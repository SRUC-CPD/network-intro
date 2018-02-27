
library(tidyverse)
library(igraph)

if (.Platform$OS.type == "windows") {
    # For Josh and I
    df <- read_csv('data/dummy_data.csv')
}

options(warn = -1) # turns off warnings
# clean data using dplyr,tidyr
df_clean <- df %>%
    select(Name, SkillsR:SkillsD3, OfficeLocation) %>%
    mutate_at(vars(-Name,-OfficeLocation), funs(
        fct_recode(
            # fct_recode is from forcats package
            .,
            '0' = 'I don\'t use it',
            '1' = 'beginner',
            '2' = 'intermediate',
            '3' = 'expert'
        )
    )) %>%
    gather(skill, level,-Name,-OfficeLocation) %>%
    mutate(skill = str_remove_all(skill, 'Skills'),
           level = as.numeric(level))

options(warn = 0) # turns warnings back on

df_clean <- df_clean %>%
    unite(location.skill, OfficeLocation, skill, sep = '_')

# Create the graph
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

#####################################
# Remove expert ties to one another #
#####################################

experts <- df_clean %>%
    separate(
        col = location.skill,
        into = c('OfficeLocation', 'skill'),
        sep = '_'
    ) %>%
    group_by(skill) %>%
    filter(level == max(level)) %>%
    arrange(Name, skill, level) %>%
    group_by(Name) %>%
    mutate(newvary = lead(skill)) %>%
    filter(is.na(newvary)) %>%
    select(-newvary)

# make into a list
ls_expert <- experts %>%
    split(.$OfficeLocation)

# get all possible combinations and coerce to
# a vector suitable for deleting edges
expert.edges <- map(ls_expert, function(x) {
    pull(x, Name) %>%
        combn(., 2) %>%
        t(.) %>%
        dplyr::as_data_frame(.) %>%
        unite(experts, V1, V2, sep = '|') %>%
        pull(experts)
    
})

delete.ed <- flatten_chr(expert.edges)

# delete these edges from the graph

g_people_strengths <- delete.edges(g_people_strengths, delete.ed)

## Create attributes

alpha <- data_frame(Name = V(g_people_strengths)$name)

g_people_stengths_att <- left_join(alpha, df_att_strengths)

# add colors and join within the same data_frame
g_people_stengths_att <- g_people_stengths_att %>%
    count(skill) %>%
    mutate(color = brewer.pal(nrow(.), 'YlGnBu')) %>%
    select(-n) %>%
    right_join(., g_people_stengths_att) %>%
    select(Name, skill, level, color)

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

## coordinates using tkplot
## ~ allows you to specify the
## ~ coordinate system interatively
## ~ and save for future use

# j <- tkplot(g_people_strengths) # this opens the plotter, turn it off '#' after
# the first creation
coords <- tkplot.getcoords(j) # gets the coordinates and stores them

# ~~ I've saved these coordinates as 'coords.RData'
# save(coords,file = '~/coords.RData')

load('~/coords.RData')
l <- coords

## The actual plot call

plot(g_people_strengths, layout = l)

# Every plot needs a legend
#
legend.labels <- unique(g_people_stengths_att$skill)
legend.colors <- unique(g_people_stengths_att$color)
legend(
    'topleft',
    legend = legend.labels,
    col = legend.colors,
    pch = 16,
    bty = 'n'
)
#











