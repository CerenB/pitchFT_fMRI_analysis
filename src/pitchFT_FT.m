clear;
clc;

% % cd(fileparts(mfilename('fullpath')));
addpath(fullfile(fileparts(mfilename('fullpath')), '..'));

% add cpp-spm lib
initEnv();

% get all the parameters needed
opt = getOptionPitchFT();

% check for dependencies are set right
checkDependencies();

%% FFT analysis

opt.anatMask = 0;
opt.FWHM = 3; % 3 or 6mm smoothing
% opt.stepSize = 4; % 2 or 4
opt.skullstrip.threshold = 0.5;

% create a whole brain functional mean image mask
% so the mask will be in the same resolution/space as the functional images
% one may not need it if they are running bidsFFX since it creates a
% mask.nii by default
opt.skullstrip.mean = 1;
opt.funcMask = bidsWholeBrainFuncMask(opt);

% % want to quickly change some parameters in opt?
% opt.space = 'MNI'; % 'individual', 'MNI'
% opt.subjects = {'011'};

calculateSNR(opt);
