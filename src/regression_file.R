library(alpaca)
library(texreg)
library(stargazer)

extensive_counts_1 <- read.csv("C:/Users/peter/.julia/dev/extensive_counts_1.csv")


extensive_counts_1$id <- factor(extensive_counts_1$id, ordered = FALSE)
extensive_counts_1$county <- factor(extensive_counts_1$county, ordered = FALSE)
extensive_counts_1$ind4 <- factor(extensive_counts_1$ind4, ordered = FALSE)

extensive_counts_2 <- read.csv("C:/Users/peter/.julia/dev/extensive_counts_2.csv")

extensive_counts_2$id <- factor(extensive_counts_2$id, ordered = FALSE)
extensive_counts_2$county <- factor(extensive_counts_2$county, ordered = FALSE)
extensive_counts_2$ind4 <- factor(extensive_counts_2$ind4, ordered = FALSE)
extensive_counts_2$cat_pat <- factor(extensive_counts_2$cat_pat, ordered = FALSE)


#############
#FEGLM Models
#############

model_1 <- feglm(patents_count ~ binary_own + mean_employee| ind4, data = extensive_counts_1, family = poisson())
coefs_1 <- coef(model_1)
summary_1 <- summary(model_1)
print(summary_1)
print(coefs_1)


model_2_ <- feglm(patents_count ~ binary_own + mean_employee| ind4 + county, data = extensive_counts_1, family = poisson())
coefs_2_ <- coef(model_2_)
summary_2_ <- summary(model_2_)
print(summary_2_)
print(coefs_2_)

model_3 <- feglm(patents_count ~ binary_own + mean_employee| county, data = extensive_counts_1, family = poisson())
coefs_3 <- coef(model_3)
summary_3 <- summary(model_3)
print(summary_3)
print(coefs_3)


model_4 <- feglm(patents_count ~ binary_own + mean_employee + binary_own*cat_pat| ind4, data = extensive_counts_2, family = poisson())
summary_4 <- summary(model_4)
coefs_4 <- coef(model_4)
print(coefs_4)

model_5 <- feglm(patents_count ~ binary_own + mean_employee + binary_own*cat_pat| ind4 + county, data = extensive_counts_2, family = poisson())
summary_5 <- summary(model_5)
coefs_5 <- coef(model_5)
print(coefs_5)


model_6 <- feglm(patents_count ~ binary_own + mean_employee + binary_own*cat_pat| county, data = extensive_counts_2, family = poisson())
summary_6 <- summary(model_6)
coefs_6 <- coef(model_6)
print(coefs_6)



#############
#FEGLM Tables
#############

texreg(list(model_1, model_2, model_2_, model_3),
       digits = 3,
       label = "tabl:2",
       caption = "Baseline Model w/ Fixed Effects",
       dcolumn = TRUE, 
       booktabs = TRUE)

texreg(list(model_12, model_13, model_14, model_15), 
       label = "tabl:4",
       caption = "Secondary Model w/ Fixed Effects", 
       dcolumn = TRUE, 
       booktabs = TRUE)



###########
#GLM Models
###########

#extensive_counts_1

model_6 <- glm(patents_count ~ binary_own, data = extensive_counts_1, family = poisson())
summary_6 <- summary(model_6)
coefs_6 <- summary(model_6)$coefficients
print(coefs_6)

model_7 <- glm(patents_count ~ binary_own + mean_output, data = extensive_counts_1, family = poisson())
summary_7 <- summary(model_7)
coefs_7 <-summary_7$coefficients
print(coefs_7)
  
model_8 <- glm(patents_count ~ binary_own + mean_employee, data = extensive_counts_1, family = poisson())
summary_8 <- summary(model_8)
coefs_8 <- summary_8$coefficients
print(coefs_8)

#extensive_counts_2

model_9 <- glm(patents_count ~ binary_own + mean_employee + binary_own*cat_pat, data = extensive_counts_2, family = poisson())
summary_9 <- summary(model_9)
coefs_9 <- summary(model_9)$coefficients
print(coefs_9)
 
model_10 <- glm(patents_count ~ binary_own + mean_output + binary_own*cat_pat, data = extensive_counts_2, family = poisson())
summary_10 <- summary(model_10)
coefs_10 <- summary(model_10)$coefficients
print(coefs_10)



###########
#GLM Tables
###########

stargazer(model_4, model_5, model_6, align = TRUE, 
          title = "Baseline Model w/o Fixed Effects",
          dep.var.labels = c("Total Patent Count"),
          covariate.labels = c("Ownership", "Mean Output", "Mean Employees"))

stargazer(model_7, model_8, model_9, model_10, model_11, align = TRUE,
          title = "Secondary Model w/o Fixed Effects",
          dep.var.labels = c("Total Patent Count per Type"),
          covariate.labels = c("Ownership", "Mean Output", "Mean Employee", "Utility Pat", "Inv Pat", 
                               "Ownership*Utility Pat", "Ownership*Inv Pat"))




