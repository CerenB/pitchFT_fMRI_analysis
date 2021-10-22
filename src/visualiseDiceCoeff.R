rm(list=ls()) #clean console

library(ggplot2)
library(doBy)
library(cowplot)
library(Rmisc)
library(stringr)


#######################################################
resultPath <- '/Users/battal/Cerens_files/fMRI/Processed/RhythmCateg/PitchFT/derivatives/rnb_fft/group/dice-coeff/task-PitchFT_space-MNI_FWHM-2_desc-A1GtB3Run'



##### 
# read the files 

# dataNames <- paste(resultPath, '*.csv', sep ='/')
dataNames = "WholeBrain_FFT_N-12_p-All_202110141454.csv"
temp = list.files(path = resultPath, pattern=dataNames)
csvFileNb <- length(temp)     

resultFiles = list()
for (i in 1:csvFileNb) {
  fileToRead = paste(resultPath, temp[i], sep ='/')
  x  = read.csv(fileToRead)
  
  # add zvalue column if it does not exist
  x$zvalue <- with(x, if ("zvalue" %in% colnames(x)) zvalue else pvalue)
  
  x$FileID <- i
  resultFiles[i] = list(x)
}

# bind txt files using rbind comment
dice <- NA
dice = do.call(rbind, resultFiles)

######
# reorganise it better
# add model names
dice$model <- ifelse(dice$FileID ==1, 'FFT', 'GLM')


# correct zvalue
dice$zvalue <- ifelse(dice$zvalue ==0.0001, 3.72, 
                      ifelse(dice$zvalue ==0.001, 3.09,
                             ifelse(dice$zvalue ==0.00001, 4.26, dice$zvalue)))

# remove the fileID column
dice[,9] <- NULL
dice[,9] <- NULL
dice[,9] <- NULL
dice[,9] <- NULL

# summary info
df <- summarySE(data = dice, 
                groupvars=c('pvalue', 'model'),
                measurevar='coeff')
df

df <- summarySE(data = dice, 
                groupvars=c('pvalue'),
                measurevar='coeff')
df


