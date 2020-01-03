# PAPERS.R
#
# This script exports a table of working paper numbers, titles, and areas.
#
# Ben Davies
# January 2020

# Load packages
library(dplyr)
library(readr)
library(rvest)
library(xml2)

# Import data
index <- read_csv('data-raw/pages/index.csv')
html_files <- dir('data-raw/pages', pattern = '*.html', full.names = T)
html_data <- lapply(html_files, read_html, encoding = 'UTF-8')

# Combine data
papers <- tibble(
  paper = gsub('^data-raw/pages/(.*)[.]html$', '\\1', html_files),
  title = sapply(html_data, function(x) html_text(html_node(x, 'h1')))
) %>%
  left_join(index) %>%
  mutate(area = gsub('^/our-work/(.*?)/(.*)$', '\\1', uri)) %>%
  select(paper, title, area)

# Export data
write_csv(papers, 'data-raw/papers.csv')
save(papers, file = 'data/papers.rda', version = 2)

# Save session info
options(width = 80)
write_lines(capture.output(sessioninfo::session_info()), 'data-raw/papers.log')
