clear;
clc;

% Smoothing to apply
FWHM = 3;
isMVPA = false;

cd(fileparts(mfilename('fullpath')));

addpath(fullfile(fileparts(mfilename('fullpath')), '..'));
% addpath(genpath('/Users/battal/Documents/MATLAB/spm12'));

initEnv();

% we add all the subfunctions that are in the sub directories
opt = getOptionPitchFT();

checkDependencies();

%% Run batches

bidsCopyRawFolder(opt, 0);
bidsSTC(opt);
idsSpatialPrepro(opt);
bidsSmoothing(FWHM, opt);

% bidsFFX('specifyAndEstimate', opt, FWHM, isMVPA);
% bidsFFX('contrasts', opt, FWHM, isMVPA);

% bidsRealignReslice(opt);
% bidsSmoothing(FWHM, opt);
% bidsFFX('specifyAndEstimate', opt, FWHM, isMVPA);
% bidsFFX('contrasts', opt, FWHM, isMVPA);
% % bidsResults(opt, FWHM, [], isMVPA);
% bidsFFX('specifyAndEstimate', opt, 0, isMVPA);
% bidsFFX('contrasts', opt, 0, isMVPA);
% bidsResults(opt, FWHM, [], isMVPA);
