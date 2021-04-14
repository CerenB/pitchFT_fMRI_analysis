% (C) Copyright 2019 CPP BIDS SPM-pipeline developpers

function opt = getOptionPitchFT()
  % opt = getOption()
  % returns a structure that contains the options chosen by the user to run
  % slice timing correction, pre-processing, FFX, RFX.

  if nargin < 1
    opt = [];
  end

  % group of subjects to analyze
  opt.groups = {''};
  % suject to run in each group
  opt.subjects = {'011'};
  % '008', '009', '010', '011'
  % '001', '002', '003', '004', '005', '006','007',

  % Uncomment the lines below to run preprocessing
  % - don't use realign and unwarp
  opt.realign.useUnwarp = true;

  % we stay in native space (that of the T1)
  % - in "native" space: don't do normalization
  opt.space = 'individual'; % 'individual', 'MNI'

  % task to analyze
  opt.taskName = 'PitchFT';

  % to add the hrf temporal derivative = [1 0]
  % to add the hrf temporal and dispersion derivative = [1 1]
  % opt.model.hrfDerivatives = [0 0];

  opt.sliceOrder = [];

  opt.STC_referenceSlice = [];

  % Options for normalize
  % Voxel dimensions for resampling at normalization of functional data or leave empty [ ].
  opt.funcVoxelDims = [2.6 2.6 2.6];

  opt.parallelize.do = true;
  opt.parallelize.nbWorkers = 4;
  opt.parallelize.killOnExit = true;

  %% set paths
  [~, hostname] = system('hostname');

  if strcmp(deblank(hostname), 'tux')

    % set spm
    warning('off');
    addpath(genpath('/home/tomo/Documents/MATLAB/spm12'));

    opt.derivativesDir = fullfile( ...
                                  '/datadisk/data/RhythmCateg-fMRI/RhythmBlock', ...
                                  'cpp_spm');

  elseif strcmp(deblank(hostname), 'mac-114-168.local')

    % set spm
    warning('off');
    addpath(genpath('/Users/battal/Documents/MATLAB/spm12'));

    % The directory where the data are located
    opt.dataDir = fullfile(fileparts(mfilename('fullpath')), ...
                           '..', '..', '..',  'raw');

    opt.derivativesDir = fullfile(opt.dataDir, '..', ...
                                  'derivatives', 'cpp_spm');

  end

  % Suffix output directory for the saved jobs
  opt.jobsDir = fullfile( ...
                         opt.dataDir, '..', 'derivatives', ...
                         'cpp_spm', 'JOBS', opt.taskName);
  %% DO NOT TOUCH
  opt = checkOptions(opt);
  saveOptions(opt);

end
