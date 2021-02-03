

clear;
clc;

% cd(fileparts(mfilename('fullpath')));

addpath(fullfile(fileparts(mfilename('fullpath')), '..'));
warning('off');
addpath(genpath('/Users/battal/Documents/MATLAB/spm12'));
% spm fmri

initEnv();

% get all the parameters needed
opt = getOptionPitchFT();

% check for dependencies are set right
checkDependencies();


%% FFT analysis 

opt.anatMask = 0;
opt.FWHM = 3; % 3 or 6mm smoothing

% % want to quickly chagne some parameters in opt?
% opt.space = 'MNI'; % 'individual', 'MNI'
% opt.subjects = {'011'};


calculateSNR(opt);