# Coauthorship Networks at Motu

This repository contains the code, data and figures for my blog post about the coauthorship networks among Motu researchers.

## Data

I scraped [Motu's working paper directory](https://motu.nz/resources/working-papers/) for a list of paper URLs and authors using the Python scripts in `code`.
The scripts' output are stored in `data`, along with metadata on Motu's six primary research fields.
I only include authors with outgoing hyperlinks from each paper's landing page in order to overcome identification and HTML parsing issues.
