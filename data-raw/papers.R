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

# Import page index and HTML data
index <- read_csv('data-raw/pages/index.csv')
html_files <- dir('data-raw/pages', pattern = '*.html', full.names = T)
html_data <- lapply(html_files, read_html, encoding = 'UTF-8')

# Define table of research area names and colours
areas <- tribble(
  ~area, ~area_name, ~area_colour,
  'environment-and-resources', 'Environment and Resources', '#86D19D',
  'human-rights', 'Human Rights', '#8F736E',
  'population-and-labour', 'Population and Labour', '#F7B36F',
  'productivity-and-innovation', 'Productivity and Innovation', '#48BFBA',
  'urban-and-regional', 'Urban and Regional', '#CF5F65',
  'wellbeing-and-macroeconomics', 'Wellbeing and Macroeconomics', '#A56BCB'
)

# Combine data
papers <- tibble(
  number = gsub('^data-raw/pages/(.*)[.]html$', '\\1', html_files),
  title = sapply(html_data, function(x) html_text(html_node(x, 'h1')))
) %>%
  left_join(index) %>%
  mutate(area = gsub('^/our-work/(.*?)/(.*)$', '\\1', uri)) %>%
  left_join(areas) %>%
  select(number, title, area = area_name, colour = area_colour)

# Export data
write_csv(papers, 'data-raw/papers.csv')
save(papers, file = 'data/papers.rda', version = 2)

# Save session info
options(width = 80)
write_lines(capture.output(sessioninfo::session_info()), 'data-raw/papers.log')
