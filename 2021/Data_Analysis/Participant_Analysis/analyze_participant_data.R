library(tidyverse)
library(ggplot2)

setwd("~/Documents/03_Yale/Projects/005_Thinking_About_Thinking/Code/Data_Analysis/Participant_Analysis")
source("helper_functions.R")
data <- read_csv("Mazes2_biglaunch.csv")

#pilot 1
ids = c("5f8f47a3aa730f19081fe0ac", "5d584a10a0c0940001a46efd", "5c6b52dfd6c7500001a05278",
        "56f29effed0cf60006911528", "5f4d52bb1c7d049f204df2ce", "5d47292b4bfe1600016925ac",
        "5dd2db924524e72e0773800f", "5f6d135caa7332173e872d0a", "5c92590a1f991d00161a6fa3",
        "5f52fcc68c2b9c601336f237", "5fb695210ebd520776bf0e03", "5a0071766e1ea9000124db35",
        "58ae2c4ed6a2220001179f7c", "5dcb1db49173807fc66660cb", "5fbe8b008273fa000c700e13",
        "57d8e1cdb9fb6f0001dda345", "5f5fef6ce0809f0d5b3cde5c", "5f4d1d7cc185c2988b377aa8",
        "5e0d774811999f502233d6ee")

ids = c("marlenetest")

#pilot2
ids = c("5f0100dbce37ac11522d8260", "5f1d5153d29e11661b41cbd6", "5f22fa6a36f76903b919037a",
        "5ec771e68288e91bf1919096", "5ff42a8d827f81aaf529e78b", "5fa5c1efbc1fcb155bf0e4dd",
        "5be8fae440b06b0001373025", "5ad5b7d8546e150001b69efd", "5bb4d40f3ecb69000146c17a",
        "5e6bc63526b6460009d2ce24", "5b4f9754995d4e0001095af9", "5e7daa886c123242e86c8138",
        "5f08afdf89789f0f445199ad", "5fbbf5116f217f03bb94c292",
        "5e6fbe91dcac9002a75e96c6", "5e1fc8d45427912f6143b012", "5c0fa46ebeb54500011921dc",
        "5fb6da2d039b27111314d871", "5ff337a16a36578cb5f94574")

#big launch
ids <- c("59dc1e0924d7bf00012f096f", "5d14de777091ed0015774f0f", "5ee3ac368e523a05ad561ae5",
         "5fbb9d43846c1196282151be", "5886d67b3e1f290001aa7529", "5c40134b1580e900012320ab",
         "5dc4c7fe96a93938462aa2bc", "5eed8bec94fa2f1be77c189a", "5dd72efa82569a6d38e06854",
         "5e6d915ba20e47358d14e376", "5ea0bb3b21f4e40b15f1953c", "5d54beb0c15b0700018d0211",
         "5d2fc2574fc1dd0017fe490a", "5f31961c57eb9507db148757", "5e69be2cd02ab2027bff5108",
         "5c6071a1e1df700001ca8bf1", "5b9ece575813c900011800ae", "5e9a90794a7e88127a8fe01e",
         "5e9558165c273912f2efbbe4", "5fa8b4123a3f0d7a4aab8ef3", "5eb44d0995eefd2923fcce92",
         "5eb1f5a1ea17ac343ea0c4d1", "5bdf4540378c3d000161e102", "5f765a3c8a6ec010370c9cc1",
         "5dcf125e8f45b906381b00fa", "5f877b0fdf57661a49364047", "5f839de3c11409537caccb9c",
         "5fabf60a1d67830bec1b3625", "56f2a49ced0cf600069131cd", "5f8ff4c16371760252edef17",
         "5e5d641259df370779040d9e", "5f60d39b4e8a86050914438d", "5f2c3bb7da92d30bdf535d97",
         "5da689dc1ce19b0016500435", "5befb1ba2d0a5e0001b3ada3", "5ffe6b8b773ec452c1d28adc",
         "5e523ca8df9ae92581169f1d", "5fc5011a78eea208787ef509", "5f4172b62cd45930d478e9e4",
         "5f6cde418d7ea80f7e5e6939", "5f345490d929cc1a6e927496", "60149bde2b50d9507b7b8242",
         "5fca97a4b105427256733533", "5d4459c166881d001c4d5451", "5b2489070ec82d0001d1dbb2",
         "5ecd1abd0c7d0703501a618f", "5f87e396bea4ed2252321e1d", "5f39c9babf015058a8ff7aa4",
         "5e975c32ca82b62079dc8f7c", "5e2bf2153a9311222d4892c6")

#data <- filter(data, !is.na(Comprehension_MC))
#data <- data %>% slice_tail(n = 1) #just getting the last row

data <- filter(data, ProlificID %in% ids)
###################################################################################################
#Demographic data for reporting
dem_data <- data %>% select(Age) %>% drop_na()
dem_data$Age <- as.numeric(dem_data$Age)
mean(dem_data$Age)
range(dem_data$Age)
###################################################################################################
data <- data %>% select(contains(c("ProlificID","7_","10_","15_"))) %>% select(-contains("Q"))
data <- drop_na(data)

data <- data %>% gather(key="stim", value="proportion_distracted", -ProlificID)
data$proportion_distracted <- as.numeric(data$proportion_distracted)
#########################################################################################################

#zscore within each participant
data <- data %>% group_by(ProlificID) %>% mutate(z_proportion_distracted = scale(proportion_distracted)[,1])

#t.test((data %>% filter(stim=="10_(10;2)_320_1"))$z_proportion_distracted, (data %>% filter(stim=="10_(10;8)_320_1"))$z_proportion_distracted)

#Bootstrap
library(tidyboot)
temp <- data %>% group_by(stim) %>% tidyboot_mean(z_proportion_distracted)

#average the z_proportion_distracted for each stim
# temp <- data %>% group_by(stim) %>% 
#   summarize(avg_z_proportion_distracted = mean((z_proportion_distracted)), 
#             sd_z_proportion_distracted = sd((z_proportion_distracted)))
#assuming participant responses for each stim is normally distributed. not a terrible assumption.






# temp <- temp %>% mutate(lower_ci = avg_z_proportion_distracted-1.96*sd_z_proportion_distracted,
#                         upper_ci = avg_z_proportion_distracted+1.96*sd_z_proportion_distracted)

temp <- separate(temp, stim, into = c("maze_name", "pause_location", "pause_time", NA), sep = "_", remove=FALSE)

temp$maze_name <- change_maze_name(temp$maze_name)
temp$stim <- change_stim(temp$stim)


#save data as a .csv file
write_csv(temp, "participants_biglaunch_boot.csv")

