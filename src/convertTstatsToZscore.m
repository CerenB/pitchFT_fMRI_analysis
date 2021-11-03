function [img, outputName] = convertTstatsToZscore(inputImgName,  df)
  % mini function to convert t-stats to z-scores

  % load the image to be read t-stats
  hdr = spm_vol(inputImgName);
  img = spm_read_vols(hdr);

  % rename 
  newName = replace(inputImgName, 'T', 'Z');
  hdr.fname = spm_file(hdr.fname, 'filename', newName);

  % rename the description as well
  newDescrip = [hdr.descrip, ' t->z converted'];
  hdr.descrip = spm_file(hdr.descrip, 'filename', newDescrip);

  % convert t-values to z-score
  img = spm_t2z(img, df);

  % save zscore image
  spm_write_vol(hdr, img);

  % output the file name
  outputName = hdr.fname;

end

