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
    opt.subjects = {'pil001'};

    % we stay in native space (that of the T1)
    opt.space = 'MNI'; %individual %MNI

    % The directory where the data are located
    opt.dataDir = fullfile(fileparts(mfilename('fullpath')), ...
                           '..', '..', '..',  'raw');

    % task to analyze
    opt.taskName = 'PitchFT';

    % Suffix output directory for the saved jobs
    opt.jobsDir = fullfile( ...
                           opt.dataDir, '..', 'derivatives', ...
                           'SPM12_CPPL', 'JOBS', opt.taskName);

    opt.sliceOrder = [];

    opt.STC_referenceSlice = [];

    % Options for normalize
    % Voxel dimensions for resampling at normalization of functional data or leave empty [ ].
    opt.funcVoxelDims = [2.6 2.6 2.6];

  %% DO NOT TOUCH
  opt = checkOptions(opt);
  saveOptions(opt);

end
