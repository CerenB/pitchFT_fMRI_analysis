function outputImage = convertTstatsToZscore(inputImgName, inputPath, df)
  % mini function to convert t-stats to z-scores

  % read the header
  hdr = spm_vol(fullfile(inputPath, inputImgName));
  % load the image to be read t-stats
  img = spm_read_vols(hdr);

  % name the z-score .nii name
  % threshold = strrep(num2str(threshold), '.', '');
  % newName = ['pvalue_', threshold,'_', replace(inputImgName,'T', 'Z')];
  newName = replace(inputImgName, 'T', 'Z');
  hdr.fname = spm_file(hdr.fname, 'filename', newName);
  % hdr.fname = spm_file(hdr.fname, 'path', destinationDir);

  % rename the description as well
  newDescrip = [hdr.descrip, ' t->z converted'];
  hdr.descrip = spm_file(hdr.descrip, 'filename', newDescrip);

  % convert t-values to z-score
  img = spm_t2z(img, df);

  % save zscore image
  spm_write_vol(hdr, img);

  % output the file name
  outputImage = hdr.fname;

end

% 'spmT_0019.nii'
% 0019 : simple
% 0020 : complex/nonmetric
% 0023 : all sounds

% all pitch
% df = 873
