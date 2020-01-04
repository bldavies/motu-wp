# REPEC.R
#
# This script downloads RDF files from Motu's RePEc index.
#
# Ben Davies
# January 2020

# Load packages
library(dplyr)
library(rvest)

# Set output directory
outdir <- 'data-raw/repec/'

# Get RePEc index HTML
index_url <- 'http://motu-www.motu.org.nz/RePEc/mtu/wpaper/'
index_html <- read_html(index_url)

# Create index of RDF file names and URLs
index <- tibble(node = html_nodes(index_html, 'a')) %>%
  mutate(file = html_text(node)) %>%
  filter(grepl('[.]rdf', file)) %>%
  mutate(url = paste0(index_url, file))

# Download uncached RDF files
needed <- filter(index, !file %in% dir(outdir))
for (i in seq_len(nrow(needed))) {
  download.file(needed$url[i], paste0(outdir, needed$file[i]))
  Sys.sleep(5)
}

# Save session info
options(width = 80)
writeLines(capture.output(sessioninfo::session_info()), 'data-raw/repec.log')
