clear;
clc;

% cd(fileparts(mfilename('fullpath')));
addpath(fullfile(fileparts(mfilename('fullpath')), '..'));


% spm fmri
warning('off');
addpath(genpath('/Users/battal/Documents/MATLAB/spm12'));



%%
paths = getPaths();

addpath(fullfile(fileparts(mfilename('fullpath')), '..'));
warning('off');
addpath(genpath(paths.spm));


%%
% add cpp-spm lib
initEnv();

% get all the parameters needed
opt = getOptionPitchFT();

% check for dependencies are set right
checkDependencies();

%% FFT analysis

opt.anatMask = 0;
opt.FWHM = 3; % 3 or 6mm smoothing
opt.stepSize = 4; % 2 or 4
opt.skullstrip.threshold = 0.25;

% % want to quickly chagne some parameters in opt?
% opt.space = 'MNI'; % 'individual', 'MNI'
% opt.subjects = {'011'};

calculateSNR(opt);
