library(tidyverse)
library(ggplot2)

#######
#helper function
#code locations of pauses as before, at, or after intersection. can later
#use mutate to recode as at or not at an intersection
code_locations <- function(stim){
  pause_location_coded <- vector(mode = "list", length = length(stim))
  for (i in 1:length(stim)){
    print(i)
    if(str_detect(stim[i], "10_\\(10;2\\)")){
      pause_location_coded[i] <- "after"
    } else if(str_detect(stim[i], "10_\\(10;8\\)")){
      pause_location_coded[i] <- "at"
    } else if(str_detect(stim[i], "10_\\(6;1\\)")){
      pause_location_coded[i] <- "before"
    } else if(str_detect(stim[i], "10_\\(7;1\\)")){
      pause_location_coded[i] <- "at"
    } else if(str_detect(stim[i], "15_\\(1;3\\)")){
      pause_location_coded[i] <- "at"
    } else if(str_detect(stim[i], "15_\\(10;11\\)")){
      pause_location_coded[i] <- "at"
    } else if(str_detect(stim[i], "15_\\(12;1\\)")){
      pause_location_coded[i] <- "at"
    } else if(str_detect(stim[i], "15_\\(3;5\\)")){
      pause_location_coded[i] <- "at"
    } else if(str_detect(stim[i], "15_\\(5;14\\)")){
      pause_location_coded[i] <- "before"
    } else if(str_detect(stim[i], "15_\\(5;15\\)")){
      pause_location_coded[i] <- "at"
    } else if(str_detect(stim[i], "15_\\(6;7\\)")){
      pause_location_coded[i] <- "at"
    } else if(str_detect(stim[i], "15_\\(7;15\\)")){
      pause_location_coded[i] <- "after"
    } else if(str_detect(stim[i], "15_\\(7;5\\)")){
      pause_location_coded[i] <- "after"
    } else if(str_detect(stim[i], "15_\\(7;7\\)")){
      pause_location_coded[i] <- "before"
    } else if(str_detect(stim[i], "7_\\(4;1\\)")){
      pause_location_coded[i] <- "before"
    } else if(str_detect(stim[i], "7_\\(5;1\\)")){
      pause_location_coded[i] <- "at"
    } else if(str_detect(stim[i], "7_\\(7;1\\)")){
      pause_location_coded[i] <- "after"
    } else if(str_detect(stim[i], "7_\\(6;3\\)")){
      pause_location_coded[i] <- "at"
    }
  }
  return (pause_location_coded)
}

#######

setwd("~/Documents/03_Yale/Projects/005_Thinking_About_Thinking/Code/Data_Analysis")

model_data <- read_csv("Model_Analysis/model.csv")
#participant_data <- read_csv("Participant_Analysis/participants_pilot1.csv")
# participant_data1 <- read_csv("Participant_Analysis/participants_pilot1.csv")
# participant_data2 <- read_csv("Participant_Analysis/participants_pilot2.csv")
participant_data <- read_csv("Participant_Analysis/participants_biglaunch_boot.csv")

participant_data <- participant_data %>% rename(scaled = mean)
participant_data <- participant_data %>% mutate(model_name = "participants1")
# participant_data2 <- participant_data2 %>% rename(scaled = avg_z_proportion_distracted)
# participant_data2 <- participant_data2 %>% mutate(model_name = "participants2")
# 
# participant_data2 <- participant_data2 %>% select(stim, maze_name, pause_location, pause_time, scaled, model_name)

model_data <- model_data %>% mutate(stim = str_sub(maze_name, 1, 2)) %>% 
  mutate(stim = str_replace(stim, "_", "")) %>% mutate(stim = paste(stim, "_", sep = "")) %>%
  mutate(stim = paste(stim, pause_location, sep = "")) %>% mutate(stim = paste(stim, "_", sep = "")) %>%
  mutate(stim = paste(stim, pause_time, sep = ""))

all_data <- full_join(participant_data, model_data)
#all_data <- full_join(participant_data2, all_data)

#drop row 14 or 15 because they're basically duplicates. just for the shuffled model
#all_data <- all_data %>% slice(-14)

#################################################################################

temp <- all_data %>% select(model_name, stim, scaled) %>%
  spread(model_name, scaled)

temp <- drop_na(temp)

cor.test(temp$Attempt5, temp$participants1)#temp$Attempt5)

#plot model predictions against particpant data. line for x=y
ggplot(temp, aes(Attempt5, participants1)) + geom_point() + 
  geom_text(aes(label=stim),hjust=0, vjust=0)# +
  #geom_segment(aes(x = -1, y = -1, xend = 1.5, yend = 1.5))# +
  #theme(aspect.ratio=1)

#Which pauses have the least agreement between the model and participants? The most?
temp <- temp %>% mutate(difference = participants1 - Attempt5)
#View(arrange(temp, desc(abs(temp$difference))))

#cleaing
all_data <- all_data %>% 
  mutate(pretty_stim_name = paste("`", stim, sep="")) %>%
  mutate(pretty_stim_name = paste(pretty_stim_name, "`", sep=""))

