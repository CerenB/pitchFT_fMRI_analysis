
% this is a script for converting HMAT masks into subject space mask
% alternative script is converting Freesurfer(FS) masks into MNI mask

% idea behind is this: use HMAT masks but limit them a bit with FS
% BA6 label. In FS, BA6 label contains all SMA, premotor, etc... We need to
% separate these regions in BA6 label by using HMAT masks. 
% so we should work in native space. 

% in this way, we would have auditory cortex, BG, and preSMA, SMA, premotor
% all in native subject space. 

% then we can use these masks to run decoding, and FFT. 

% GOAL
% 0. Insert 1x1x1mm masks into group folder with bids-valid name
% 1. First reslice the ROI according to ?THE NORMALIZED? functional image.
% 2. Then do the inverse transformation
% Note: Use nearest neighbour interpolation as well when doing the reverse transformation


% reslicing the roi according to the w- functional image (or Tmap.nii)

% set paths
warning('off');
addpath(genpath('/Users/battal/Documents/MATLAB/spm12'));

% add cpp repo
run ../lib/CPP_BIDS_SPM_pipeline/initCppSpm.m;

% get parameters
% opt = getOptionPitchFT();

% try with Block if it provides same masks or not
opt = getOptionRhythmBlock();

% dont start from copying the raw masks
opt.copyRaw.do = false; 

% reslice the mask into mni  func space
opt.reslice.do = true; 

% reslice mask to normalised func space 
% (only once is enough for MNI space roi)
opt.resliceFunc.do = false;

% transform space from "mni func image" to "individual func image" 
opt.inversTransform.do = true; 

% count the mask voxel
opt.countVoxel.do = true;

% use anat image for mask resolution? If so it'll be 1x1x1mm
opt.roi.anatBased  = false; 


opt.roi.space = 'individual';

funcFWHM = 2;


%% let's start
[BIDS, opt] = setUpWorkflow(opt, 'create ROI');

spm_mkdir(fullfile(opt.dir.roi, 'derivatives', 'group'));

opt.jobsDir = fullfile(opt.dir.roi, 'derivatives', 'JOBS', opt.taskName);
  
  
  
% TODO - copy from source to raw

if opt.copyRaw.do
    
    % first rename HMAT rois into more bids-friendly way
    maskAll = dir(fullfile(opt.dir.roi,'raw','*.nii'));
    
    for iFile = 2:numel(maskAll)
        % raw file
        rawMask = fullfile(opt.dir.roi,'raw', maskAll(iFile).name);
        
        % rename HMAT masks
        rawMask = renameHmat(rawMask);
        
        % now it's bids-friendly, lets move them to derivatives
        groupMask = strrep(rawMask, 'raw', 'derivatives/group');
        copyfile(rawMask, groupMask);
    end
    
end

%read the recently renamed files in derivatives
maskAll = dir(fullfile(opt.dir.roi,'derivatives','group', '*_mask.nii'));


%% reslice the ROI with our normalised functional toy image
if opt.reslice.do
    % If needed reslice probability map to have same resolution as the data image
    %
    % resliceImg won't do anything if the 2 images have the same resolution
    %
    % if you read the data with spm_summarise,
    % then the 2 images do not need the same resolution.
    
    opt.space = 'MNI'; % make sure we are in normalised space
    
    for iSub = 1:numel(opt.subjects)
        
        % get subject folder name
        subLabel = opt.subjects{iSub};
        subFolder = ['sub-', subLabel];
        
        % get FFX path
        ffxDir = getFFXdir(subLabel, funcFWHM, opt);
        
        % toy data to be used for reslicing
        dataImage = fullfile(ffxDir, 'spmT_0001.nii');
        
        
        for iMask = 1:length(maskAll)
            
            % read the mask
            groupMask =  fullfile(opt.dir.roi,'derivatives', 'group', ...
                                 maskAll(iMask).name);
            
            %copy it into subject specific folder
            funcMask = fullfile(opt.dir.roi,'derivatives',subFolder, ...
                maskAll(iMask).name);
            copyfile(groupMask, funcMask);
            
            % reslice the mask in subject specific folder
            funcMask = resliceRoiImages(dataImage, funcMask);
            funcMask = removeSpmPrefix(funcMask, ...
                                         spm_get_defaults('realign.write.prefix'));
            
            % TODO
            % rename resliced images with bids formatting, so that files
            % can have a link between this step and the following
            
        end
    end
    
end

