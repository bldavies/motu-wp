library(dplyr)
library(ggplot2)
library(igraph)
library(readr)
library(stringr)
library(tidyr)

fields <- read_csv("data/fields.csv")
linked_authors <- read_csv("data/linked-authors.csv")
urls <- read_csv("data/urls.csv")

source("https://raw.githubusercontent.com/bldavies/pokenet/master/code/jaccard.R")


## THE AUTHORSHIP NETWORK

data <- linked_authors %>%
  left_join(urls) %>%
  mutate(paper_id = paste0(year - 2000, "-", number),
         field_id = sub("/our-work/(.*?)/.*", "\\1", url)) %>%
  select(year, paper_id, field_id, author_id)

authors <- data %>%
  group_by(author_id) %>%
  summarise(num_papers = n_distinct(paper_id)) %>%
  ungroup()

papers <- data %>%
  group_by(paper_id, field_id) %>%
  summarise(num_authors = n_distinct(author_id)) %>%
  ungroup() %>%
  left_join(fields) %>%
  select(paper_id, field_id, field_colour, num_authors)

incidence <- table(data$author_id, data$paper_id)

bip <- graph.incidence(incidence)

dim(incidence)

data %>%
  group_by(field_id) %>%
  summarise(num_papers = n_distinct(paper_id)) %>%
  ungroup() %>%
  left_join(fields) %>%
  ggplot(aes(reorder(str_wrap(field_name, width = 15), -num_papers),
             num_papers)) +
  geom_bar(aes(fill = field_colour), stat = "identity") +
  labs(y = "Number of working papers") +
  scale_fill_identity() +
  theme_light() +
  theme(axis.title.x = element_blank())
ggsave("figures/field-counts.svg", width = 8, height = 4)

E(bip)$color <- "gray80"
V(bip)$color[V(bip)$type == FALSE] <- "gray60"
V(bip)$color[V(bip)$type == FALSE][authors$num_papers >= 30] <- "gray35"  # Hubs
V(bip)$color[V(bip)$type == TRUE] <- as.character(papers$field_colour)
V(bip)$frame.color <- V(bip)$color
V(bip)$label <- NA
V(bip)$shape <- c("circle", "square")[V(bip)$type + 1]
V(bip)$size <- 3
authors$radius <- 1 + 5 * sqrt(authors$num_papers / max(authors$num_papers))
V(bip)$size[V(bip)$type == FALSE] <- authors$radius

svg("figures/author-network.svg", width = 6, height = 6)
par(mar = rep(0, 4))
set.seed(0)
bip_layout <- layout_with_fr(bip)
plot(bip, layout = bip_layout)
dev.off()


## THE COAUTHORSHIP NETWORK

net <- bipartite.projection(bip)[[1]]

V(net)$size <- V(net)$size ^ 1.33

svg("figures/coauthor-network.svg", width = 4, height = 4)
par(mar = rep(0, 4))
set.seed(0)
net_layout <- jaccard(incidence %*% t(incidence)) %>%
  graph.adjacency(mode = "undirected", weighted = TRUE) %>%
  simplify() %>%
  layout_with_fr()
plot(net, layout = net_layout)
dev.off()

gorder(net)
gsize(net)
graph.density(net)
max(components(net)$csize)

authors <- authors %>%
  mutate(num_coauthors = degree(net))
ego(net, 1, V(net)[which(authors$num_coauthors >= 20)]) %>%
  unlist() %>%
  unique() %>%
  length()  # Order of hub neighbourhoods' union

common_neighbour_rate <- function (G) {
  B <- distances(G, weights = rep(1, gsize(G))) == 2
  num_pairs <- choose(gorder(G), 2)
  rate <- (sum(B) / 2) / num_pairs
  return (rate)
}

clust <- clusters(net)
lcc_vertices <- V(net)[which(clust$membership == which.max(clust$csize))]
lcc <- induced.subgraph(net, lcc_vertices)
common_neighbour_rate(lcc)

mean_distance(net, directed = FALSE)
diameter(net, directed = FALSE, weights = rep(1, gsize(net)))


### TESTING FOR SMALL-WORLDNESS

small_world_baselines <- function (G, sample_size = 1000, seed = 0) {
  set.seed(seed)
  transitivity_samples <- rep(0, sample_size)
  mean_distance_samples <- rep(0, sample_size)
  for (i in 1 : sample_size) {
    er <- sample_gnm(gorder(G), gsize(G))
    transitivity_samples[i] <- transitivity(er)
    mean_distance_samples[i] <- mean_distance(er, directed = FALSE)
  }
  return (list(transitivity = mean(transitivity_samples),
               mean_distance = mean(mean_distance_samples)))
}

(C <- transitivity(net, weights = rep(1, gsize(net))))
(L <- mean_distance(net, directed = FALSE))

(baselines <- small_world_baselines(net))

(C / baselines$transitivity) / (L / baselines$mean_distance)  # S-W coefficient


## SUBSAMPLING BY FIELD

fields <- fields %>%
  left_join(data) %>%
  group_by(field_name, field_id) %>%
  summarise(num_papers = n_distinct(paper_id),
            num_authors = n_distinct(author_id)) %>%
  ungroup() %>%
  filter(num_authors > 1)

for (i in 1 : nrow(fields)) {
  field_data <- data %>%
    filter(field_id == fields$field_id[i])
  field_incidence <- table(field_data$author_id, field_data$paper_id)
  field_net <- field_incidence %*% t(field_incidence) %>%
    graph.adjacency(mode = "undirected") %>%
    simplify()  #  Remove loops and parallel edges
  
  fields$density[i] <- graph.density(field_net)
  fields$lcc_order[i] <- max(components(field_net)$csize)
  fields$lcc_diameter[i] <- diameter(field_net, directed = FALSE)
  
  field_baselines <- small_world_baselines(field_net)
  fields$transitivity[i] <- transitivity(field_net)
  fields$transitivity_baseline[i] <- field_baselines$transitivity
  fields$mean_distance[i] <- mean_distance(field_net, directed = FALSE)
  fields$mean_distance_baseline[i] <- field_baselines$mean_distance
}

fields %>%
  arrange(-num_papers) %>%
  select(field_name, num_papers, num_authors, density, starts_with("lcc")) %>%
  mutate(density = round(density, digits = 2)) 

fields %>%
  arrange(-num_papers) %>%
  select(field_name, starts_with("transitivity"), starts_with("mean_dist")) %>%
  mutate(transitivity_ratio = transitivity / transitivity_baseline,
         mean_distance_ratio = mean_distance / mean_distance_baseline,
         coeff = transitivity_ratio / mean_distance_ratio) %>%
  select(-ends_with("ratio")) %>%
  mutate_if(is.numeric, funs(round(., 2)))
