function maskPath = makeNativeSpaceMask(imagePath)

  % function uses a mean functional image to create individual space mask

  % STEP 1
  % go to mricron and create skull stripped mean functional image
  % by using FSL BET function
  % in the future think about implementing FSL BET into matlab
  [path, imageName, ext] = fileparts(imagePath);
  betImageName = ['bet05_', imageName, ext];
  betImagePath = fullfile(path, betImageName);

  % create mask name
  maskFileName = ['mask', betImageName];
  maskPath = fullfile(path, maskFileName);

  % STEP 2
  if ~exist(maskPath)
    % Create a template & load the mask
    % A = load_untouch_nii('bet_05_meanuasub-pil001-PitchFT_run-001.nii');
    A = load_untouch_nii(betImagePath);

    C = A;
    C.fileprefix = 'C';
    C.img = [];

    idx = find(A.img > 0);
    A.img(idx) = 1;
    C.img = A.img;
    save_untouch_nii(C, maskPath);
  end

end
