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
library(tidyr)

# Import data
html_files <- dir('data-raw/pages', pattern = '*.html', full.names = T)
html_data <- lapply(html_files, read_html)

# Define function for replacing non-ASCII characters with ASCII equivalents
replace_non_ascii <- function(x) {
  subfun <- function(x, pattern, y) gsub(pattern, y, x, perl = T)
  x %>%
    iconv('', 'ASCII', sub = 'byte') %>%
    subfun('<c3><83><c2><89>', 'E') %>%
    subfun('<c3><83><c2><96>', 'O') %>%
    subfun('<c3><83><c2><a1>', 'a') %>%
    subfun('<c3><83><c2><a9>', 'e') %>%
    subfun('<c3><83><c2><ab>', 'e') %>%
    subfun('<c3><83><c2><b8>', 'o')
}

# Extract, combine and clean author data
authors_list <- vector('list', length(html_files))
for (i in seq_along(html_files)) {
  authors_list[[i]] <- tibble(
    number = gsub('^data-raw/pages/(.*)[.]html$', '\\1', html_files[i]),
    text = html_text(html_node(html_data[[i]], 'p:last-of-type'))
  )
}
authors <- authors_list %>%
  bind_rows() %>%
  mutate(text = strsplit(text, '\n')) %>%
  unnest(text) %>%
  filter(text != '' & !grepl('^Author', text)) %>%
  mutate(text = gsub(',\\s+$', '', text),
         text = trimws(text),
         text = replace_non_ascii(text)) %>%
  distinct(number, author = text) %>%
  bind_rows(
    tribble(
      ~number, ~author,
      '03-01', 'Suzi Kerr',
      '03-11', 'Ralph Lattimore',
      '13-15', 'Lynda Sanderson',
      '14-16', 'Richard Fabling',
      '14-16', 'Lynda Sanderson'
    )
  ) %>%
  arrange(number, author) %>%
  filter(!is.na(author))

# Export data
write_csv(authors, 'data-raw/authors.csv')
save(authors, file = 'data/authors.rda', version = 2)

# Save session info
options(width = 80)
write_lines(capture.output(sessioninfo::session_info()), 'data-raw/authors.log')
