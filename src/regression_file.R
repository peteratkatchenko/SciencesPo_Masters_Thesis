library(alpaca)

extensive_counts_1 <- read.csv("C:/Users/peter/.julia/dev/extensive_counts_1.csv")

extensive_counts_1$id <- factor(extensive_counts_1$id, ordered = FALSE)
extensive_counts_1$county <- factor(extensive_counts_1$county, ordered = FALSE)
extensive_counts_1$ind4 <- factor(extensive_counts_1$ind4, ordered = FALSE)

model_1 <- feglm(patents_count ~ binary_own + mean_employee| ind4, data = extensive_counts_1, family = poisson())

model_1 <- feglm(patents_count ~ binary_own + mean_employee| ind4 + id, data = extensive_counts_1, family = poisson())

model_1 <- feglm(patents_count ~ binary_own + mean_employee| ind4 + id + county, data = extensive_counts_1, family = poisson())



model_2 <- glm(patents_count ~ binary_own, data = extensive_counts_1, family = poisson())
summary_2 <- summary(model_2)
coefs_2 <- summary(model_2)$coefficients
print(coefs_2)

model_3 <- glm(patents_count ~ binary_own + mean_output, data = extensive_counts_1, family = poisson())
summary_3 <- summary(model_3)
coefs_3 <-summary_3$coefficients
print(coefs_3)
  
model_4 <- glm(patents_count ~ binary_own + mean_output + ind4, data = extensive_counts_1, family = poisson())
summary_4 <- summary(model_4)
coefs_4 <- summary_4$coefficients
print(coefs_4)







