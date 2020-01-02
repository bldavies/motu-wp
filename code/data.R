# DATA.R
#
# This script scrapes the Motu website for a list of working papers, and
# exports data on those papers' authors and titles.
#
# Ben Davies
# July 2019

# Load packages
library(dplyr)
library(httr)
library(readr)
library(rvest)
library(tidyr)

# Get working paper IDs and URIs
dir_html <- read_html('https://motu.nz/resources/working-papers/')
papers <- tibble(node = html_nodes(dir_html, '.content__abstract-content p')) %>%
  mutate(paper = gsub('^([0-9]+).?([0-9]+).*?$', '\\1-\\2', html_text(node)),
         uri = html_attr(html_node(node, 'a'), 'href')) %>%
  mutate(paper = case_when(grepl('relatedness-complexity', uri) ~ '19-01',
                           grepl('pacific-migrants', uri) ~ '19-02',
                           TRUE ~ paper)) %>%
  filter(grepl('our-work', uri)) %>%
  arrange(paper)

# Load cache
cache_path <- 'data/_cache.rds'
cache <- if (file.exists(cache_path)) readRDS(cache_path) else NULL

# Get working paper authors and titles
authors_list <- list()
titles_list <- list()
for (i in 1 : nrow(papers)) {
  if (!(papers$paper[i] %in% cache$paper)) {
    paper_html <- read_html(paste0('https://motu.nz', papers$uri[i]))
    authors_list[[i]] <- tibble(
      paper = papers$paper[i],
      uri = html_attr(html_nodes(paper_html, '.h-right p a'), 'href')
    )
    titles_list[[i]] <- tibble(
      paper = papers$paper[i],
      title = html_text(html_node(paper_html, 'h1'))
    )
    Sys.sleep(3)
  }
  if (i %% 5 == 0) cat('Querying paper', i, 'of', nrow(papers), '\n')
}

# Update cache
if (length(titles_list) * length(authors_list) > 0) {
 cache <- bind_rows(titles_list) %>%
    left_join(bind_rows(authors_list)) %>%
    rbind(cache)
  saveRDS(cache, 'data/_cache.rds')
}

# Process authors and papers
authors <- cache %>%
  mutate(author = gsub('/about-us/people/(.*)/', '\\1', uri)) %>%
  select(paper, author) %>%
  arrange(paper, author) %>%
  filter(!is.na(author))
papers <- cache %>%
  distinct(paper, title) %>%
  full_join(papers) %>%
  mutate(area = gsub('^/our-work/(.*?)/(.*)$', '\\1', uri)) %>%
  select(paper, title, area) %>%
  arrange(paper)

# Export data
write_csv(authors, 'data/authors.csv')
write_csv(papers, 'data/papers.csv')

# Save session info
write_lines(capture.output(sessioninfo::session_info()), "logs/data.log")
