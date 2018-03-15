# --------------------------------
# --------------------------------
# Anonymise delegates
# --------------------------------
# --------------------------------

library(tidyverse)

df = read_csv("http://bit.ly/SRUC-delegates")

df$`Your name` = paste("Person", 1:nrow(df))

df = df %>% 
   select(-`Email address`)

write_csv(df, "~/repo/network-intro/data/SNA_anon_delegates.csv")
