% calculates SNR on functional data using the function calcSNRmv6()

% RnB lab 2020 SNR analysis script adapted from
% Xiaoqing Gao, Feb 27, 2020, Hangzhou xiaoqinggao@zju.edu.cn

% note: if we keep .mat files, in source folder, we can load them here to extract some
% parameters

clear;
clc;

%% set the paths & subject info
cd(fileparts(mfilename('fullpath')));

addpath(fullfile(fileparts(mfilename('fullpath')), '..'));
warning('off');
addpath(genpath('/Users/battal/Documents/MATLAB/spm12'));
% spm fmri

% set and check dependencies (lib)
initEnv();
checkDependencies();

% get option for parameters
opt = getOptionPitchFT();

% subID = opt.subjects{1};
% opt.session = {'001'};

opt.anatMask = 0;
opt.FWHM = 3; % 3 or 6mm smoothing

% we let SPM figure out what is in this BIDS data set
opt = getSpecificBoldFiles(opt);

% add or count tot run number
allRunFiles = opt.allFiles;

% use a predefined mask, only calculate voxels within the mask
maskFileName = opt.anatMaskFileName;
if ~opt.anatMask == 1
  maskFileName = makeFuncIndivMask(opt);
end
maskFile = spm_vol(maskFileName);
mask = spm_read_vols(maskFile);

%% setup parameters for FFT analysis
% mri.repetition time(TR) and repetition of steps/categA
repetitionTime = 1.75;
opt.stepSize = 4;
stepDuration = 36.48;

% setup output directory
opt.destinationDir = createOutputDirectory(opt);

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
  boldFile = allRunFiles{iRun};

  % get file name to-be saved
  [boldFileDir, boldFileName, ext] = fileparts(boldFile);

  % read/load bold file
  boldFile = spm_vol(boldFile);
  signal = spm_read_vols(boldFile); % check the load_untouch_nii to compare
  signal = reshape(signal, [size(signal, 1) * size(signal, 2) * ...
                            size(signal, 3) size(signal, 4)]);

  % find cyclic volume
  totalVol = length(spm_vol(boldFile));
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

  % save the results
  FileName = fullfile(opt.destinationDir, ['SNR_', boldFileName, ext]);

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

FileName = fullfile(opt.destinationDir, ['AvgSNR_', boldFileName, ext]);

save_nii(new_nii, FileName);

function opt = getSpecificBoldFiles(opt)

  % we let SPM figure out what is in this BIDS data set
  [~, opt, BIDS] = getData(opt);

  subID = opt.subjects(1);

  %% Get functional files for FFT
  % identify sessions for this subject
  [sessions, nbSessions] = getInfo(BIDS, subID, opt, 'Sessions');

  % get prefix for smoothed image
  [prefix, ~] = getPrefix('ffx', opt, opt.FWHM);

  allFiles = [];
  sesCounter = 1;

  for iSes = 1:nbSessions        % For each session

    % get all runs for that subject across all sessions
    [runs, nbRuns] = getInfo(BIDS, subID, opt, 'Runs', sessions{iSes});

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

  %% get the masks for FFT

  % get mean image
  [meanImage, meanFuncDir] = getMeanFuncFilename(BIDS, subID, opt);
  meanFuncFileName = fullfile(meanFuncDir, meanImage);

  % normalized image option by adding prefix w-
  if strcmp(opt.space, 'MNI')
    meanFuncFileName = fullfile(meanFuncDir, ['w', meanImage]);
  end

  % think about it again % % % %
  % instead of segmented meanfunc image here
  % get native-spaced resliced anat (cpp-spm pipeline) image:
  [~, meanImageName, ext] = fileparts(meanImage);
  anatMaskFileName = fullfile(meanFuncDir, ...
                              [meanImageName, '_mask', ext]);

  opt.anatMaskFileName = anatMaskFileName;
  opt.funcMaskFileName = meanFuncFileName;

  % save prefix
  opt.prefix = prefix;

end

function destinationDir = createOutputDirectory(opt)

  subjectDestDir = fullfile(opt.derivativesDir, '..', 'FFT_RnB_funcmask');
  if opt.anatMask
    subjectDestDir = fullfile(opt.derivativesDir, '..', 'FFT_RnB_anatmask');
  end

  subject = ['sub-', opt.subjects{1}];
  session = ['ses-', opt.session{1}];
  stepFolder = ['step', num2str(opt.stepSize)];
  dirsToMake = {subject, session, stepFolder};

  % create subject folder witn subfolders if doesn't exist
  if ~exist(fullfile(subjectDestDir, subject, session, stepFolder), 'dir')
    for idir = 1:length(dirsToMake)
      Thisdir = fullfile(subjectDestDir, dirsToMake{1:idir});
      if ~exist(Thisdir)
        mkdir(Thisdir);
      end
    end
  end

  % output the results
  destinationDir =  fullfile(subjectDestDir, subject, session, stepFolder);

end
