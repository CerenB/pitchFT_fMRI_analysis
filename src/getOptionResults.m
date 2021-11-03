function opt =  getOptionResults(contrastName, pvalue)
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


  % Specify the result to compute
  opt.result.Steps(1) = returnDefaultResultsStructure();

  opt.result.Steps(1).Level = 'subject';

  % these are function input variabls
  opt.result.Steps(1).Contrasts(1).Name = contrastName; 
  opt.result.Steps(1).Contrasts(1).p = pvalue;
  
  opt.result.Steps(1).Contrasts(1).MC =  'none';
  opt.result.Steps(1).Contrasts(1).k = 0;

  % Specify how you want your output (all the following are on false by default)
  opt.result.Steps(1).Output.png = false(); 
  opt.result.Steps(1).Output.csv = false();
  opt.result.Steps(1).Output.thresh_spm = false();
  opt.result.Steps(1).Output.binary = true();

  % MONTAGE FIGURE OPTIONS
  opt.result.Steps(1).Output.montage.do = false(); 
  opt.result.Steps(1).Output.montage.slices = 12:4:54; % in mm -12:4:60  -26:3:6
  opt.result.Steps(1).Output.montage.orientation = 'axial';

  % will use the MNI T1 template by default but the underlay image can be
  % changed.
%   subID = ['sub-', opt.subjects{1}];
%   
%   opt.result.Steps(1).Output.montage.background = ...
%       fullfile(opt.derivativesDir, subID, 'ses-001', 'anat',[subID,'_ses-001_T1w.nii,1']);
  
%   if strcmp(opt.space, 'MNI')
        opt.result.Steps(1).Output.montage.background = ...
        fullfile(spm('dir'), 'canonical', 'avg152T1.nii,1');
%   end
  

end
