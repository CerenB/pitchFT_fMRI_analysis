function [allCoeff, meanCoeff] = calculateDiceCoeff(opt, FWHM)
  % this function is a batch for calculating dice coefficient
  % last edit on 08.10.2021
  % we already prepared spmT maps (thresholded + binarised) by using bidsResults
  % now, we will read/load binarised masks and calculate dice coeff across
  % subjects

  % % TO-DO
  % check if tmap --> zmap --> binarisation
  % is different than tmap --> binarisation (for dice coeff)

  % all pitch
  % df = 873;

  % run number
  runNb = 9; % important to make pairs of runs to calculate dice

  % load results;
  result = opt.result.Steps;
  contrastName = bids.internal.camel_case(result.Contrasts(1).Name(1:end - 1));

  % save path
  outputDir = returnOutputPath(opt, FWHM, contrastName);

  % rename pvalue for using saving results
  pvalue = num2str(result.Contrasts(1).p);
  pvalue = strrep(pvalue, '.', '');

  % save results
  savefileMat = fullfile(outputDir, ...
                         ['WholeBrain_GLM', ...
                          '_N-', num2str(numel(opt.subjects)), ...
                          '_p-', pvalue, ...
                          '_', datestr(now, 'yyyymmddHHMM'), '.mat']);

  savefileCsv = fullfile(outputDir, ...
                         ['WholeBrain_GLM', ...
                          '_N-', num2str(numel(opt.subjects)), ...
                          '_p-', pvalue, ...
                          '_', datestr(now, 'yyyymmddHHMM'), '.csv']);

  % here we read already thresholded & binarize tmaps (assuming that tmaps
  % would not be different than zmaps as long as the threshold is the same
  count = 1;

  for iSub = 1:numel(opt.subjects)

    % find the tmaps to load
    subLabel = opt.subjects{iSub};
    imagePath =  getFFXdir(subLabel, FWHM, opt);

    % if bidsResults work to create desired contrast, use below:
    filePattern = returnName(subLabel, result, opt);

    patternBinary = [filePattern, '_mask.nii'];

    binaryMapFiles = dir(fullfile(imagePath, patternBinary));
    binaryMapFiles([binaryMapFiles.isdir]) = [];

    % make all the combinations of runs
    indices = nchoosek(1:runNb, 2);
    coeff = nan(1, length(indices));

    % loop for calculating dice coeff across runs
    for iPairs = 1:length(indices)

      image1 = fullfile(imagePath, binaryMapFiles(indices(iPairs, 1)).name);
      image2 = fullfile(imagePath, binaryMapFiles(indices(iPairs, 2)).name);

      coeff(iPairs) = nii_dice(image1, image2);
      fprintf('Dice coeff of Sub%d Run%d and Run%d is %f\n', iSub, ...
              indices(iPairs, 1), indices(iPairs, 2), coeff(iPairs));

      allCoeff(count).coeff = coeff(iPairs);
      allCoeff(count).subID = iSub;
      allCoeff(count).run1 = indices(iPairs, 1);
      allCoeff(count).run2 = indices(iPairs, 2);
      allCoeff(count).label = contrastName;
      allCoeff(count).img1 = binaryMapFiles(indices(iPairs, 1)).name;
      allCoeff(count).img2 = binaryMapFiles(indices(iPairs, 2)).name;
      count = count + 1;
    end

    % calculate the mean dice coeff
    meanCoeff(iSub).coeff =  mean(coeff, 'omitnan');
    meanCoeff(iSub).coeffisNan =  mean(coeff);
    meanCoeff(iSub).subID = iSub;
    meanCoeff(iSub).pvalue = result.Contrasts(1).p;

    % save the dice coeff value
    save(savefileMat, 'meanCoeff', 'allCoeff');
    % only save the mean values for plotting
    writetable(struct2table(meanCoeff), savefileCsv);
  end

end

function baseName = returnName(subLabel, result, opt)
  % returns base name to find which tmaps we are interested in

  contrastName = bids.internal.camel_case(result.Contrasts(1).Name(1:end - 1));
  correction = result.Contrasts(1).MC;
  pvalue = bids.internal.camel_case(num2str(result.Contrasts(1).p));
  clusterSize = result.Contrasts(1).k;

  baseName = ['sub-', subLabel, ...
              '_task-', opt.taskName, ...
              '_space-', opt.space, ...
              '_desc-', contrastName, ...
              '*_label-', '*', ...
              '_p-', pvalue, ...
              '_k-', num2str(clusterSize), ...
              '_MC-', correction];

  baseName = strrep(baseName, '.', '');

end

function outputDir = returnOutputPath(opt, FWHM, contrastName)
  % makes directory is not there
  main = fullfile(opt.derivativesDir, '..', 'rnb_fft', 'group', 'dice-coeff');

  if ~exist(main, 'dir')
    mkdir(main);
  end

  outputDir = fullfile(main, ['task-', opt.taskName, ...
                              '_space-', opt.space, ...
                              '_FWHM-', num2str(FWHM), ...
                              '_desc-', contrastName]);

  if ~exist(outputDir, 'dir')
    mkdir(outputDir);
  end

end
