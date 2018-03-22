# --------------------------------
# --------------------------------
# Anonymise delegates
# --------------------------------
# --------------------------------

library(tidyverse)

df = read_csv("~/Downloads/Network analysis external delegates (Responses) - Form responses 1.csv")

df$`Your name` = paste("Person", 1:nrow(df))

df = df %>% 
   select(-`Do you have any extra access or dietary requirements?`)

write_csv(df, "~/repo/network-intro/data/SNA_anon_delegates.csv")