#################################################################################
#Barplots

ggplot(all_data, aes(x = model_name, fill = model_name, y = scaled)) + 
  geom_bar(stat = "identity") +
  facet_wrap(~pretty_stim_name)

#################################################################################

all_data %>% ggplot(aes(pretty_stim_name, scaled, color = model_name)) + geom_point() +
  geom_errorbar(aes(ymin = ci_lower, ymax = ci_upper)) + facet_wrap(~pretty_stim_name) +
  coord_flip()

all_data <- all_data %>% mutate(dummy = 1)

all_data %>% ggplot(aes(dummy, scaled, color = model_name)) + geom_point() +
  geom_linerange(aes(ymin = ci_lower, ymax = ci_upper)) + facet_wrap(~pretty_stim_name) +
  coord_flip()

#################################################################################
all_data$location_wrt_intersection <- code_locations(all_data$stim)
all_data <- as.data.frame(lapply(all_data, unlist)) #have to do because code location made a list

temp <- all_data %>% select(model_name, stim, scaled, location_wrt_intersection, pause_time) %>% spread(model_name, scaled)
cor.test(temp$Attempt5, temp$participants1)

ggplot(temp, aes(Attempt5, participants1)) + 
  geom_point(aes(color = location_wrt_intersection, size = pause_time)) + 
  scale_color_manual(values=c("#004c6d", "#6996b3", "#c1e7ff")) +
  scale_size(range = c(1, 3)) +
  geom_smooth(method='lm') + 
  xlab("Model Predictions") + ylab("Participant Judgements") + 
  theme(aspect.ratio=1) 

ggplot(temp, aes(Attempt5, participants1)) + 
  geom_point() + 
  #geom_smooth(method='lm') + 
  xlab("Model Predictions") + ylab("Participant Judgements") + 
  theme(aspect.ratio=1) 


# +
  #geom_text(aes(label=stim),hjust=0, vjust=0)# +
#geom_segment(aes(x = -1, y = -1, xend = 1.5, yend = 1.5))# +
#theme(aspect.ratio=1)

#################################################################################
#Try a cue-based regression
#Regression1: pause time
participants <- all_data %>% filter(model_name == "participants1")

output1 <- lm(participants$scaled ~ participants$pause_time)
summary(output1)

#Regression2: at intersection or not
participants$location_wrt_intersection <- code_locations(participants$stim)
participants <- participants %>% mutate(at_intersection = location_wrt_intersection=="at")

output2 <- lm(participants$scaled ~ participants$at_intersection)
summary(output2)

#Regression3: both pause time and intersection together
output3 <- lm(scaled ~ pause_time + at_intersection + pause_time:at_intersection, participants)
summary(output3)
#################################################################################
#Barplots with regression model predictions
predict(output1, )

ggplot(all_data, aes(x = model_name, fill = model_name, y = scaled)) + 
  geom_bar(stat = "identity") +
  facet_wrap(~pretty_stim_name)

which_stim <- c("10_(6;1)_320", "10_(7;1)_320", "10_(10;2)_320", "15_(1;3)_320", "7_(5;1)_320")

subset <- all_data %>% filter(stim %in% which_stim)
which_indices = all_data$stim %in% which_stim

pause_lm = predict(output1)[which_indices[1:23]]

new_data_1 <-
  data.frame(
  model_name = rep("pause_lm", length(which_stim)),
  scaled = pause_lm,
  stim = subset$stim[1:length(which_stim)],
  maze_name = subset$maze_name[1:length(which_stim)],
  pause_location = subset$pause_location[1:length(which_stim)],
  pause_time = subset$pause_time[1:length(which_stim)],
  pretty_stim_name = subset$pretty_stim_name[1:length(which_stim)],
  location_wrt_intersection = subset$location_wrt_intersection[1:length(which_stim)]
)

where_lm = predict(output2)[which_indices[1:23]]
  
new_data_2 <-
  data.frame(
    model_name = rep("where_lm", length(which_stim)),
    scaled = where_lm,
    stim = subset$stim[1:length(which_stim)],
    maze_name = subset$maze_name[1:length(which_stim)],
    pause_location = subset$pause_location[1:length(which_stim)],
    pause_time = subset$pause_time[1:length(which_stim)],
    pretty_stim_name = subset$pretty_stim_name[1:length(which_stim)],
    location_wrt_intersection = subset$location_wrt_intersection[1:length(which_stim)]
  )

# both_cues_lm = predict(output3)[which_indices[1:23]]

# new_data_3 <-
#   data.frame(
#     model_name = rep("both_cues_lm", length(which_stim)),
#     scaled = both_cues_lm,
#     stim = subset$stim[1:length(which_stim)],
#     maze_name = subset$maze_name[1:length(which_stim)],
#     pause_location = subset$pause_location[1:length(which_stim)],
#     pause_time = subset$pause_time[1:length(which_stim)],
#     pretty_stim_name = subset$pretty_stim_name[1:length(which_stim)],
#     location_wrt_intersection = subset$location_wrt_intersection[1:length(which_stim)]
#   )


