
change_maze_name <- function (maze_name) {
  for (i in 1:length(maze_name)) {
    if (maze_name[i]==7) {
      maze_name[i] = "7_by_7_maze_4"
    } else if (maze_name[i]==10) {
      maze_name[i] = "10_by_10_maze_2"
    } else if (maze_name[i]==15) {
      maze_name[i] = "15_by_15_maze_6"
    }
  }
  return(maze_name)
}

change_stim <- function (stim) {
  for (i in 1:length(stim)) {
    stim[i] <- substr(stim[i], 1, nchar(stim[i])-2)
  }
  return(stim)
}
