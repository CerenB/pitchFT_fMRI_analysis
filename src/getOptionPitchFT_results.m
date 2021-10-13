function opt =  getOptionPitchFT_results(contrastName, pvalue)
  %
  % (C) Copyright 2021 Remi Gau

  % this is an idea of how to use cpp-spm results pipeline to create tmaps
  % which will be thresholded & binarised and saved according to the input below.
  % CB edited on 29.09.2021 - we have not yet implemented it.
  %
  % alternatively, we can take the tmaps from the folder and threshold it
  % and binarise manually.
  %
  % in cpp-spm, RUN level hasn't implemenyet yet, so this will not work atm

  opt = getOptionPitchFT();

  %   opt.model.file = fullfile( ...
  %                             fileparts(mfilename('fullpath')), ...
  %                             'models', ...
  %                             'model-PitchFT_smdl.json');
  %
  %   opt.glm.QA.do = false;

  % Specify the result to compute
  opt.result.Steps(1) = returnDefaultResultsStructure();

  opt.result.Steps(1).Level = 'subject';

  opt.result.Steps(1).Contrasts(1).Name = contrastName; % 'A1_gt_B3_run_1'

  opt.result.Steps(1).Contrasts(1).MC =  'none';
  opt.result.Steps(1).Contrasts(1).p = pvalue; % 0.001
  opt.result.Steps(1).Contrasts(1).k = 0;

  % Specify how you want your output (all the following are on false by default)
  opt.result.Steps(1).Output.png = false(); % true();
  opt.result.Steps(1).Output.csv = false(); % true();
  opt.result.Steps(1).Output.thresh_spm = true();
  opt.result.Steps(1).Output.binary = true();

  % MONTAGE FIGURE OPTIONS
  opt.result.Steps(1).Output.montage.do = false(); % true();
  opt.result.Steps(1).Output.montage.slices = -26:3:6; % in mm -12:4:60;
  opt.result.Steps(1).Output.montage.orientation = 'axial';

  % will use the MNI T1 template by default but the underlay image can be
  % changed.
  opt.result.Steps(1).Output.montage.background = ...
      fullfile(spm('dir'), 'canonical', 'avg152T1.nii,1');

end