regression_df <- full_join(new_data_1, new_data_2)

#regression_df <- full_join(regression_df, new_data_3)

everything <- full_join(subset, regression_df)

ggplot(everything, aes(x = model_name, fill = model_name, y = scaled)) + 
  geom_bar(stat = "identity") +
  facet_wrap(~pretty_stim_name) +
  geom_errorbar(aes(ymin = ci_lower, ymax = ci_upper)) +
  theme(aspect.ratio=1) 

ggplot(subset, aes(x = model_name, fill = model_name, y = scaled)) + 
  geom_bar(stat = "identity") +
  facet_wrap(~pretty_stim_name) +
  geom_errorbar(aes(ymin = ci_lower, ymax = ci_upper)) +
  theme(aspect.ratio=1) 

########################################################
#p values for comparing correlations
library(cocor)

pause_lm = predict(output1)

partic_data <- all_data %>% filter(model_name=="participants1")
model <- all_data %>% filter(model_name=="Attempt5")

new_data_1 <-
  data.frame(
    model_name = rep("pause_lm", length(pause_lm)),
    scaled = pause_lm,
    stim = partic_data$stim,
    maze_name = partic_data$maze_name,
    pause_location = partic_data$pause_location,
    pause_time = partic_data$pause_time,
    pretty_stim_name = partic_data$pretty_stim_name,
    location_wrt_intersection = partic_data$location_wrt_intersection
  )

where_lm <- predict(output2)

new_data_2 <-
  data.frame(
    model_name = rep("where_lm", length(where_lm)),
    scaled = where_lm,
    stim = partic_data$stim,
    maze_name = partic_data$maze_name,
    pause_location = partic_data$pause_location,
    pause_time = partic_data$pause_time,
    pretty_stim_name = partic_data$pretty_stim_name,
    location_wrt_intersection = partic_data$location_wrt_intersection
  )

both_cues_lm <- predict(output3)

new_data_3 <-
  data.frame(
    model_name = rep("both_cues_lm", length(both_cues_lm)),
    scaled = both_cues_lm,
    stim = partic_data$stim,
    maze_name = partic_data$maze_name,
    pause_location = partic_data$pause_location,
    pause_time = partic_data$pause_time,
    pretty_stim_name = partic_data$pretty_stim_name,
    location_wrt_intersection = partic_data$location_wrt_intersection
  )

partic_data <- partic_data %>% select(-n, -empirical_stat, -ci_upper, -ci_lower, -dummy)
model <- model %>% select(-mean_time_distracted, -time_thinking, -sd_time_distracted, -proportion_distracted, -dummy)

pause_lm_main_model <- full_join(partic_data, new_data_1)
everything <- full_join(pause_lm_main_model, new_data_2)
everything <- full_join(pause_lm_main_model, new_data_3)
everything <- full_join(everything, model)
everything <- everything  %>% spread(model_name, scaled)

cocor(~participants1 + Attempt5 | participants1 + pause_lm, everything)
cocor(~participants1 + Attempt5 | participants1 + where_lm, everything)

cor.test(everything$participants1, everything$where_lm)

########################################################
ggplot(everything, aes(both_cues_lm, participants1))+ 
  geom_point() + 
  geom_smooth(method='lm') + 
  xlab("Both Cues Predictions") + ylab("Participant Judgements") + 
  theme(aspect.ratio=1) 

########################################################
#check model's correlation for each clump of data
#split by participant judgements = 0.5
lower_cluster = everything %>% filter(participants1 < 0.5)
upper_cluster = everything %>% filter(participants1 > 0.5)
#correlation in lower cluster
cor.test(lower_cluster$participants1, lower_cluster$Attempt5)
#try removing outlier in lower cluster
lower_cluster_rm_outlier = lower_cluster %>% filter(Attempt5 < 0.4)
cor.test(lower_cluster_rm_outlier$participants1, lower_cluster_rm_outlier$Attempt5)

#correlation in upper cluster
cor.test(upper_cluster$participants1, upper_cluster$Attempt5)
#try removing outlier in upper cluster
upper_cluster_rm_outlier = upper_cluster %>% filter(Attempt5 < 2)
cor.test(upper_cluster_rm_outlier$participants1, upper_cluster_rm_outlier$Attempt5)
########################################################
#scatterplot for comparing these lms to participant data
ggplot(temp, aes(pause_lm, participants1)) + 
  geom_point() + 
  #geom_smooth(method='lm') + 
  xlab("Pause LM Predictions") + ylab("Participant Judgements") + 
  theme(aspect.ratio=1) 

ggplot(temp, aes(where_lm, participants1)) + 
  geom_point() + 
  #geom_smooth(method='lm') + 
  xlab("Intersection LM Predictions") + ylab("Participant Judgements") + 
  theme(aspect.ratio=1)
