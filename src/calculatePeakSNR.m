function calculatePeakSNR(opt, pvalue)

% pvalue = 1e-4;

% this function looks at the FFT and GLM thresholded images to find the
% highest zpscore in a given mask

% 1. GLM images: we already thresholded the GLM (spmT map). We need to mask the
% image with a given roi, and then find the highest t-value, then convert
% it into z-score. 
% 2. FFT image: we have z maps, we need to threshold with desired p value,
% and look for the highest zscore in a given ROI. 
%
% for both we start with the whole-brain images. 
%
% thenwe save the values across participant into a structure

%   % save results
%   savefileMat = fullfile(outputDir, ...
%                          ['WholeBrain_GLM', ...
%                           '_N-', num2str(numel(opt.subjects)), ...
%                           '_p-', pvalue, ...
%                           '_', datestr(now, 'yyyymmddHHMM'), '.mat']);
% 
%   savefileCsv = fullfile(outputDir, ...
%                          ['WholeBrain_GLM', ...
%                           '_N-', num2str(numel(opt.subjects)), ...
%                           '_p-', pvalue, ...
%                           '_', datestr(now, 'yyyymmddHHMM'), '.csv']);

FWHM = opt.FWHM;

%cut off threshold for pvalue
threshold =  round(abs(norminv(pvalue)),2);

% for pitchFT the degrees of freedom
dof = 873; 

    for iSub = 1:numel(opt.subjects)

        subLabel = opt.subjects{iSub};
        
        % setup output directory
        fftDir = getFFTdir(opt, subLabel);
        fftFileName = getZimage(fftDir);

        % load image
        zHdr = spm_vol(fftFileName);
        zImg = spm_read_vols(zHdr);
        
        % threshold image with z-conversion of p<1e-4 
        zImg = zImg > threshold;
        
        % glm dir
        glmDir =  getFFXdir(subLabel, FWHM, opt);
        results = opt.result.Steps.Contrasts;
        results.dir = glmDir;
        glmFileName = getTimage(results);
        
        % load image
        tHdr = spm_vol(glmFileName);
        tImg = spm_read_vols(tHdr);

        % convert tMap into zMap
        [tToZimg, outputName] = convertTstatsToZscore(glmFileName, dof);
        fprintf('Zmap saved as %s\n', outputName);
        
        % alternative is getting the 1 tvalue - please see below
        
      for iMask = 1:size(opt.maskFile,2)
        
        % get mask image
        % use a predefined mask, only calculate voxels within the mask
        % below is same resolution as the functional images
        maskType = opt.maskType;
        if numel(opt.maskLabel) > 1
            maskType = [opt.maskType, '-', opt.maskLabel{iMask}];
        end
        
        %get the mask
        maskFileName = opt.maskFile{iSub, iMask};
        
        %load the mask
        maskHdr = spm_vol(maskFileName);
        maskImg = spm_read_vols(maskHdr);
        
%         % put z/t image with iMask -- masking
%         tImg(~maskImg) = 0;
%         
%         % save zscore image
%         tHdr.fname = spm_file(tHdr.fname, 'filename', 'maskedspmT_0068.nii');
%         spm_write_vol(tHdr, tImg);
% somewhere here take the tImg and after masking take the highest value and
% convert that tvalue into z value
        
        % get the highest z-score for a given mask
        
        % save as .csv the z score from glm/fft into a structure
        
        % save as .mat file
        
      end
    end

end




function outputImage = getTimage(results)
  % find the spmT.nii file that is already thresholded
  
%   contrastName = bids.internal.camel_case(results.Name);
%   pattern = ['^sub-.*.',contrastName,'_.*spmT.nii$'];
  pattern = 'spmT_0068.nii';
  outputImage = spm_select('FPList', results.dir, pattern);

end

function outputImage = getZimage(fftDir)
% find the zmap in a given folder

pattern = '^whole-brain_AvgZTarget_.*bold.nii$';
outputImage = spm_select('FPList', fftDir, pattern);



end