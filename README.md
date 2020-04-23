
# Managing data better with pins

Relates to our [discussion on managing and using
data](https://github.com/2DegreesInvesting/ds-incubator/issues/35), and
extends a previous [introduction to the pins
package](https://github.com/2DegreesInvesting/ds-incubator/issues/38).

Here I show how pins meets these requirements:

  - [x] Plays well with R.
  - [x] Is low cost or better free.
  - [x] Data hosted online can also be accessed from a local cache.
  - [x] Allows us to control permissions to read and write data.
  - [x] Supports version control with Git and GitHub.
  - [x] Can handle datasets of the maximum size we need.

tl;dr:

  - The pins package meets all requirements with some caveats.
  - `pin()`: Pin remote resources locally, work offline and cache
    results.
  - `pin_find()`: Discover new resources across different boards.
  - `board_register()`: Share resources in local folders, GitHub, Azure,
    and more.
  - Learn more at <https://pins.rstudio.com/>.

### Plays well with R

It is an [R
package](https://cloud.r-project.org/web/packages/pins/index.html), and
well integrated with RStudio.

``` r
# install.packages("pins")
library(pins)
```

Here I also use a few other packages for convenience.

``` r
library(glue)
library(readr)
library(fs)
library(dplyr, warn.conflicts = FALSE)
```

### Is low cost or better free

As any other R package, pins is free, but [can be used with paid
services,
e.g. Azure](https://pins.rstudio.com/articles/boards-azure.html).

### Data hosted online can also be accessed from a local cache

Consider a dataset stored online:

  - [Nice
    view](https://github.com/tidyverse/readr/blob/master/inst/extdata/mtcars.csv).
  - [Raw
    view](https://raw.githubusercontent.com/tidyverse/readr/master/inst/extdata/mtcars.csv)

You don’t need pins to download or read this file. You may do it with
`download.file()` and `read.csv()` (I prefer `readr::read_csv()`). But
every time the process may potentially take a long time.

``` r
raw_url <- 
  "https://raw.githubusercontent.com/tidyverse/readr/master/inst/extdata/mtcars.csv"

# First time
system.time(read_csv(raw_url))
#>    user  system elapsed 
#>   0.116   0.032   0.287

# Second time
system.time(read_csv(raw_url))
#>    user  system elapsed 
#>   0.020   0.003   0.152
```

A better way is to `pin()` the URL.

``` r
# First time
system.time(read_csv(pin(raw_url)))
#>    user  system elapsed 
#>   0.038   0.004   0.099

# Second time
system.time(read_csv(pin(raw_url)))
#>    user  system elapsed 
#>   0.006   0.004   0.010
```

The first time pins creates a cache in a local “board” and reuses it the
second time – which runs faster.

``` r
pins::board_default()
#> [1] "local"

fs::dir_tree(
  pins::board_cache_path()
)
#> /home/mauro/.cache/pins
#> └── local
#>     ├── data.txt
#>     ├── data.txt.lock
#>     ├── mtcars
#>     │   ├── data.txt
#>     │   └── mtcars.csv
#>     └── my_data
#>         ├── data.csv
#>         ├── data.rds
#>         └── data.txt
```

The default location for the local-board cache is convenient and
sensible, but you may want to instead use another location.

``` r
my_cache <- fs::path(tempdir(), "pins_cache")
board_register_local(
  name = "my_local_board", 
  cache = my_cache, 
  versions = TRUE
)
fs::dir_tree(my_cache)
#> /tmp/Rtmp1qb3b4/pins_cache
```

`versions = TRUE` enables [pins
versions](https://pins.rstudio.com/articles/advanced-versions.html).

``` r
read_csv(pin(raw_url)) %>% 
  pin(name = "my_data", board = "my_local_board")

pin_get("my_data", board = "my_local_board") %>% 
  filter(cyl > 6) %>% 
  pin(name = "my_data", board = "my_local_board") %>%  
  # Cache new version
  select(mpg, gear) %>% 
  # Cache new version
  pin(name = "my_data", board = "my_local_board") 

history <- pins::pin_versions("my_data", board = "my_local_board")
history
#> # A tibble: 3 x 1
#>   version
#>   <chr>  
#> 1 c4ebac4
#> 2 473809d
#> 3 87c8327

latest <- history$version[1]
dim(pin_get("my_data", board = "my_local_board", version = latest))
#> [1] 14  2

older <- history$version[2]
dim(pin_get("my_data", board = "my_local_board", version = older))
#> [1] 14 11
```

In case you are curious, this is the structure of pins versions.

``` r
fs::dir_tree(my_cache)
#> /tmp/Rtmp1qb3b4/pins_cache
#> └── my_local_board
#>     ├── data.txt
#>     ├── data.txt.lock
#>     └── my_data
#>         ├── _versions
#>         │   ├── 473809d4678e82db4ecc9a2a6b72f04f69d35d83
#>         │   │   ├── data.csv
#>         │   │   ├── data.rds
#>         │   │   └── data.txt
#>         │   ├── 87c8327fdadbef640066aded629edda046483bc9
#>         │   │   ├── data.csv
#>         │   │   ├── data.rds
#>         │   │   └── data.txt
#>         │   └── c4ebac4df0413fad973f3c39a04390801946b259
#>         │       ├── data.csv
#>         │       ├── data.rds
#>         │       └── data.txt
#>         ├── data.csv
#>         ├── data.rds
#>         └── data.txt
```

### Supports version control with Git

For more control, initialize a Git repository in your pins cache.

``` /bin/bash
git init /tmp/Rtmpdrvnwb/pins_cache
```

On the terminal I can now change directory to my pins\_cache, add all
changes, commit, and inspect the log:

``` /bin/bash
cd /tmp/Rtmpdrvnwb/pins_cache
git add .
git commit -m "Start tracking my cache with Git"
```

### Allows us to control permissions to read and write data

It is not pins job to control who reads or writes data but it plays well
with tools like Azure and GitHub that provide granular [access
permissions](https://help.github.com/en/github/getting-started-with-github/access-permissions-on-github).

### Can handle datasets of the maximum size we need

Pins has no limit but some boards do.
[Azure](https://pins.rstudio.com/articles/boards-azure.html) is
apparently limitless but charges for what it hosts. On
[GitHub](https://pins.rstudio.com/articles/boards-github.html) pins can
host files up to 2GB in both public and private repos.

–

Cleanup.

``` /bin/bash
trash /tmp/Rtmpdrvnwb/pins_cache
```
