# motuwp

This package contains information about [Motu working papers](https://motu.nz/resources/working-papers/) published between 2003 and 2020.
The package provides two data frames:

* `papers`: working paper attributes.
* `authors`: paper-author correspondences.

I build these data frames by running `data-raw/pages.R`, `data-raw/repec.R`, `data-raw/papers.R` and `data-raw/authors.R` (in that order), each in a fresh instance of `motuwp.Rproj`.

## Installation

motuwp can be installed via [remotes](https://github.com/r-lib/remotes):

```r
library(remotes)
install_github('bldavies/motuwp')
```

## License

CC0
