# PAGES.R
#
# This script scrapes data from Motu working papers' webpages. These data are
# used by papers.R and authors.R.
#
# Ben Davies
# December 2020

# Load packages
library(dplyr)
library(rvest)
library(readr)

# Set output directory
outdir <- 'data-raw/pages/'

# Get working paper list HTML
list_url <- 'https://motu.nz/resources/working-papers/'
list_html <- read_html(list_url)

# Create index of working paper numbers and page URIs
index <- html_nodes(list_html, '.content__abstract-content p') %>%
  lapply(function(node) {
    tibble(
      uri = html_attr(html_node(node, 'a'), 'href'),
      number = gsub('^([0-9]+).?([0-9]+).*?$', '\\1-\\2', html_text(node)),
    ) %>%
      mutate(number = case_when(grepl('relatedness-complexity', uri) ~ '19-01',
                                grepl('pacific-migrants', uri) ~ '19-02',
                                TRUE ~ number))
  }) %>%
  bind_rows() %>%
  filter(grepl('our-expertise', uri)) %>%
  arrange(number) %>%
  select(number, uri)

# Save index
write_csv(index, paste0(outdir, 'index.csv'))

# Download HTML for uncached pages
needed <- filter(index, !paste0(number, '.html') %in% dir(outdir))
for (i in seq_len(nrow(needed))) {
  
  # Extract HTML nodes of interest
  page_html <- read_html(paste0('https://motu.nz', needed$uri[i]))
  title_html <- html_node(page_html, 'h1')
  info_html <- html_node(page_html, '.item__infos')
  
  # Combine, tidy and export HTML nodes
  out <- paste(as.character(title_html), as.character(info_html), sep = '\n')
  out <- gsub('\\\t', '', out)
  out <- gsub('(\\\n)+', '\n', out)
  write_lines(out, paste0(outdir, needed$number[i], '.html'))
  
  # Pause
  Sys.sleep(5)
}

# Save session info
options(width = 80)
write_lines(capture.output(sessioninfo::session_info()), 'data-raw/pages.log')
