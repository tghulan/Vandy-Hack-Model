## ============================================================
## Vanderbilt Football Prediction Model — Starter Script
## ============================================================
## Two parallel models on the same data:
##   1. Hierarchical Bayesian regression (brms)      -> calibrated margin + win prob
##   2. Gradient boosted trees (XGBoost)              -> non-linear interactions
##
## Data source: cfbfastR / collegefootballdata.com API (free key required)
## Get a key at: https://collegefootballdata.com/key
## ============================================================

## ---- 0. Packages ----
packages <- c("cfbfastR", "tidyverse", "brms", "xgboost", "Metrics")
installed <- rownames(installed.packages())
for (p in packages) if (!(p %in% installed)) install.packages(p)

library(cfbfastR)
library(tidyverse)
library(brms)
library(xgboost)
library(Metrics)

Sys.setenv(CFBD_API_KEY = "pXbncH+WkMnH9px/GlKNGAil4dVndZgWItFDIStoX8fVGGJwBXo+oTA7oy+bYpnF")

## ---- 1. Pull data across multiple seasons ----
## Use several years so the model has enough games to learn from.
## Keep 2024 out of training — it's your holdout/test season.
seasons_train <- 2019:2023
seasons_test  <- 2024

pull_season <- function(yr) {
  games <- cfbd_game_info(year = yr, season_type = "regular") %>%
    filter(!is.na(home_points), !is.na(away_points))
  
  sp <- cfbd_ratings_sp(year = yr) %>%
    select(team, rating) %>%
    rename(sp_rating = rating)
  
  elo <- tryCatch(
    cfbd_ratings_elo(year = yr) %>%
      select(team, elo) %>%
      rename(elo_rating = elo),
    error = function(e) tibble(team = character(), elo_rating = numeric())
  )
  
  returning <- tryCatch(
    cfbd_player_returning(year = yr) %>%
      select(team, total_ppa) %>%
      rename(returning_ppa = total_ppa),
    error = function(e) tibble(team = character(), returning_ppa = numeric())
  )
  
  weather <- tryCatch(
    cfbd_game_weather(year = yr) %>%
      select(game_id, temperature, wind_speed),
    error = function(e) tibble(game_id = numeric(), temperature = numeric(), wind_speed = numeric())
  )
  
  games %>%
    left_join(sp, by = c("home_team" = "team")) %>%
    rename(home_sp = sp_rating) %>%
    left_join(sp, by = c("away_team" = "team")) %>%
    rename(away_sp = sp_rating) %>%
    left_join(elo, by = c("home_team" = "team")) %>%
    rename(home_elo = elo_rating) %>%
    left_join(elo, by = c("away_team" = "team")) %>%
    rename(away_elo = elo_rating) %>%
    left_join(returning, by = c("home_team" = "team")) %>%
    rename(home_returning = returning_ppa) %>%
    left_join(returning, by = c("away_team" = "team")) %>%
    rename(away_returning = returning_ppa) %>%
    left_join(weather, by = "game_id") %>%
    mutate(season = yr)
}

raw_train <- map_dfr(seasons_train, pull_season)
raw_test  <- map_dfr(seasons_test,  pull_season)

## ---- 2. Feature engineering ----
## Build one row per game from the HOME team's perspective.
## margin > 0 means the home team won by that many points.
pull_season <- function(yr) {
  games <- cfbd_game_info(year = yr, season_type = "regular") %>%
    filter(!is.na(home_points), !is.na(away_points))
  
  sp <- cfbd_ratings_sp(year = yr) %>%
    select(team, rating) %>%
    rename(sp_rating = rating)
  
  elo <- tryCatch(
    cfbd_ratings_elo(year = yr) %>%
      select(team, elo) %>%
      rename(elo_rating = elo),
    error = function(e) tibble(team = character(), elo_rating = numeric())
  )
  
  returning <- tryCatch(
    cfbd_player_returning(year = yr) %>%
      select(team, total_ppa) %>%
      rename(returning_ppa = total_ppa),
    error = function(e) tibble(team = character(), returning_ppa = numeric())
  )
  
  advanced <- tryCatch({
    Sys.sleep(2)
    cfbd_stats_season_advanced(year = yr) %>%
      select(team, off_success_rate, def_success_rate)
  }, error = function(e) {
    message("Advanced stats failed for ", yr, ", retrying once...")
    Sys.sleep(5)
    tryCatch(
      cfbd_stats_season_advanced(year = yr) %>%
        select(team, off_success_rate, def_success_rate),
      error = function(e2) tibble(team = character(), off_success_rate = numeric(),
                                  def_success_rate = numeric())
    )
  })
  
  games %>%
    left_join(sp, by = c("home_team" = "team")) %>%
    rename(home_sp = sp_rating) %>%
    left_join(sp, by = c("away_team" = "team")) %>%
    rename(away_sp = sp_rating) %>%
    left_join(elo, by = c("home_team" = "team")) %>%
    rename(home_elo = elo_rating) %>%
    left_join(elo, by = c("away_team" = "team")) %>%
    rename(away_elo = elo_rating) %>%
    left_join(returning, by = c("home_team" = "team")) %>%
    rename(home_returning = returning_ppa) %>%
    left_join(returning, by = c("away_team" = "team")) %>%
    rename(away_returning = returning_ppa) %>%
    left_join(advanced, by = c("home_team" = "team")) %>%
    rename(home_off_sr = off_success_rate, home_def_sr = def_success_rate) %>%
    left_join(advanced, by = c("away_team" = "team")) %>%
    rename(away_off_sr = off_success_rate, away_def_sr = def_success_rate) %>%
    mutate(season = yr)
}

## ============================================================
## Next steps to extend this:
##   - Add down/distance splits, havoc rate, weather via cfbd_pbp_data()
##     and cfbd_game_weather()
##   - Swap season-level SP+ for week-by-week if you pull FPI instead
##   - Re-run predict_game() for each Vandy 2026 opponent
## ============================================================
