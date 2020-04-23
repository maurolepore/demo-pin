
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
#>   0.083   0.013   0.163

# Second time
system.time(read_csv(raw_url))
#>    user  system elapsed 
#>   0.019   0.000   0.096
```

A better way is to `pin()` the URL.

``` r
# First time
system.time(read_csv(pin(raw_url)))
#>    user  system elapsed 
#>   0.028   0.004   0.088

# Second time
system.time(read_csv(pin(raw_url)))
#>    user  system elapsed 
#>   0.009   0.000   0.008
```

The first time pins creates a cache in a local “board” and reuses it the
second time – which runs faster.

``` r
board_default()
#> [1] "local"

dir_tree(board_cache_path())
#> /home/mauro/.cache/pins
#> └── local
#>     ├── data.txt
#>     ├── data.txt.lock
#>     ├── mtcars
#>     │   ├── data.txt
#>     │   └── mtcars.csv
#>     └── my_data
#>         └── mtcars.csv
```

The default location for the local-board cache is convenient and
sensible, but you may want to instead use another location.

``` r
my_cache <- path(tempdir(), "pins_cache")
board_register_local(
  name = "my_local_board", 
  cache = my_cache, 
  versions = TRUE
)
```

`versions = TRUE` enables [pins
versions](https://pins.rstudio.com/articles/advanced-versions.html).

You can pin a dataset at different after you read it, and get it from
your cache into any R session.

``` r
read_csv(raw_url) %>% 
  pin(name = "my_data", board = "my_local_board")

# Sometime, somewhere
my_data <- pin_get(name = "my_data", board = "my_local_board")
my_data
#> # A tibble: 32 x 11
#>      mpg   cyl  disp    hp  drat    wt  qsec    vs    am  gear  carb
#>    <dbl> <dbl> <dbl> <dbl> <dbl> <dbl> <dbl> <dbl> <dbl> <dbl> <dbl>
#>  1  21       6  160    110  3.9   2.62  16.5     0     1     4     4
#>  2  21       6  160    110  3.9   2.88  17.0     0     1     4     4
#>  3  22.8     4  108     93  3.85  2.32  18.6     1     1     4     1
#>  4  21.4     6  258    110  3.08  3.22  19.4     1     0     3     1
#>  5  18.7     8  360    175  3.15  3.44  17.0     0     0     3     2
#>  6  18.1     6  225    105  2.76  3.46  20.2     1     0     3     1
#>  7  14.3     8  360    245  3.21  3.57  15.8     0     0     3     4
#>  8  24.4     4  147.    62  3.69  3.19  20       1     0     4     2
#>  9  22.8     4  141.    95  3.92  3.15  22.9     1     0     4     2
#> 10  19.2     6  168.   123  3.92  3.44  18.3     1     0     4     4
#> # … with 22 more rows
```

And you can pin different versions, which might be difficult or slow to
re-compute.

``` r
my_data %>% 
  filter(cyl > 6) %>% 
  # Cache new version
  pin(name = "my_data", board = "my_local_board") %>%  
  select(mpg, gear) %>% 
  # Cache new version
  pin(name = "my_data", board = "my_local_board") 

history <- pin_versions("my_data", board = "my_local_board")
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
dir_tree(my_cache)
#> /tmp/RtmpxtEBJ5/pins_cache
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
