Using daily data I don’t control
================

``` r
library(pins)
library(tidyverse)
#> ── Attaching packages ───────────────────────────────────────────────── tidyverse 1.3.0 ──
#> ✓ ggplot2 3.3.0           ✓ purrr   0.3.4      
#> ✓ tibble  3.0.1           ✓ dplyr   0.8.99.9002
#> ✓ tidyr   1.0.2           ✓ stringr 1.4.0      
#> ✓ readr   1.3.1           ✓ forcats 0.5.0
#> ── Conflicts ──────────────────────────────────────────────────── tidyverse_conflicts() ──
#> x dplyr::filter() masks stats::filter()
#> x dplyr::lag()    masks stats::lag()
```

Here is some data I don’t control:

``` r
raw_url <- 
  "https://raw.githubusercontent.com/maurolepore/demo-data/master/some_data.csv"

read_csv(raw_url)
#> Parsed with column specification:
#> cols(
#>   x = col_double(),
#>   y = col_character()
#> )
#> # A tibble: 2 x 2
#>       x y    
#>   <dbl> <chr>
#> 1     1 a    
#> 2     2 b
```

It may become unavailable anytime, so I better pin it to a board I do
control.

> `pin()` still works when working offline or when the remote resource
> becomes unavailable; when this happens, a warning will be triggered
> but your code will continue to work.

– `?pins::pin()`

I’ll register a new GitHub board so I can use Git tools I already know.

1.  I’ll first create a GitHub repo. Do it however you like; I’ll use
    the terminal.

<!-- end list -->

``` bash
# bash
gh repo create --public maurolepore/demo-gh-board
gh repo view maurolepore/demo-gh-board
maurolepore/demo-gh-board
No description provided

No README provided

View this repository on GitHub: https://github.com/maurolepore/demo-gh-board
```

2.  I now register that repo as a new pins board.

<!-- end list -->

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

# I shave not created this directory yet
fs::dir_exists(path_pins_cache)
#> /home/mauro/git/demo-pins/pins_cache 
#>                                FALSE
```

I pin the URL to the raw data to my board on GitHub.

``` r
some_data <- raw_url %>% 
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

<img src=http://i.imgur.com/v1nSe43.png width=400 />

  - From the tab *Connections*:

<img src=http://i.imgur.com/2KU3b7a.png width=400 />

And I can use the pin anywhere, anytime.

``` r
path_some_data <- pins::pin_get("some_data", board = "demo-gh-board")
some_data <- read_csv(path_some_data)
#> Parsed with column specification:
#> cols(
#>   x = col_double(),
#>   y = col_character()
#> )
```

I would also compute downstream datasets that may be slow to recompute.

``` r
some_data %>% 
  mutate(new_column = paste(x, y)) %>% 
  pin(
    name = "processed_data", 
    description = "Something expensive to recreate",
    board = "demo-gh-board"
  )
```

What happens if the raw data becomes unavailable?

``` bash
# bash terminal
cd ~/git/demo-data
ls
#> some_data.csv
```

``` bash
# bash terminal
git rm some_data.csv
git add some_data.csv
git commit -m "Destroy some_data.csv"
git push
#> fatal: pathspec 'some_data.csv' did not match any files
#> fatal: pathspec 'some_data.csv' did not match any files
#> On branch master
#> Untracked files:
#>  pins_cache/
#>  use-some-data.Rmd
#>  use-some-data.md
#>  use-some-data_files/
#> 
#> nothing added to commit but untracked files present
#> To github.com:maurolepore/demo-pin.git
#>    688657d..1b69e2e  master -> master
```

``` bash
# bash terminal
ls
#> demo-pins.Rproj
#> pins_cache
#> pins.html
#> README.md
#> README.Rmd
#> use-some-data_files
#> use-some-data.md
#> use-some-data.Rmd
```

No problem, I can still get it.

``` r
read_csv(pins::pin_get("some_data"))
#> Parsed with column specification:
#> cols(
#>   x = col_double(),
#>   y = col_character()
#> )
#> # A tibble: 2 x 2
#>       x y    
#>   <dbl> <chr>
#> 1     1 a    
#> 2     2 b
```

### Cleanup

``` bash
# bash terminal
cd ~/git/demo-data
ls
#> some_data.csv
```

``` bash
# bash terminal
git revert HEAD -n
git commit -am "Recover some_data"
git push
#> [master ddd6273] Recover some_data
#>  2 files changed, 16 insertions(+), 44 deletions(-)
#> To github.com:maurolepore/demo-pin.git
#>    1b69e2e..ddd6273  master -> master
```

``` bash
# bash terminal
ls
#> demo-pins.Rproj
#> pins_cache
#> pins.html
#> README.md
#> README.Rmd
#> use-some-data_files
#> use-some-data.md
#> use-some-data.Rmd
```

``` r
fs::dir_delete(path_pins_cache)
```
