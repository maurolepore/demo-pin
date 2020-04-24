Pin volatile raw data to a board you control
================

``` r
library(dplyr, warn.conflicts = FALSE)
library(pins)
```

Here is some data I don’t control:

``` r
raw_url <- 
  "https://raw.githubusercontent.com/maurolepore/demo-data/master/some_data.csv"

read.csv(raw_url)
#>   x  y
#> 1 1  a
#> 2 2  b
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
```

([View this repository on
GitHub](https://github.com/maurolepore/demo-gh-board))

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

<img src=http://i.imgur.com/v1nSe43.png width=600 />

  - From the tab *Connections*:

<img src=http://i.imgur.com/2KU3b7a.png width=600 />

And I can use the pin anywhere, anytime.

``` r
path_some_data <- pins::pin_get("some_data", board = "demo-gh-board")
some_data <- read.csv(path_some_data)
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

rm some_data.csv

git add some_data.csv
git commit -m "Destroy some_data.csv"
git push

ls some_data.csv
#> some_data.csv
#> [master 61ebbf0] Destroy some_data.csv
#>  1 file changed, 4 deletions(-)
#>  delete mode 100644 some_data.csv
#> To github.com:maurolepore/demo-data.git
#>    835e360..61ebbf0  master -> master
#> ls: cannot access 'some_data.csv': No such file or directory
```

Reading directly from the source will fail, but reading via pins still
works.

``` r
raw_url <- 
  "https://raw.githubusercontent.com/maurolepore/demo-data/master/some_data.csv"

# Fails
raw_url %>% 
  read.csv()
#>   x  y
#> 1 1  a
#> 2 2  b

# Works
raw_url %>% 
  pins::pin(
    name = "some_data",
    description = "Some raw data",
    board = "demo-gh-board"
  ) %>% 
  read.csv()
#>   x  y
#> 1 1  a
#> 2 2  b
```

No problem, I can still get it.

``` r
read.csv(pins::pin_get("some_data"))
#>   x  y
#> 1 1  a
#> 2 2  b
```

### Cleanup

``` bash
# bash terminal
cd ~/git/demo-data
ls

cd ~/git/demo-data
git revert HEAD -n
git commit -am "Recover some_data"
git push

ls some_data.csv
#> [master 998014d] Recover some_data
#>  1 file changed, 4 insertions(+)
#>  create mode 100644 some_data.csv
#> To github.com:maurolepore/demo-data.git
#>    61ebbf0..998014d  master -> master
#> some_data.csv
```

``` r
fs::dir_delete(path_pins_cache)
```
