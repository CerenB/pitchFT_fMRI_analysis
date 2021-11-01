% (C) Copyright 2019 CPP BIDS SPM-pipeline developpers

function opt = getOptionPitchFT()
  % opt = getOption()
  % returns a structure that contains the options chosen by the user to run
  % slice timing correction, pre-processing, FFX, RFX.

  if nargin < 1
    opt = [];
  end

  % suject to run in each group
%   opt.subjects = {'001','002', '003', '004', '005', '006',...
%     '007', '008', '009', '010', '011', '012'};
  opt.subjects = {'001'};

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

  opt.parallelize.do = false;
  opt.parallelize.nbWorkers = 1;
  opt.parallelize.killOnExit = true;

  %% set paths
  [~, hostname] = system('hostname');
  if strcmp(deblank(hostname), 'tux')
    opt.dataDir = fullfile('/datadisk/data/RhythmCateg-fMRI/RhythmBlock');
    opt.derivativesDir = fullfile( ...
                                  '/datadisk/data/RhythmCateg-fMRI/PitchFT', ...
                                  'cpp_spm');
  elseif strcmp(deblank(hostname), 'mac-114-168.local')
    % The directory where the data are located
    opt.dataDir = fullfile(fileparts(mfilename('fullpath')), ...
                           '..', '..', '..', 'raw');
    opt.derivativesDir = fullfile(opt.dataDir, '..', ...
                                  'derivatives', 'cpp_spm');

    opt.dir.roi = fullfile(fileparts(mfilename('fullpath')),  ...
                          '..', '..', '..', '..', 'RhythmCateg_ROI', 'hmat');
  end

  % Suffix output directory for the saved jobs
  opt.jobsDir = fullfile( ...
                         opt.dataDir, '..', 'derivatives', ...
                         'cpp_spm', 'JOBS', opt.taskName);

  opt.model.file =  ...
        fullfile(fileparts(mfilename('fullpath')), '..', ...
                 'model', 'model-PitchFT_smdl.json');

  % assign QA false for FFX analysis if you have not run QA
  opt.glm.QA.do = false;

  %% DO NOT TOUCH
  opt = checkOptions(opt);
  saveOptions(opt);

end
