library(ggplot2)
library(tidyverse)
library(stringr)

setwd("~/Documents/03_Yale/Projects/005_Thinking_About_Thinking/Code/Model/Attempt5")
data <- read_csv("output_from_many_runs_small_mazes_full_constraints_big_mazes20window.csv")

data <- data %>% mutate(proportion_distracted = mean_time_distracted/(pause_time)) %>%
  rowwise() %>% mutate(proportion_distracted = min(1, proportion_distracted))
data <- data %>% ungroup() %>% mutate(scaled = scale(proportion_distracted))

data$pause_location <- clean_coordinate(data$pause_location)

clean_coordinate <- function(pause_location){
  for (i in 1:length(pause_location)){
    pause_location[i] <- str_remove(pause_location[i], "Coordinate")
    pause_location[i] <- str_remove_all(pause_location[i], " ")
  }
  return(pause_location)
}

setwd("~/Documents/03_Yale/Projects/005_Thinking_About_Thinking/Code/Data_Analysis/Model_Analysis")
write_csv(data, "model.csv")

#data <- data.frame( mean_time_distracted = c(10), time_thinking = c(20))

#data <- data.frame( time = c(94.959, 175.041, 42.751, 227.249), category = c("distracted", "thinking", "distracted", "thinking"), model = c("shuffle model", "shuffle model", "full search model", "full search model"))

# ggplot(data, aes(time)) +
#   geom_bar(aes(x = model, fill = category, y = time), stat = "identity", position = position_stack())


# seven_by_seven <- data %>% filter(maze_name == " 7_by_7_maze_4")
# gathered <- seven_by_seven %>% gather(key = "thinking_or_distracted", value = "time", c(mean_time_distracted, time_thinking))
# 
# gathered %>% filter(pause_location == " Coordinate(5; 1)") %>%
#   ggplot(aes(time)) +
#   geom_bar(aes(x = pause_time, fill = thinking_or_distracted, y = time), stat = "identity", position = position_stack())
# 
# gathered %>% filter(pause_time == 200) %>%
#   ggplot(aes(time)) +
#   geom_bar(aes(x = pause_location, fill = thinking_or_distracted, y = time), stat = "identity", position = position_stack())
# 
# gathered <- data %>% gather(key = "thinking_or_distracted", value = "time", c(mean_time_distracted, time_thinking))
# 
# gathered %>% filter(pause_location %in% c(" Coordinate(5; 1)", " Coordinate(4; 1)"), pause_time==200) %>%
#   ggplot(aes(time)) +
#   geom_bar(aes(x = pause_location, fill = thinking_or_distracted, y = time), stat = "identity", position = position_stack())
# 
# gathered %>% filter(pause_location %in% c(" Coordinate(5; 15)", " Coordinate(5; 14)"), pause_time==320) %>%
#   ggplot(aes(time)) +
#   geom_bar(aes(x = pause_location, fill = thinking_or_distracted, y = time), stat = "identity", position = position_stack())
# 
