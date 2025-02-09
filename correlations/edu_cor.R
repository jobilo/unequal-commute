library(dplyr)
library(openintro)
library(corrplot)
library(leaps)
#library(HH) #HH is incompatible with contains function
library(readr)

acs_dataset <- read_csv("data/acs_dataset.csv")
job_access_gap <- read_csv("data/job_access_gap.csv")

edu_census <- acs_dataset %>%
  select(GEOID,NAME,contains("B15003"))

#using education by for 25+ age
edu_census <- edu_census %>%
  select(c(GEOID, NAME, 
           estimate_B15003_001, #total
           estimate_B15003_002, #no education
           estimate_B15003_016, #12th grade no diploma
           estimate_B15003_017, #high school diploma
           estimate_B15003_018, #GED
           estimate_B15003_019, #some college, <1 year
           estimate_B15003_020, #some college >1 year, no degree
           estimate_B15003_021, #associate degree,
           estimate_B15003_022, #bachelor degree
           estimate_B15003_023, #master degree
           estimate_B15003_024, #professional school degree
           estimate_B15003_025)) #doctoral degree

#some college, <1 year AND  #some college >1 year, no degree
edu_census$somecollege = edu_census$estimate_B15003_019 +
  edu_census$estimate_B15003_020 

# associate, bachelor, master, professional school, doctorate
edu_census$higher_ed = edu_census$estimate_B15003_021 + 
  edu_census$estimate_B15003_022 + 
  edu_census$estimate_B15003_023 + 
  edu_census$estimate_B15003_024 + 
  edu_census$estimate_B15003_025

# master, professional, doctorate
edu_census$post_grad = edu_census$estimate_B15003_023 + 
  edu_census$estimate_B15003_024 + 
  edu_census$estimate_B15003_025

#group above and below Bachelor's level
edu_census$below_bach <- edu_census$estimate_B15003_002 + edu_census$estimate_B15003_016 + edu_census$estimate_B15003_017 + 
                        edu_census$estimate_B15003_018 + edu_census$estimate_B15003_019 + edu_census$estimate_B15003_020 +
                        edu_census$estimate_B15003_021
edu_census$above_bach <- edu_census$estimate_B15003_022 + edu_census$estimate_B15003_023 + edu_census$estimate_B15003_024 +
                        edu_census$estimate_B15003_025

edu_spatial <- left_join(job_access_gap, edu_census,by = "GEOID") %>%
  select(-geometry,-NAME) %>%
  filter(MSA == "Seattle")


#create proportions
edu_spatial$prop_noedu <- edu_spatial$estimate_B15003_002/edu_spatial$estimate_B15003_001
edu_spatial$prop_nodiploma <- edu_spatial$estimate_B15003_016/edu_spatial$estimate_B15003_001
edu_spatial$prop_hsdiploma <- edu_spatial$estimate_B15003_017/edu_spatial$estimate_B15003_001
edu_spatial$prop_GED <- edu_spatial$estimate_B15003_018/edu_spatial$estimate_B15003_001
edu_spatial$prop_lesssomecollege <- edu_spatial$estimate_B15003_019/edu_spatial$estimate_B15003_001
edu_spatial$prop_moresomecollege <- edu_spatial$estimate_B15003_020/edu_spatial$estimate_B15003_001
edu_spatial$prop_AA <- edu_spatial$estimate_B15003_021/edu_spatial$estimate_B15003_001
edu_spatial$prop_BS <- edu_spatial$estimate_B15003_022/edu_spatial$estimate_B15003_001
edu_spatial$prop_MD <- edu_spatial$estimate_B15003_023/edu_spatial$estimate_B15003_001
edu_spatial$prop_pro <- edu_spatial$estimate_B15003_024/edu_spatial$estimate_B15003_001
edu_spatial$prop_PhD <- edu_spatial$estimate_B15003_025/edu_spatial$estimate_B15003_001

edu_spatial$prop_somecollege <- edu_spatial$somecollege/edu_spatial$estimate_B15003_001
edu_spatial$prop_higher_ed <- edu_spatial$higher_ed/edu_spatial$estimate_B15003_001
edu_spatial$prop_post_grad <- edu_spatial$post_grad/edu_spatial$estimate_B15003_001

edu_spatial$prop_below_bach <- edu_spatial$below_bach/edu_spatial$estimate_B15003_001
edu_spatial$prop_above_bach <- edu_spatial$above_bach/edu_spatial$estimate_B15003_001

edu_spatial_cor <- edu_spatial%>%
  select(spatialmismatch,prop_somecollege,prop_higher_ed,prop_post_grad)

edu_spatial_2var <- edu_spatial%>%
  select(spatialmismatch,prop_below_bach,prop_above_bach)

#plotting all categories vs only upper
m.all <- lm(spatialmismatch~prop_noedu+prop_nodiploma+prop_hsdiploma+prop_GED+prop_lesssomecollege+prop_moresomecollege+prop_AA+prop_BS+prop_MD+prop_pro+prop_PhD, data = edu_spatial)
m.higher_edu <- lm(spatialmismatch~prop_BS+prop_MD+prop_pro+prop_PhD, data = edu_spatial)

