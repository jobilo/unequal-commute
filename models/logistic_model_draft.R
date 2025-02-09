library(readr)
library(tidyverse)
library(InformationValue)
job_access_gap <- read_csv("data/job_access_gap.csv")
model_data <- read_csv("models/model_data.csv")
model_data_na <- na.omit(model_data)

summary(model_data_na$spatialmismatch)
boxplot(model_data_na$spatialmismatch)

job_access_gap %>%
  ggplot(aes(x = MSA, y = spatialmismatch)) +
  geom_boxplot() +
  coord_flip()

#cut off at mean
cat_data <- model_data_na %>%
  mutate(high = spatialmismatch>0.07225)

cat_data$high <- as.numeric(cat_data$high)

#plots will contain warnings but it's just for initial observations and not final model 
plot(jitter(high,amount=.05) ~ spanish, data = cat_data, family = "binomial")
plot(jitter(high,amount=.05) ~ median_household_income, data = cat_data, family = "binomial")
plot(jitter(high,amount=.05) ~ above_bach, data = cat_data, family = "binomial")
plot(high~above_bach, data = cat_data, family = "binomial")
plot(jitter(high,amount=.05) ~ below_bach, data = cat_data, family = "binomial")
plot(jitter(high,amount=.05) ~ bach_interact, data = cat_data, family = "binomial")
plot(jitter(high,amount=.05) ~ phd, data = cat_data, family = "binomial")
plot(jitter(high,amount=.05) ~ white, data = cat_data, family = "binomial")
plot(jitter(high,amount=.05) ~ nonwhite, data = cat_data, family = "binomial")
plot(jitter(high,amount=.05) ~ people_per_sqmi, data = cat_data, family = "binomial")
plot(jitter(high,amount=.05) ~ english_better, data = cat_data, family = "binomial")

m1 <- glm(high~spanish + median_household_income + below_bach + above_bach + bach_interact + phd + white + nonwhite 
          + people_per_sqmi + english_better, data = cat_data, family = "binomial")
summary(m1)

m2 <- glm(high~median_household_income + above_bach + below_bach + bach_interact + phd + white, data = cat_data, family = "binomial")
summary(m2)

G = m2$deviance - m1$deviance
Gdf = m2$df.residual - m1$df.residual
pchisq(G, df = Gdf, lower.tail = F)

addmargins(table(cat_data$high, as.numeric(m2$fitted.values >= .5)))

#percent correctly classified
(addmargins(table(cat_data$high, as.numeric(m2$fitted.values >= .5)))[1,1] + 
  addmargins(table(cat_data$high, as.numeric(m2$fitted.values >= .5)))[2,2])/
  addmargins(table(cat_data$high, as.numeric(m2$fitted.values >= .5)))[3,3]

#c-stat
cstat <- function(model){
  # extract actual results and predicted probabilities from model
  results <- data.frame(actual = model$y, prob = model$fitted.values)
  # split results into subsets based on actual results
  successes <- subset(results, actual == 1)
  failures <- subset(results, actual == 0)
  2
  # initialize counter for concordant pairs
  concordant_pairs = 0
  # loop to count concordant pairs
  for(i in 1:nrow(successes)){
    concordant_pairs = concordant_pairs + (sum(successes$prob[i] > failures$prob))
  }
  # compute and output c-statistic
  concordant_pairs/(nrow(successes)*nrow(failures))
}
cstat(m1)

addmargins(table(m1$y, as.numeric(m1$fitted.values >= 0.5)))
table(cat_data$high[m1$na.action])
(676+972+33)/(2441+33+9)

Concordance(m1$y, m1$fitted.values)
Concordance(m2$y, m2$fitted.values)
