# AUTHORS.R
#
# This script exports a table of paper-author correspondences.
#
# Ben Davies
# January 2020

# Load packages
library(dplyr)
library(readr)
library(rvest)

# Import data
html_files <- dir('data-raw/pages', pattern = '*.html', full.names = T)
html_data <- lapply(html_files, read_html)

# Extract and combine author data
authors_list <- vector('list', length(html_files))
for (i in seq_along(html_files)) {
  authors_list[[i]] <- tibble(
    number = gsub('^data-raw/pages/(.*)[.]html$', '\\1', html_files[i]),
    uri = html_attr(html_nodes(html_data[[i]], '.h-right p a'), 'href')
  )
}
authors <- authors_list %>%
  bind_rows() %>%
  mutate(author = gsub('/about-us/people/(.*)/', '\\1', uri)) %>%
  select(number, author) %>%
  arrange(number, author) %>%
  filter(!is.na(author))

# Export data
write_csv(authors, 'data-raw/authors.csv')
save(authors, file = 'data/authors.rda', version = 2)

# Save session info
options(width = 80)
write_lines(capture.output(sessioninfo::session_info()), 'data-raw/authors.log')
