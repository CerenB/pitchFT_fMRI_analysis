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
%addpath(genpath('/Users/battal/Documents/MATLAB/spm12'));
% spm fmri

% set and check dependencies (lib)
initEnv();
checkDependencies();

% subject to run
opt.subject = {'pil001'};
opt.taskName = 'PitchFT';
opt.space = 'individual';


opt.derivativesDir = fullfile(fileparts(mfilename('fullpath')), ...
                           '..', '..', '..',  'derivatives', 'SPM12_CPPL');
                      


% we let SPM figure out what is in this BIDS data set
opt = getSpecificBoldFiles(opt);
  
% add or count tot run number
allRunFiles = opt.allFiles;

% % use a predefined mask, only calculate voxels within the mask
% maskFileName = opt.funcMaskFileName;
% % read/load mask file
% maskFile = spm_vol(maskFileName);
% mask = spm_read_vols(maskFile); % dimension wise, may not fit with func!!

%%%%%%%%%%%% WORK IN PROGRESS
% re-do the mask
% Create a template
A = load_untouch_nii('bet_05_meanuasub-pil001-PitchFT_run-001.nii');
C = A ;
C.fileprefix = 'C';
C.img = [];

idx= find(A.img >0);
A.img(idx) = 1;
C.img = A.img;
save_untouch_nii(C,'funcBinaryMask3.nii')

maskFile = spm_vol('funcBinaryMask3.nii');
mask = spm_read_vols(maskFile2);


%tasks={'Run1';'Run2'};

%%%%%%%%%%%%%%%%%%%%%

% mri.repetition time(TR) and repetition of steps/categA
repetitionTime = 1.75;
stepDuration = 36.48;


% calculate frequencies
oddballFreq = 1/stepDuration; 
samplingFreq = 1/repetitionTime; 

% Number of vol before/after the rhythmic sequence (exp) are presented
onsetDelay = 2; %5.2s
endDelay = 4; %10.4s





% We collected 313 volumes in total, but only 306 volumes/secs in each run (306/9=34 cycles),
% remove the first 4 volumes to align the beginning with first appearance of faces 
% and remove the last 3 volumes so we don't have any partial cycles

% use neighbouring 40 bins as noise frequencies
BinSize = 40;

RunPattern(2).pattern = [];
RunPattern(2).rawpattern = [];



%% Calculate SNR for each run
for iRun = 1:length(allRunFiles)
    
    fprintf('Read in file ... \n');
    
    tic
    
    % choose current BOLD file
    boldFileName = allRunFiles{iRun};
    % read/load bold file
    boldFile = spm_vol(boldFileName);
    signal = spm_read_vols(boldFile); %check the load_untouch_nii to compare
    signal = reshape(signal,[size(signal,1)*size(signal,2)*size(signal,3) size(signal,4)]);
    
    % find cyclic volume
    totalVol = length(spm_vol(boldFileName));
    sequenceVol = totalVol - onsetDelay - endDelay;
    
    %remove the first 4 volumes, using this step to make the face stimulus onset at 0
    Pattern = signal(mask == 1,(onsetDelay+1):(sequenceVol+onsetDelay));
    
    Pattern = Pattern';
    RunPattern(iRun).rawpattern = Pattern;
    
    
    %remove linear trend
    PatternDT = detrend(Pattern);
    RunPattern(iRun).pattern = PatternDT;
    
    toc
    
