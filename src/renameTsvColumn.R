library(tidyverse)

# let's read tsv files and reorganize the trial_type so each repetition of 
# a condition would be labeled differently and thus we can model them in 
# GLM as separated regressors == separated betas

pathToFunc <- '/Users/battal/Cerens_files/fMRI/Processed/RhythmCateg/RhythmBlock/code/rhythmBlock_fMRI_analysis/lib/bids-R/bidsr_queryEvents.R'
source(pathToFunc)


# i'd like to change the .tsv files in derivatives folder (could be raw folder instead)
bidsRoot <- '/Users/battal/Cerens_files/fMRI/Processed/RhythmCateg/PitchFT/derivatives/cpp_spm/sub-001' 
taskName <- 'PitchFT' 

taskEventsFiles <- bidsr_queryEvents(bidsRoot = bidsRoot, 
                                     taskName = taskName)

# # OPTION 1 - complex_A and complex_B made
# # for loop to make multiple regressors of 1 condition (1 repetition = 1 regressor)
# for (i in 1:length(taskEventsFiles)) {
# 
#   tsv <- read.table(paste(bidsRoot, taskEventsFiles[i], sep = '/'), header = TRUE)
# 
#   # if it is simple_block or complex_block, rewrite it with "simple_block_stepNum"
#   tsv$trial_type <- ifelse(tsv$F0 == '277.183' & tsv$trial_type == 'block_complex',
#                             paste(tsv$trial_type, 'B', sep = '_'), tsv$trial_type)
#   
#   tsv$trial_type <- ifelse(tsv$trial_type == 'block_complex',
#                            paste(tsv$trial_type, 'A', sep = '_'), tsv$trial_type)
# 
#   write.table(tsv,
#               paste(bidsRoot, taskEventsFiles[i], sep = '/'),
#               row.names = FALSE,
#               sep = '\t',
#               quote = FALSE)
# 
# }

# OPTION 2 - complex_A_$segmentNum, complex_B_$segmentNum
for (i in 1:length(taskEventsFiles)) {
  
  tsv <- read.table(paste(bidsRoot, taskEventsFiles[i], sep = '/'), header = TRUE)
  
  # if it is complex_block, rewrite it with "complex_block_segmentNum"
  tsv$trial_type <- ifelse(tsv$trial_type == 'block_complex_A' | tsv$trial_type == 'block_complex_B',
                           paste(tsv$trial_type, tsv$segmentNum, sep = '_'), tsv$trial_type)
  
  write.table(tsv,
              paste(bidsRoot, taskEventsFiles[i], sep = '/'),
              row.names = FALSE,
              sep = '\t',
              quote = FALSE)
  
}
