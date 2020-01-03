# AREAS.R
#
# This script exports a table of research area names and colours.
#
# Ben Davies
# January 2020

# Load packages
library(dplyr)
library(readr)

# Define data
areas <- tribble(
  ~area, ~area_name, ~area_colour,
  'environment-and-resources', 'Environment and Resources', '#86d19d',
  'human-rights', 'Human Rights', '#8f736e',
  'population-and-labour', 'Population and Labour', '#f7b36f',
  'productivity-and-innovation', 'Productivity and Innovation', '#48bfba',
  'urban-and-regional', 'Urban and Regional', '#cf5f65',
  'wellbeing-and-macroeconomics', 'Wellbeing and Macroeconomics', '#a56bcb'
)

# Export data
write_csv(areas, 'data-raw/areas.csv')
save(areas, file = 'data/areas.rda', version = 2)

# Save session info
options(width = 80)
write_lines(capture.output(sessioninfo::session_info()), 'data-raw/areas.log')
