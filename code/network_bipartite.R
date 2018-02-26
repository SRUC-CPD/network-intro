# ---------------------------
# ---------------------------
# Visualising complexity attendees
# Bipartite explorer
# ---------------------------
# ---------------------------

library(tidyverse)
library(RColorBrewer)
library(igraph)

df = read_csv("~/repo/network-intro/data/dummy_data.csv")

pal = brewer.pal(5, "Dark2")

# spurious comment


# ---------------------------
# Make 2 vertice type graph

df_edges = df %>% 
   select(Name, SkillsR, SkillsPython, SkillsExcel, SkillsSQL, SkillsSpatial, SkillsD3) %>% 
   setNames(c("Name", "R", "Python", "Excel", "SQL", "Spatial", "D3")) %>% 
   gather(skill, level, -Name) %>% 
   mutate(level=factor(level, levels=c("I don't use it", "beginner", "intermediate", "expert")),
          width=2 * as.numeric(level) - 2,
          color=rgb(55/255, 58/255, 58/255, as.numeric(level) / 10)) %>% 
   filter(level!="I don't use it")

y = df %>% 
   select(Name, SkillsR, SkillsPython, SkillsExcel, SkillsSQL, SkillsSpatial, SkillsD3) %>% 
   setNames(c("Name", "R", "Python", "Excel", "SQL", "Spatial", "D3")) %>% 
   gather(skill, level, -Name) %>% 
   filter(level=="expert" | level=="intermediate") %>% 
   count(skill) %>% 
   setNames(c("name", "size")) %>% 
   mutate(size=2 + 12 * size/max(size))

x = data.frame(name=unique(df_edges$skill), color=sefari[3],
               label.cex=0.9)
x = left_join(x, y)
y = data.frame(name=unique(df_edges$Name), color=sefari[4], size=5,
               label.cex=0.7)

df_graph = graph.data.frame(df_edges[, c("Name", "skill", "width", "color")],
                            vertices=rbind(x, y),
                            directed=F)

make_bipartite_graph(types=c(rep("software", times=6), rep("person", times=42)),
                     edge=E(df_graph))

# ---------------------------
# Plot graph

par(mar=c(0.5, 0.5, 0.5, 0.5), cex=1.5)
plot(df_graph,
     asp=0.8,
     vertex.label.color="black",
     edge.curved=.1)
par(mar=c(5, 4, 4, 2) + 0.1)
