# PAPERS.R
#
# This script exports a table of working paper attributes.
#
# Ben Davies
# December 2020

# Load packages
library(dplyr)
library(readr)
library(rvest)
library(tidyr)

# Import page index and HTML data
index <- read_csv('data-raw/pages/index.csv')
html_files <- dir('data-raw/pages', pattern = '*.html', full.names = T)
html_data <- lapply(html_files, read_html, encoding = 'UTF-8')

# Import RDF data
rdf_files <- dir('data-raw/repec', pattern = '*.rdf', full.names = T)
rdf_data <- lapply(rdf_files, read_lines)

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

# Define function for replacing non-ASCII characters with ASCII equivalents
replace_non_ascii <- function(x) {
  subfun <- function(x, pattern, y) gsub(pattern, y, x, perl = T)
  x %>%
    iconv('', 'ASCII', sub = 'byte') %>%
    subfun('<fc><be><8c><86><84><bc>', ' ') %>%
    subfun('<fc><be><8c><86><94><bc>', 'a') %>%
    subfun('<fc><be><8c><93><a4><bc>', '\'') %>%
    subfun('<fc><be><8c><96><94><bc>', 'a') %>%
    subfun('<fc><be><8c><a3><a4><bc>', '\'') %>%
    subfun('<fc><be><8c><b3><a4><bc>', '\"') %>%
    subfun('<fc><be><8d><83><a4><bc>', '\"') %>%
    subfun('<fc><be><8d><a3><a4><bc>', '--') %>%
    subfun('<fc><be><8e><96><94><bc>', 'e') %>%
    subfun('<c4><81>', 'a') %>%
    subfun('<e2><80><93>', '--') %>%
    subfun('<e2><80><98>|<e2><80><99>', '\'') %>%
    subfun('<e2><80><9c>|<e2><80><9d>', '\"') %>%
    subfun('<fc><be><8d><b3><a4><bc>', '---')
}

# Extract abstracts
abstracts <- rdf_data %>%
  lapply(function(x) tibble(line = seq_along(x), text = x)) %>%
  bind_rows() %>%
  mutate(number = gsub('^data-raw/repec/(.*)[.]rdf$', '\\1', rdf_files[cumsum(line == 1)]),
         has_key = grepl(':', text),
         is_abstract = ifelse(!has_key, NA, grepl('Abstract:', text))) %>%
  group_by(number) %>%
  fill(is_abstract) %>%
  filter(is_abstract) %>%
  summarise(abstract = paste(text, collapse = '\n')) %>%
  ungroup() %>%
  mutate(abstract = gsub('^Abstract:', '', abstract),
         abstract = replace_non_ascii(abstract),
         abstract = trimws(gsub('\\s+', ' ', abstract)),
         abstract = ifelse(abstract == '', NA, abstract))

# Combine data and manually add missing papers
papers <- tibble(
  number = gsub('^data-raw/pages/(.*)[.]html$', '\\1', html_files),
  title = sapply(html_data, function(x) html_text(html_node(x, 'h1')))
) %>%
  mutate(title = replace_non_ascii(title)) %>%
  left_join(index) %>%
  mutate(area = gsub('^/our-expertise/(.*?)/(.*)$', '\\1', uri)) %>%
  bind_rows(
    tribble(
      ~number, ~title, ~area,
      '03-01', 'Allocating Risks in a Domestic Greenhouse Gas Trading System', 'environment-and-resources',
      '03-11', 'Long Run Trends in New Zealand Industry Assistance', 'population-and-labour',
      '13-15', 'Sources of international investment data in the Longitudinal Business Database', 'wellbeing-and-macroeconomics',
      '14-16', 'Productivity distributions in New Zealand: The dangers of international comparison', 'productivity-and-innovation'
    )
  ) %>%
  left_join(abstracts) %>%
  left_join(areas) %>%
  select(number, title, abstract, area = area_name, colour = area_colour) %>%
  arrange(number)

# Export data
write_csv(papers, 'data-raw/papers.csv')
save(papers, file = 'data/papers.rda', version = 2)

# Save session info
options(width = 80)
write_lines(capture.output(sessioninfo::session_info()), 'data-raw/papers.log')
