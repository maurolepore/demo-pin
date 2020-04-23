
# Managing data better with pins

Relates to our [discussion on managing and using
data](https://github.com/2DegreesInvesting/ds-incubator/issues/35), and
extends a previous [introduction to the pins
package](https://github.com/2DegreesInvesting/ds-incubator/issues/38).

Here I show how pins meets these requirements:

  - [x] Plays well with R.
  - [x] Is low cost or better free.
  - [x] Data hosted online can also be accessed from a local cache.
  - [x] Supports version control with Git.
  - [x] Plays well with GitHub.
  - [x] Plays well with Azure.
  - [x] Allows us to control permissions to read and write data.
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
url <- "https://raw.githubusercontent.com/tidyverse/readr/master/inst/extdata/mtcars.csv"
url %>% read_csv()
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

A better way is to `pin()` the URL, which creates a cache in a local
“board” that you can later use.

``` r
url %>% pin("my_data")

# Works from any R session
my_data <- pin_get("my_data") %>% read_csv()
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

> `pin()` still works when working offline or when the remote resource
> becomes unavailable; when this happens, a warning will be triggered
> but your code will continue to work.

The default location for the local-board cache is convenient and
sensible.

``` r
board_default()
#> [1] "local"

dir_tree(board_cache_path())
#> /home/mauro/.cache/pins
#> ├── azure
#> │   ├── data.txt
#> │   ├── data.txt.lock
#> │   └── iris
#> │       ├── data.rds
#> │       └── data.txt
#> └── local
#>     ├── data.txt
#>     ├── data.txt.lock
#>     ├── mtcars
#>     │   ├── data.txt
#>     │   └── mtcars.csv
#>     └── my_data
#>         ├── data.txt
#>         └── mtcars.csv
```

But you may want to instead use another location, and enable [pins
versions](https://pins.rstudio.com/articles/advanced-versions.html).

``` r
my_cache <- path(tempdir(), "pins_cache")

board_register_local(
  name = "my_local_board", 
  cache = my_cache, 
  versions = TRUE
)

my_data %>% 
  filter(cyl > 6) %>% 
  # Cache new version
  pin(name = "my_data", board = "my_local_board") %>%  
  select(mpg, gear) %>% 
  # Cache new version
  pin(name = "my_data", board = "my_local_board") 

history <- pin_versions("my_data", board = "my_local_board")
history
#> # A tibble: 2 x 1
#>   version
#>   <chr>  
#> 1 c4ebac4
#> 2 53d5e44

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
#> /tmp/RtmpDffCsC/pins_cache
#> └── my_local_board
#>     ├── data.txt
#>     ├── data.txt.lock
#>     └── my_data
#>         ├── _versions
#>         │   ├── 53d5e443f9427929c8d518a9dcbc235c931dbc79
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

``` r
# Set environmental variable so I can use it from the terminal
Sys.setenv(MY_CACHE = my_cache)
Sys.getenv("MY_CACHE")
#> [1] "/tmp/RtmpDffCsC/pins_cache"
```

From the terminal:

``` /bin/bash
git init $MY_CACHE
cd $MY_CACHE
git add .
git commit -m "Start tracking my cache with Git"
```

### Plays well with GitHub

GitHub is a tool we already use a lot and pins plays well with it.

If you track your cache with Git, you can now push it to GitHub. But
GitHub repos can better serve you as a pins board. This works both for
public and private repos.

For example:

``` r
board_register_github(
  name = "my_github_board",
  repo = "maurolepore/demo-board",
  cache = my_cache,
  versions = TRUE
)

my_data %>% 
  pin(
    name = "my_data",
    board = "my_github_board",
    description = "Some data",
    repo = "maurolepore/demo-board"
  )

pin_find("my_data", board = "my_github_board")
#> # A tibble: 1 x 4
#>   name    description type  board          
#>   <chr>   <chr>       <chr> <chr>          
#> 1 my_data Some data   table my_github_board

pin_get("my_data", board = "my_github_board")
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

Worst case scenario you can always get data directly from your local
cache.

``` r
dir_tree(my_cache)
#> /tmp/RtmpDffCsC/pins_cache
#> ├── my_github_board
#> │   ├── data.txt
#> │   ├── data.txt.lock
#> │   └── my_data
#> │       ├── data.rds
#> │       └── data.txt
#> └── my_local_board
#>     ├── data.txt
#>     ├── data.txt.lock
#>     └── my_data
#>         ├── _versions
#>         │   ├── 53d5e443f9427929c8d518a9dcbc235c931dbc79
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

path(my_cache, "my_github_board", "my_data", "data.rds") %>% read_rds()
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

### Plays well with Azure

Azure is important to us because the data managers use it. Data managers
may then simply manage access permissions so the right people can access
the data they need. Data users like analysts and software developers may
then get the access key from Azure, store it safely in their file
.Renviron (see
[`usethis::edit_r_environ()`](https://usethis.r-lib.org/reference/edit.html)),
and read and write data with `pins()`. This way we can use the same
familiar `pins()` interface across boards (local, GitHub, Azure, and
more) instead of learning a specialized interface (e.g. the
[AzureStor](https://cran.r-project.org/web/packages/AzureStor/)
package).

Learn more about [Using Azure
boards](https://pins.rstudio.com/articles/boards-azure.html).

`board_register_azure()` requires a number of arguments, including
secrets, that are best passed as environmental variables – that is,
stored them as key-value pairs in you .Renviron.

``` r
# usethis::edit_r_environ()
AZURE_STORAGE_CONTAINER="test-container"
AZURE_STORAGE_ACCOUNT="2diiteststorage"
# Not my real key
AZURE_STORAGE_KEY="ABCABCABCABCABCABCABCABCABCAB=="
```

That setups simplifies how you register an Azure board.

``` r
board_register_azure()
```

You can now pin resources to the Azure board.

``` r
datasets::iris %>% 
  pin(name = "iris", board = "azure", description = "My iris data")
#> No encoding supplied: defaulting to UTF-8.

datasets::mtcars %>% 
  pin(name = "mtcars", board = "azure", description = "My mtcars data")
#> No encoding supplied: defaulting to UTF-8.
```

And you can also find and get resources from the Azure board.

``` r
pin_find("data", board = "azure")
#> # A tibble: 2 x 4
#>   name   description    type  board
#>   <chr>  <chr>          <chr> <chr>
#> 1 iris   My iris data   table azure
#> 2 mtcars My mtcars data table azure

pin_get("mtcars", board = "azure")
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

And you can also remove resources.

``` r
pin_remove(name = "mtcars", board = "azure")
#> No encoding supplied: defaulting to UTF-8.
#> No encoding supplied: defaulting to UTF-8.

pin_find("data", board = "azure")
#> No encoding supplied: defaulting to UTF-8.
#> # A tibble: 1 x 4
#>   name  description  type  board
#>   <chr> <chr>        <chr> <chr>
#> 1 iris  My iris data table azure
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
trash $MY_CACHE
```