summary(m.all)
summary(m.higher_edu)
anova(m.all, m.higher_edu)



# basic correlations
edu_correlation = cor(edu_spatial_cor[,(1:4)], use = "complete.obs")

#  Positive correlations are displayed in blue and negative correlations in red color. 
# Color intensity and the size of the circle are proportional to the correlation coefficients. 
# In the right side of the correlogram, the legend color shows the correlation 
# coefficients and the corresponding colors.
corrplot(edu_correlation, order = "hclust", 
         tl.col = "black", tl.srt = 45)

pairs(edu_spatial_cor[,(1:4)])

# modeling categorized education levels (COUNTS)
m.cat <- lm(spatialmismatch~somecollege + higher_ed + post_grad, data = edu_spatial)
m.propcat <- lm(spatialmismatch~prop_somecollege + prop_higher_ed + prop_post_grad, data = edu_spatial)
summary(m.propcat)
plot(spatialmismatch~prop_higher_ed, data = edu_spatial)

# modeling categorized education levels (PROP)
m.some_higher <- lm(spatialmismatch~prop_somecollege + prop_higher_ed + prop_somecollege*prop_higher_ed, data = edu_spatial)
m.some <- lm(spatialmismatch~prop_somecollege, data = edu_spatial)
m.higher <- lm(spatialmismatch~prop_higher_ed, data = edu_spatial)
m.post <- lm(spatialmismatch~prop_post_grad, data = edu_spatial)
summary(m.some_higher)
summary(m.some)
summary(m.higher)
summary(m.post)
m.prop <- lm(spatialmismatch~prop_somecollege + prop_higher_ed + prop_post_grad, data = edu_spatial)
summary(m.prop)

plot(m.prop)

#spatial and props only
#sometimes have to run this twice
edu_select <- edu_spatial %>%
  select(7,25:40)

# model with all predictors
m.all <- lm(spatialmismatch~prop_noedu+prop_nodiploma+prop_hsdiploma+prop_GED+prop_lesssomecollege+
              prop_moresomecollege+prop_AA+prop_BS+prop_MD+prop_pro+prop_PhD + prop_somecollege + prop_higher_ed
            + prop_post_grad + prop_below_bach + prop_above_bach, data = edu_select)


# backwards selection model, r^2 = 0.1531
MSE=(summary(m.all)$sigma)^2
step(m.all, scale=MSE, direction="backward")

m.back <- lm(formula = spatialmismatch ~ prop_GED + prop_lesssomecollege + 
               prop_moresomecollege + prop_BS + prop_MD + prop_pro + prop_PhD, 
             data = edu_select)
summary(m.back)

plot(m.back$resid~m.back$fitted)
abline(0,0)
plot(m.back)

#omit na's so that foward selection can occur
#may need to run this twice if selection does not work
edu_select <- na.omit(edu_select)

# forward selection model, r^2 = 0.1535 and smaller AIC
m.none <- lm(spatialmismatch~1, data = edu_select)
step(m.none, scope=list(upper=m.all), scale=MSE, direction="forward")

m.forward <- lm(formula = spatialmismatch ~ prop_above_bach + prop_PhD + prop_pro + 
                  prop_lesssomecollege + prop_AA + prop_noedu + prop_hsdiploma, 
                data = edu_select)

summary(m.forward)

# stepwise regression model
step(m.all, scope=list(upper=m.all), scale=MSE, direction="both")
m.stepwise <- lm(formula = spatialmismatch ~ prop_GED + prop_lesssomecollege + 
                   prop_moresomecollege + prop_BS + prop_MD + prop_pro + prop_PhD, 
                 data = edu_select)
summary(m.stepwise)

anova(m.stepwise, m.forward)

# Best subsets model
all <- regsubsets(spatialmismatch~prop_noedu+prop_nodiploma+prop_hsdiploma+prop_GED+prop_lesssomecollege+
                    prop_moresomecollege+prop_AA+prop_BS+prop_MD+prop_pro+prop_PhD + prop_somecollege + prop_higher_ed
                  + prop_post_grad + prop_below_bach + prop_above_bach, data = edu_select)
round(summary(all)$adjr2, 3)
plot(all, scale="adjr2")

# Lowest Cp model
round(summary(all)$cp,2)
plot(all, scale="Cp")

best_indiv_edu <- lm(formula = spatialmismatch ~ prop_BS + prop_MD + prop_pro + prop_PhD, 
                 data = edu_spatial)
summary(best_indiv_edu)

plot(best_indiv_edu)

# adding in interaction variable

m.edu_final <- lm(formula = spatialmismatch ~ prop_above_bach + prop_PhD + prop_above_bach * 
                    prop_below_bach, data = edu_select)
summary(m.edu_final)