%%%%
% interpolate (resample)
    oldN = size(Pattern,1); 
    newN = 104; 
    oldFs = samplingFreq; 
    newFs = 1 / (182.4 / newN); 
    xi = linspace(0,oldN,newN); 

   
    % design low-pass filter (to be 100% sure you prevent aliasing)
    fcutoff = samplingFreq/4;
    transw  = .1;
    order   = round( 7*samplingFreq/fcutoff );
    shape   = [ 1 1 0 0 ];
    frex    = [ 0 fcutoff fcutoff+fcutoff*transw samplingFreq/2 ] / (samplingFreq/2);
    hz      = linspace(0,samplingFreq/2,floor(oldN/2)+1);

    % get filter kernel
    filtkern = firls(order,frex,shape);

    % get kernel power spectrum
    filtkernX = abs(fft(filtkern,oldN)).^2;
    filtkernXdb = 10*log10(abs(fft(filtkern,oldN)).^2);


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
%     set(gca,'xlim',[0 fcutoff*3],'ylim',[min([filtkernXdb(plotedge) filtkernXdb(plotedge)]) 5])
%     xlabel('Frequency (Hz)'), ylabel('Gain')
%     title('Filter kernel spectrum (dB)')

    % filter and interpolate
    PatternRs = nan(newN, size(Pattern,2)); 
    
    for voxi=1:size(Pattern,2)
        % low-pass filter
        PatternFilt = filtfilt(filtkern,1,Pattern(:,voxi));
        % interpolate
        PatternRs(:,voxi) = interp1([1:oldN], PatternFilt, xi, 'linear'); 
    end

    RunPattern(iRun).pattern = PatternRs;
    samplingFreq = newFs; 


%%%%

    %number of samples (round to smallest even number)
    N = 2*floor(size(PatternDT,1)/2);
    %frequencies
    f = samplingFreq/2*linspace(0,1,N/2+1);
    %target frequency
    TF=round(N*oddballFreq/samplingFreq+1);
    %number of bins for phase histogram
    histBin=20;
    %threshold for choosing voxels for the phase distribution analysis
    Thresh=4;
    
    [TargetSNR, TargetPhase, TargetSNRsigned,tSNR] = calcSNRmv6(...
        PatternDT,RunPattern(iRun).rawpattern,TF,BinSize, Thresh,histBin);
    
    fprintf('Saving ... \n');
    
    mask_new = load_untouch_nii(maskFileName);
    dims = size(mask_new.img);
    
    maskIndex = find(mask_new.img==1);
    
    zmapmasked = TargetSNR;
    zmap3Dmask = zeros(size(mask_new.img));
    zmap3Dmask(maskIndex) = zmapmasked;
    new_nii = make_nii(zmap3Dmask);
    new_nii.hdr = mask_new.hdr;
    new_nii.hdr.dime.dim(2:5) = [dims(1) dims(2) dims(3) 1];
    FileName=[current_dir  '/Results/SNR_' tasks{iRun} '.nii'];
    save_nii(new_nii,FileName);
    
end


%% Calculate SNR for the averaged time course of the two runs
avgPattern=(RunPattern(1).pattern+RunPattern(2).pattern)/2;
avgrawPattern=(RunPattern(1).rawpattern+RunPattern(2).rawpattern)/2;

% SNR Calculation
fprintf('Calculating average... \n');
[TargetSNR, TargetPhase, TargetSNRsigned, tSNR]=calcSNRmv6(avgPattern,avgrawPattern,TF,BinSize, Thresh,histBin); 
            
% write zmap
fprintf('Saving average... \n');
mask_new=load_untouch_nii(maskFileName);
maskIndex=find(mask_new.img==1);
dims=size(mask_new.img);
zmapmasked=TargetSNR;
zmap3Dmask=zeros(size(mask_new.img));
zmap3Dmask(maskIndex)=zmapmasked;
new_nii = make_nii(zmap3Dmask);
new_nii.hdr = mask_new.hdr;
new_nii.hdr.dime.dim(2:5) = [dims(1) dims(2) dims(3) 1];
FileName=[current_dir '/Results/SNR_Avg.nii'];
save_nii(new_nii,FileName);



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
            subID, sessions{iSes},...
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
anatMaskFileName = fullfile(subFuncDataDir,'..',...
    'anat','msub-pil001_ses-001_T1w_mask.nii');

funcMaskFileName = fullfile(subFuncDataDir,...
    'meanasub-pil001_ses-001_task-PitchFT_run-001_bold.nii');
if strcmp(opt.space, 'individual')
    funcMaskFileName = fullfile(subFuncDataDir,...
        'meanuasub-pil001_ses-001_task-PitchFT_run-001_bold.nii');
end


opt.anatMaskFileName = anatMaskFileName;
opt.funcMaskFileName = funcMaskFileName;

end
