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
    opt.subjects = {'001'};

    % Uncomment the lines below to run preprocessing
    % - don't use realign and unwarp
    opt.realign.useUnwarp = true;

    % we stay in native space (that of the T1)
    % - in "native" space: don't do normalization
    opt.space = 'individual'; % 'individual', 'MNI'

    % The directory where the data are located
    opt.dataDir = fullfile(fileparts(mfilename('fullpath')), ...
                           '..', '..', '..',  'raw');
    opt.derivativesDir = fullfile(opt.dataDir, '..');

    % task to analyze
    opt.taskName = 'PitchFT';

    % Suffix output directory for the saved jobs
    opt.jobsDir = fullfile( ...
                           opt.dataDir, '..', 'derivatives', ...
                           'cpp_spm', 'JOBS', opt.taskName);

    opt.sliceOrder = [];

    opt.STC_referenceSlice = [];

    % Options for normalize
    % Voxel dimensions for resampling at normalization of functional data or leave empty [ ].
    opt.funcVoxelDims = [2.6 2.6 2.6];

  %% DO NOT TOUCH
  opt = checkOptions(opt);
  saveOptions(opt);

end
