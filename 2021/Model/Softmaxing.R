x <- c(0:15)
y <- 1/(x+1)
think <- tibble(x, y)
ggplot(think, aes(x, y)) + geom_line() +
  scale_y_continuous(limits =c (0,1))


# Softmaxing one variable (deciding what to do based on a single value)

B_0 <- -3
B_1 <- 2.5
think$probability <- 1/(1+exp(B_0 + B_1*think$x))

ggplot(think,aes(x,probability))+geom_line()+
  scale_y_continuous(limits=c(0,1))

# Softmaxing two variables (deciding what to do based on two competing values)

think <- 4
move <- 5

tau <- 3
# when tau is close to 0, the model *always* chooses the best option
# as tau increases, the model starts to choose randomly

(p_think <- exp(think/tau)/(exp(think/tau)+exp(move/tau)))

