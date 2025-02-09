library(tidycensus)
library(tidyverse)
library(readr)

## no need to run this file before creating visualizations

job_access_gap <- read_csv("./data/job_access_gap.csv")

sea_gap <- job_access_gap %>%
  filter(MSA == "Seattle")
#join table

#calculate how many are in 10% of data
quantity<-round(.1*dim(sea_gap)[1])

high<-sea_gap %>%
  arrange(desc(spatialmismatch))%>%
  head(quantity)

low<-sea_gap %>%
  arrange((spatialmismatch))%>%
  head(quantity)

#import big data CSV

acs_dataset <- read_csv("./data/acs_dataset.csv")
# View(acs_dataset)

#select the columns you want

acs_dataset$GEOID <- as.integer( acs_dataset$GEOID )
### joining is N O T working
high_with_acs <- left_join( high, acs_dataset, by="GEOID" )

anti_high_with_acs <- anti_join( high, acs_dataset, by="GEOID" )


