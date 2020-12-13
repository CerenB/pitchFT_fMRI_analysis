% calculates SNR on functional data using the function calcSNRmv6()

% RnB lab 2020 SNR analysis script adapted from
% Xiaoqing Gao, Feb 27, 2020, Hangzhou xiaoqinggao@zju.edu.cn

% note: if we keep .mat files, in source folder, we can load them here to extract some
% parameters

clear;
clc;

cd(fileparts(mfilename('fullpath')));

addpath(fullfile(fileparts(mfilename('fullpath')), '..'));
warning('off');
% addpath(genpath('/Users/battal/Documents/MATLAB/spm12'));
% spm fmri

% set and check dependencies (lib)
initEnv();
checkDependencies();

% subject to run
opt.subject = {'002'};
opt.taskName = 'RhythmFT';
opt.space = 'individual';

opt.derivativesDir = fullfile(fileparts(mfilename('fullpath')), ...
                              '..', '..', '..',  'derivatives', 'cpp_spm');

% we let SPM figure out what is in this BIDS data set
opt = getSpecificBoldFiles(opt);

% add or count tot run number
allRunFiles = opt.allFiles;

% use a predefined mask, only calculate voxels within the mask
maskFileName = makeNativeSpaceMask(opt.funcMaskFileName);
maskFile = spm_vol(maskFileName);
mask = spm_read_vols(maskFile);

% mri.repetition time(TR) and repetition of steps/categA
repetitionTime = 1.75;
stepDuration = 36.48;

% calculate frequencies
oddballFreq = 1 / stepDuration;
samplingFreq = 1 / repetitionTime;

% Number of vol before/after the rhythmic sequence (exp) are presented
onsetDelay = 2;
endDelay = 4;

% use neighbouring 4 bins as noise frequencies
cfg.binSize = 4;

RunPattern = struct();
nVox = sum(mask(:) == 1);
nRuns = length(allRunFiles);
newN = 104;

allRunsRaw = nan(newN, nVox, nRuns);
allRunsDT = nan(newN, nVox, nRuns);

