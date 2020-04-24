Pin volatile raw data to a board you control
================

``` r
library(magrittr)
library(pins)
```

Here is some data I (pretend) don’t control:

``` r
source_url <- 
  "https://raw.githubusercontent.com/maurolepore/demo-data/master/some_data.csv"

read.csv(source_url)
#>   x  y
#> 1 1  a
#> 2 2  b
```

That raw data may become unavailable anytime, so I’ll pin it to a board
I do control, for example, a github board.

First I create a GitHub repo, for example, at
<https://github.com/maurolepore/demo-gh-board>. Then I register that
repo as a pins board.

``` r
# The default cache is okay, but I include it here just because I can
path_pins_cache <- fs::path(here::here(), "pins_cache")

pins::board_register_github(
  name = "demo-gh-board",
  repo = "maurolepore/demo-gh-board",
  # You should add GITHUB_PAT to .Renviron; see ?usethis::github_token()
  token = usethis::github_token(),  
  cache = path_pins_cache
)
```

I pin to my github board the URL pointing to the volatile source data.

``` r
some_data <- source_url %>% 
  pins::pin(
    name = "some_data",
    description = "Some raw data",
    board = "demo-gh-board"
  )
```

Although I didn’t explicitly read the data, pins stored it in its cache.

``` r
fs::dir_tree(path_pins_cache)
#> /home/mauro/git/demo-pins/pins_cache
#> └── demo-gh-board
#>     ├── data.txt
#>     ├── data.txt.lock
#>     ├── processed_data
#>     │   ├── data.rds
#>     │   └── data.txt
#>     └── some_data
#>         ├── data.txt
#>         └── some_data.csv
```

> `pin()` allows you to cache remote resources and intermediate results
> with ease. When caching remote resources, usually URLs, it will check
> for HTTP caching headers to avoid re-downloading when the remote
> result has not changed.

– `?pins::pin()`

I can later find `some_data` in multiple ways:

  - With pins:

<!-- end list -->

``` r
pin_find("some", board = "demo-gh-board")
#> # A tibble: 1 x 4
#>   name      description   type  board        
#>   <chr>     <chr>         <chr> <chr>        
#> 1 some_data Some raw data files demo-gh-board
```

  - With the RStudio addin *Find Pins*:

<img src=http://i.imgur.com/v1nSe43.png width=600 />

  - From the tab *Connections*:

<img src=http://i.imgur.com/2KU3b7a.png width=600 />

And I can use the pin anywhere, anytime.

``` r
some_data <- pins::pin_get("some_data", board = "demo-gh-board") %>% 
  read.csv()

some_data
#>   x  y
#> 1 1  a
#> 2 2  b
```

I should also pin downstream datasets that may be slow to recompute.

``` r
some_data %>% 
  transform(new_column = paste(x, y)) %>% 
  pin(
    name = "processed_data", 
    description = "Something expensive to recreate",
    board = "demo-gh-board"
  )
```

What happens if the source data becomes unavailable, because the source
data is deleted, you are offline, or whatever?

**HERE I TURN OFF MY CONNECTION TO INTERNET**

  - Reading directly from the source fails:

<!-- end list -->

``` r
source_url %>% 
  read.csv()
#> Error in file(file, "rt") : 
#>   cannot open the connection to 'https://raw.githubusercontent.com/maurolepore/demo-data/master/some_data.csv'
#> In addition: Warning message:
#> In file(file, "rt") :
#>   URL 'https://raw.githubusercontent.com/maurolepore/demo-data/master/some_data.c#> sv': status was 'Couldn't resolve host name'
```

  - But I can still get the `some_data` via pin:

<!-- end list -->

``` r
pins::pin_get(name = "some_data", board = "demo-gh-board") %>% 
  read.csv()
#>   x  y
#> 1 1  a
#> 2 2  b
```

The documentation says that “`pin()` still works when working offline or
when the remote resource becomes unavailable; when this happens, a
warning will be triggered but your code will continue to work”. I failed
to confirm this behavior, but it relatively simple to first try reading
from the source and on error retry reading from pins cache:

``` r
tryCatch(
  read.csv(source_url), 
  error = function(e) {
    read.csv(pins::pin_get(name = "some_data", board = "demo-gh-board"))
  }
)
#>   x  y
#> 1 1  a
#> 2 2  b
```

Whatever happens with the source data, I’m safe because I have two
backups:

  - My local cache, which I can track with Git for extra safety.

<!-- end list -->

``` r
fs::dir_tree(path_pins_cache)
#> /home/mauro/git/demo-pins/pins_cache
#> └── demo-gh-board
#>     ├── data.txt
#>     ├── data.txt.lock
#>     ├── processed_data
#>     │   ├── data.rds
#>     │   └── data.txt
#>     └── some_data
#>         ├── data.txt
#>         └── some_data.csv
```

  - And the GitHub board at
    <https://github.com/maurolepore/demo-gh-board>, which is a normal
    GitHub repo so I can also check previous versions with Git.