if opt.resliceFunc.do
    spm_mkdir(fullfile(opt.dir.roi, 'derivatives', 'group', 'func'));
    opt.space = 'MNI'; % make sure we are in normalised space
    
    for iSub = 1:numel(opt.subjects)
        
        % get subject folder name
        subLabel = opt.subjects{iSub};
        subFolder = ['sub-', subLabel];
        
        % get FFX path
        ffxDir = getFFXdir(subLabel, funcFWHM, opt);
        
        % toy data to be used for reslicing
        dataImage = fullfile(ffxDir, 'spmT_0001.nii');
        
        
        for iMask = 1:length(maskAll)
            
            % read the mask
            groupMask =  fullfile(opt.dir.roi,'derivatives', 'group', ...
                maskAll(iMask).name);
            
            %copy it into subject specific folder
            funcMask = fullfile(opt.dir.roi,'derivatives','group', ...
                'func', maskAll(iMask).name);
            copyfile(groupMask, funcMask);
            
            % reslice the mask in subject specific folder
            funcMask = resliceRoiImages(dataImage, funcMask);
            funcMask = removeSpmPrefix(funcMask, ...
                spm_get_defaults('realign.write.prefix'));
            
            % TODO
            % rename resliced images with bids formatting, so that files
            % can have a link between this step and the following
            
        end
    end
end

    


%% let's do the inverse transformation now
% now we need to be in individual subject space
if opt.inversTransform.do && any(strcmp(opt.roi.space, 'individual'))
    
    opt.space = 'individual'; % make sure we are in subject space
    
    count = 1;
    
    for iSub = 1:numel(opt.subjects)
        
        subLabel = opt.subjects{iSub};
        subFolder = ['sub-', subLabel];
        
        printProcessingSubject(iSub, subLabel);
        
        roiList = spm_select('FPlist', ...
            fullfile(opt.dir.roi,'derivatives',subFolder), ...
            '^space.*_mask.nii.*$');
        
        %% inverse normalize
        % normalise mask according to functional image res
        [image, dataDir] = getMeanFuncFilename(BIDS, subLabel, opt);
        
        if opt.roi.anatBased
            %then the resolution of the mask will be anat image res
            [image, dataDir] = getAnatFilename(BIDS, subLabel, opt);
        end
        
        deformation_field = spm_select('FPlist', dataDir, ['^iy_' image '$']);
        
        matlabbatch = {};
        for iROI = 1:size(roiList, 1)
            matlabbatch = setBatchNormalize(matlabbatch, ...
                {deformation_field}, ...
                nan(1, 3), ...
                {deblank(roiList(iROI, :))});
            matlabbatch{end}.spm.spatial.normalise.write.woptions.bb = nan(2, 3);
        end
        
        
        saveAndRunWorkflow(matlabbatch, 'inverseNormalize', opt, subLabel);
        
        %% rename file
        roiList = spm_select('FPlist', ...
            fullfile(opt.dir.roi,'derivatives',subFolder), ...
            '^wspace.*_mask.nii.*$');
        
        for iROI = 1:size(roiList, 1)
            
            roiImage = deblank(roiList(iROI, :));
            
            % rename
            p = bids.internal.parse_filename(spm_file(roiImage, 'filename'));
            
            entities = struct('space', 'individual', ...
                'hemi', p.entities.label(1), ...
                'label', p.entities.label(3:end), ...
                'desc', 'inverseTransform');
            
            nameStructure = struct('entities', entities, ...
                'suffix', 'mask', ...
                'ext', '.nii');
            nameStructure.use_schema = false;
            
            newName = bids.create_filename(nameStructure);
            
            movefile(roiImage, fullfile(opt.dir.roi,'derivatives',subFolder, ...
                newName));
            
        end
        
    end
end

if opt.countVoxel.do
    info = struct();
    count = 1;
    
    for iSub = 1:numel(opt.subjects)
        
        subLabel = opt.subjects{iSub};
        subFolder = ['sub-', subLabel];
        
        roiList = spm_select('FPlist', ...
            fullfile(opt.dir.roi,'derivatives',subFolder), ...
            '^space.*inverseTransform_mask.nii.*$');
        
        for iROI = 1:size(roiList, 1)
            
            roiImage = deblank(roiList(iROI, :));
            
            p = bids.internal.parse_filename(spm_file(roiImage, 'filename'));
            roiName = [p.entities.hemi, p.entities.label];
            
            % read how many voxels it has
            hdr = spm_vol(roiImage);
            img = spm_read_vols(hdr);
            
            voxelNb = sum(img(:));
            
            % save this info
            info(count).SUBname = subLabel;
            info(count).ROIname = roiName;
            info(count).ROInumVox = voxelNb;
            count = count + 1;
            
        end
    end
end