%% Calculate SNR for each run
for iRun = 1:nRuns

    fprintf('Read in file ... \n');

    % choose current BOLD file
    boldFileName = allRunFiles{iRun};
    % read/load bold file
    boldFile = spm_vol(boldFileName);
    signal = spm_read_vols(boldFile); % check the load_untouch_nii to compare
    signal = reshape(signal, [size(signal, 1) * size(signal, 2) * ...
                              size(signal, 3) size(signal, 4)]);

    % find cyclic volume
    totalVol = length(spm_vol(boldFileName));
    sequenceVol = totalVol - onsetDelay - endDelay;

    % remove the first 4 volumes, using this step to make the face stimulus onset at 0
    Pattern = signal(mask == 1, (onsetDelay + 1):(sequenceVol + onsetDelay));

    Pattern = Pattern';

    % interpolate (resample)
    oldN = size(Pattern, 1);
    oldFs = samplingFreq;
    newFs = 1 / (182.4 / newN);
    xi = linspace(0, oldN, newN);

    % design low-pass filter (to be 100% sure you prevent aliasing)
    fcutoff = samplingFreq / 4;
    transw  = .1;
    order   = round(7 * samplingFreq / fcutoff);
    shape   = [1 1 0 0];
    frex    = [0 fcutoff fcutoff + fcutoff * transw samplingFreq / 2] / ...
              (samplingFreq / 2);
    hz      = linspace(0, samplingFreq / 2, floor(oldN / 2) + 1);

    % get filter kernel
    filtkern = firls(order, frex, shape);

    % get kernel power spectrum
    filtkernX = abs(fft(filtkern, oldN)).^2;
    filtkernXdb = 10 * log10(abs(fft(filtkern, oldN)).^2);

    %     % plot filter properties (visual check)
    %     figure
    %     plotedge = dsearchn(hz',fcutoff*3);
    %
    %     subplot(2,2,1)
    %     plot((-order/2:order/2)/samplingFreq,filtkern,'k','linew',3)
    %     xlabel('Time (s)')
    %     title('Filter kernel')
    %
    %     subplot(2,2,2), hold on
    %     plot(frex*samplingFreq/2,shape,'r','linew',1)
    %
    %     plot(hz,filtkernX(1:length(hz)),'k','linew',2)
    %     set(gca,'xlim',[0 fcutoff*3])
    %     xlabel('Frequency (Hz)'), ylabel('Gain')
    %     title('Filter kernel spectrum')
    %
    %     subplot(2,2,4)
    %     plot(hz,filtkernXdb(1:length(hz)),'k','linew',2)
    %     set(gca,'xlim',[0 fcutoff*3],'ylim',...
    %        [min([filtkernXdb(plotedge) filtkernXdb(plotedge)]) 5])
    %     xlabel('Frequency (Hz)'), ylabel('Gain')
    %     title('Filter kernel spectrum (dB)')

    % filter and interpolate
    patternResampled = zeros(newN, size(Pattern, 2));

    for voxi = 1:size(Pattern, 2)
        % low-pass filter
        PatternFilt = filtfilt(filtkern, 1, Pattern(:, voxi));
        % interpolate
        patternResampled(:, voxi) = interp1([1:oldN], PatternFilt, xi, 'spline');
    end

    samplingFreq = newFs;

    % remove linear trend
    patternDetrend = detrend(patternResampled);

    % number of samples (round to smallest even number)
    N = newN; % 2*floor(size(PatternDT,1)/2);
    % frequencies
    f = samplingFreq / 2 * linspace(0, 1, N / 2 + 1);
    % target frequency
    cfg.targetFrequency = round(N * oddballFreq / samplingFreq + 1);
    % number of bins for phase histogram
    cfg.histBin = 20;
    % threshold for choosing voxels for the phase distribution analysis
    cfg.thresh = 4;

    [targetSNR, cfg] = calculateFourier(patternDetrend, patternResampled, cfg);

    %     %unused parameters for now
    %     targetPhase = cfg.targetPhase;
    %     targetSNRsigned = cfg.targetSNRsigned;
    %     tSNR = cfg.tSNR;
    %     %

    allRunsRaw(:, :, iRun) = patternResampled;
    allRunsDT(:, :, iRun) = patternDetrend;

    fprintf('Saving ... \n');

    % z-scored 1-D vector
    zmapmasked = targetSNR;

    % allocate 3-D img
    % get the mask
    mask_new = load_untouch_nii(maskFileName);
    zmap3Dmask = zeros(size(mask_new.img));

    % get mask index
    maskIndex = find(mask_new.img == 1);
    % assign z-scores from 1-D to their correcponding 3-D location
    zmap3Dmask(maskIndex) = zmapmasked;

    new_nii = make_nii(zmap3Dmask);

    new_nii.hdr = mask_new.hdr;

    % get dimensions to save
    dims = size(mask_new.img);
    new_nii.hdr.dime.dim(2:5) = [dims(1) dims(2) dims(3) 1];

    FileName = fullfile(opt.derivativesDir, '..', ...
                        'FFT_RnB', ['sub-', opt.subject{1}], ...
                        'ses-001', ['SNR_sub-', ...
                                    opt.subject{1}, '_ses-001_task-', ...
                                    opt.taskName, '_run-00', num2str(iRun), ...
                                    '_bold.nii']);

    save_nii(new_nii, FileName);

end

%% Calculate SNR for the averaged time course of the two runs
avgPattern = mean(allRunsDT, 3);
avgrawPattern = mean(allRunsRaw, 3);

% avgPattern=(RunPattern(1).pattern+RunPattern(2).pattern)/2;
% avgrawPattern=(RunPattern(1).rawpattern+RunPattern(2).rawpattern)/2;

% SNR Calculation
fprintf('Calculating average... \n');
[targetSNR, cfg] = calculateFourier(avgPattern, avgrawPattern, cfg);

% write zmap
fprintf('Saving average... \n');
mask_new = load_untouch_nii(maskFileName);
maskIndex = find(mask_new.img == 1);
dims = size(mask_new.img);
zmapmasked = targetSNR;
zmap3Dmask = zeros(size(mask_new.img));
zmap3Dmask(maskIndex) = zmapmasked;
new_nii = make_nii(zmap3Dmask);
new_nii.hdr = mask_new.hdr;
new_nii.hdr.dime.dim(2:5) = [dims(1) dims(2) dims(3) 1];
FileName = fullfile(opt.derivativesDir, '..', ...
                    'FFT_RnB', ['sub-', opt.subject{1}], ...
                    'ses-001', ['AvgSNR_sub-', ...
                                opt.subject{1}, '_ses-001_task-', ...
                                opt.taskName, '_bold.nii']);
save_nii(new_nii, FileName);

function opt = getSpecificBoldFiles(opt)

    % we let SPM figure out what is in this BIDS data set
    BIDS = spm_BIDS(opt.derivativesDir);

    subID = opt.subject(1);

    % identify sessions for this subject
    [sessions, nbSessions] = getInfo(BIDS, subID, opt, 'Sessions');

    % creates prefix to look for
    prefix = 's3wa';
    if strcmp(opt.space, 'individual')
        prefix = 's3ua';

    end

    allFiles = [];
    sesCounter = 1;

    for iSes = 1:nbSessions        % For each session

        % get all runs for that subject across all sessions
        [runs, nbRuns] = getInfo(BIDS, subID, opt, 'Runs', sessions{iSes});

        % numRuns = group(iGroup).numRuns(iSub);
        for iRun = 1:nbRuns

            % get the filename for this bold run for this task
            [fileName, subFuncDataDir] = getBoldFilename( ...
                                                         BIDS, ...
                                                         subID, sessions{iSes}, ...
                                                         runs{iRun}, opt);

            % check that the file with the right prefix exist
            files = validationInputFile(subFuncDataDir, fileName, prefix);

            % add the files to list
            allFilesTemp = cellstr(files);
            allFiles = [allFiles; allFilesTemp]; %#ok<AGROW>
            sesCounter = sesCounter + 1;

        end
    end

    opt.allFiles = allFiles;

    % get the masks
    anatMaskFileName = fullfile(subFuncDataDir, '..', ...
                                'anat', 'msub-,', ...
                                opt.subject, '_ses-001_T1w_mask.nii');

    funcMaskFileName = fullfile(subFuncDataDir, ...
                                ['meanasub-', opt.subject{1}, ...
                                 '_ses-001_task-,', opt.taskName, ...
                                 '_run-001_bold.nii']);

    if strcmp(opt.space, 'individual')
        funcMaskFileName = fullfile(subFuncDataDir, ...
                                    ['meanuasub-', opt.subject{1}, ...
                                     '_ses-001_task-', opt.taskName, ...
                                     '_run-001_bold.nii']);
    end

    opt.anatMaskFileName = anatMaskFileName;
    opt.funcMaskFileName = funcMaskFileName;

end
