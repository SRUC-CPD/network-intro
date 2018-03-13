
# igraph and dplyr both have a 'as_data_frame' function,
# so it's best to call tidyverse after igraph
library(igraph)
library(tidyverse)


# Import & Clean ---------------------------------------------------


df <- read_csv('data/dummy_data.csv')


options(warn = -1) # turns off warnings
# clean data using dplyr,tidyr
df_clean <- df %>%
  select(Name, SkillsR:SkillsD3, OfficeLocation) %>%
  mutate_at(vars(-Name, -OfficeLocation), funs(
    fct_recode(
      # fct_recode is from forcats package
      .,
      '0' = 'I don\'t use it',
      '1' = 'beginner',
      '2' = 'intermediate',
      '3' = 'expert'
    )
  )) %>%
  gather(skill, level, -Name, -OfficeLocation) %>%
  mutate(skill = str_remove_all(skill, 'Skills'),
         level = as.numeric(level))

options(warn = 0) # turns warnings back on

df_clean <- df_clean %>%
  unite(location.skill, OfficeLocation, skill, sep = '_')


# Create Graph -----------------------------------------------------


# Graph straight from data.frame
g_df_att_strengths <- graph_from_data_frame(df_clean)

# Create bipartite projects

V(g_df_att_strengths)$type <-
  V(g_df_att_strengths)$name %in% df_clean$Name

g_df_clean_projs_strengths <-
  bipartite.projection(g_df_att_strengths)

# There are two bipartite graphs in g_df_clean_projs
# and we want to use the second one
# the first is the software ties

g_people_strengths <- g_df_clean_projs_strengths[[2]]


# Graph Attributes -------------------------------------------------


alpha <- data_frame(Name = V(g_people_strengths)$name)

df_clean_attr <- df_clean %>%
  separate(
    col = location.skill,
    into = c('OfficeLocation', 'skill'),
    sep = '_'
  ) %>%
  group_by(Name, OfficeLocation) %>%
  filter(level == max(level)) %>%
  arrange(Name, skill, level) %>%
  group_by(Name, OfficeLocation) %>%
  mutate(newvary = lead(skill)) %>%
  filter(is.na(newvary)) %>%
  select(-newvary)


g_people_stengths_att <- left_join(alpha, df_clean_attr)


# add colors and join within the same data_frame
g_people_stengths_att <- g_people_stengths_att %>%
  count(skill) %>%
  mutate(color = brewer.pal(nrow(.), 'YlGnBu')) %>%
  select(-n) %>%
  right_join(., g_people_stengths_att) %>%
  select(Name, skill, level, color)

 #Edge attributes
  # add colors and join within the same data_frame
 edge.col.a <-  data_frame(Name = as_edgelist(g_people_strengths)[,2]) %>% 
    distinct(.) %>% 
    left_join(.,select(g_people_stengths_att,Name,color)) 

edge.attr <- 
   left_join(data_frame(Name = as_edgelist(g_people_strengths)[,2]    ),edge.col.a)





# Remove Similar Skills --------------------------------------------
# This removes edges between people with the same skill level and software use.  No need to have these people share information if they are effectively the 'same.'

same.level <- df_clean_attr %>%
  unite(skill.level.location, 
        c(skill, level, OfficeLocation), sep = '_')

# make into a list
ls_same.level <- same.level %>%
  split(.$skill.level.location)

# get all possible combinations and coerce to
# a vector suitable for deleting edges

ls_same.level.over.1 <- ls_same.level[map(ls_same.level, nrow) > 1]

same.level.edges <- map(ls_same.level.over.1, function(x) {
  pull(x, Name) %>%
    combn(., 2) %>%
    t(.) %>%
    dplyr::as_data_frame(.) %>%
    unite(same.level, V1, V2, sep = '|') %>%
    pull(same.level)
  
})

# delete.ed <- c(flatten_chr(expert.edges),flatten_chr(same.level.edges))
delete.ed <- flatten_chr(same.level.edges)

# delete these edges from the graph

g_people_strengths <- delete.edges(g_people_strengths, delete.ed)





####################
# graph attributes #
# ##################

# ~ it's much easier to add the graph attributes
# ~ one at a time
#
V(g_people_strengths)$color <- g_people_stengths_att$color
V(g_people_strengths)$size <- g_people_stengths_att$level * 7
V(g_people_strengths)$shape <- 'circle'

#label attributes
V(g_people_strengths)$label <-
  g_people_stengths_att$Name %>% str_wrap(5)
V(g_people_strengths)$label.cex <- .5        #label size
V(g_people_strengths)$label.color <- 'black' #label color


E(g_people_strengths)$color <- edge.attr$color # edge color

## coordinates using tkplot
## ~ allows you to specify the
## ~ coordinate system interatively
## ~ and save for future use

# j <- tkplot(g_people_strengths) # this opens the plotter, turn it off '#' after
# the first creation
coords <- tkplot.getcoords(j) # gets the coordinates and stores them

# ~~ I've saved these coordinates as 'coords.RData'

load('data/coords.RData')
l <- coords

## The actual plot call
par(mar = c(1, 1, 1, 1),bg = 'black')
plot(g_people_strengths, layout = l)


# Every plot needs a legend

legend.labels <- unique(g_people_stengths_att$skill)
legend.colors <- unique(g_people_stengths_att$color)
legend(
  'topleft',
  legend = legend.labels,
  col = legend.colors,
  pch = 16,
  bty = 'n',text.col = 'white'
)
