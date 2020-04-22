# tl;dr -------------------------------------------------------------------

# * pin(): Pin remote resources locally, work offline and cache results.
# * pin_find(): Discover new resources across different boards.
# * board_register(): Share resources in local folders, GitHub, Azure, and more.
# * Learn more at https://pins.rstudio.com/

# Setup -------------------------------------------------------------------

# install.packages("pins")
# Or
# remotes::install_github("rstudio/pins")
library(pins)
packageVersion("pins")

# For convenience
library(glue)
library(readr)
library(dplyr)
library(fs)

# Pin a URL: Avoid re-downloading data and save time ----------------------

owner_repo <- "tidyverse/readr"
dataset <- "master/inst/extdata/mtcars.csv"

normal_url <- glue("https://github.com/{owner_repo}/blob/{dataset}")
if (interactive()) browseURL(normal_url)

# Raw view
raw_url <- glue("https://raw.githubusercontent.com/{owner_repo}/{dataset}")

# You can use the resource from its online source and download it every time
# * Both calls should take about the same time
system.time(read_csv(raw_url))
system.time(read_csv(raw_url))

# Or you can pin the url and store the data in a local cache
# * The second call should be faster
system.time(read_csv(pin(raw_url)))
system.time(read_csv(pin(raw_url)))

# Cache structure
fs::dir_tree(pins::board_cache_path())

# Pin a data frame or other R object: Save computation time ---------------

# Compute a thing
colMeans(datasets::airquality, na.rm = TRUE) %>% 
  pin(name = "expensive_result")

# Use a thing elsewhere
pins::pin_get("expensive_result")

# Works after you restart R
callr::r(function()  # This is to run in a separate R session
  pins::pin_get("expensive_result")
)

# Your thing is now stored in pins's cache
fs::dir_tree(pins::board_cache_path())

# Pin resources from GitHub -----------------------------------------------

# You can store and pin datasets on public and private GitHub repos

# 1. Create an empty GitHub repo 
# I did it from the terminal with:
#   gh repo create maurolepore/demo-pin1
#   gh repo create maurolepore/demo-pin2 --public
browseURL("https://github.com/maurolepore/demo-pin1")
browseURL("https://github.com/maurolepore/demo-pin2")

# 2. Register "github" and the specific "owner/repo"
pins::board_list()
pins::board_register("github", repo = "maurolepore/demo-pin1")
pins::board_register("github", repo = "maurolepore/demo-pin2")
pins::board_list()

datasets::BOD %>% 
  pins::pin(
    name = "my_bod", 
    description = "My copy of `datasets::BOD`",
    board = "github", 
    repo = "maurolepore/demo-pin1"
)

datasets::iris %>% 
  pins::pin(
    name = "my_iris", 
    description = "My copy of `datasets::iris`.",
    board = "github", 
    repo = "maurolepore/demo-pin2"
  )

pins::pin_find("datasets", board = "github")

# If the resource is gone, you can still get it from your cache
fs::dir_tree(pins::board_cache_path())

read_rds(
  fs::path_home(".cache", "pins", "github", "my_bod", "data.rds")
)

# Cleanup -----------------------------------------------------------------

fs::dir_tree(pins::board_cache_path())

pins::pin_remove("expensive_result", board = "local")
pins::pin_remove("mtcars", board = "local")

fs::dir_tree(pins::board_cache_path())

# You can remove pins from GitHub, but they stay in locall cache
pins::pin_remove("my_iris", board = "github")
pins::pin_remove("my_bod", board = "github")
browseURL("https://github.com/maurolepore/demo-pin1")
browseURL("https://github.com/maurolepore/demo-pin2")
fs::dir_tree(pins::board_cache_path())

pins::board_list()
pins::board_deregister("github")
pins::board_list()








# Leftovers ---------------------------------------------------------------


fs::dir_tree(pins::board_cache_path())

library(pins)
pins::pin_get("expensive-result")
pins::pin_get("expensive_result")
# pins::pin_remove("mtcars", board = "local")
fs::dir_tree(pins::board_cache_path())

# How it works ------------------------------------------------------------



pins::board_default()
pins_cache <- pins::board_cache_path()


pins::board_register("github", repo = "maurolepore/demo-pins2")
pins::board_register("packages")
pins::board_register("github", repo = "maurolepore/demo-pins2")
pins::board_deregister("github", repo = "maurolepore/demo-pins2")
pins::board_deregister("packages")
pins::board_list()
pins::board_register("github", repo = "maurolepore/demo-pins3")
pins::pin_remove("diamonds", board = "github")
pins::pin_remove("wines", board = "local")

pins::

head(diam2)

# But pin() creates a local cache; it's  faster and allows you to work offline
retail_sales <- read_csv(pin(url))
head(retail_sales)

pin_info("retail_sales")



# Pin locally to reuse data easily ----------------------------------------

retail_sales %>%
  group_by(month = lubridate::month(ds, T)) %>%
  summarise(total = sum(y)) %>%
  pin("sales_by_month")

pin_info("sales_by_month")
pin_get("sales_by_month")



# Discover pins: In packages ----------------------------------------------

pin_find("flights", board = "packages")

# I don't have this package installed
try(packageVersion("hflights"))

# Yet I can get data from this package
x <- pin_get("hflights/hflights", board = "packages")

pin_info("hflights")



# GitHub ------------------------------------------------------------------

# 1. Create a repo on GitHub

# 2. Register it
board_register_github(repo = "maurolepore/demo-pins3", token = usethis::github_token())

# Start using pins
pin(airquality, description = "The airquality dataset", board = "github")

library(pins)
board_register_github(repo = "maurolepore/demo-pins3", token = usethis::github_token())
pin_get("airquality", board = "github")
