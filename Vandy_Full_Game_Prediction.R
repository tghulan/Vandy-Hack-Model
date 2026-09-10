predict_full_game <- function(home_team, away_team, home_sp, away_sp, home_elo, away_elo,
                              conference_game = 1, neutral_site = 0) {
  
  margin_input <- tibble(
    home_team = home_team, away_team = away_team,
    rating_diff = home_sp - away_sp, elo_diff = home_elo - away_elo,
    returning_diff = 0, conference_game = conference_game, neutral_site = neutral_site
  )
  totals_input <- tibble(
    home_team = home_team, away_team = away_team,
    rating_sum = home_sp + away_sp, elo_sum = home_elo + away_elo,
    conference_game = conference_game, neutral_site = neutral_site
  )
  
  margin_pred <- predict(bayes_model, newdata = margin_input, allow_new_levels = TRUE, summary = TRUE)
  total_pred  <- predict(totals_model, newdata = totals_input, allow_new_levels = TRUE, summary = TRUE)
  
  margin_est   <- margin_pred[, "Estimate"]
  margin_lower <- margin_pred[, "Q2.5"]
  margin_upper <- margin_pred[, "Q97.5"]
  
  total_est   <- total_pred[, "Estimate"]
  total_lower <- total_pred[, "Q2.5"]
  total_upper <- total_pred[, "Q97.5"]
  
  win_prob <- pnorm(margin_est / resid_sd)
  
  tibble(
    matchup       = paste(away_team, "@", home_team),
    home_score    = round((total_est + margin_est) / 2),
    away_score    = round((total_est - margin_est) / 2),
    margin        = round(margin_est, 1),
    margin_lower  = round(margin_lower, 1),
    margin_upper  = round(margin_upper, 1),
    total         = round(total_est, 1),
    total_lower   = round(total_lower, 1),
    total_upper   = round(total_upper, 1),
    win_prob      = round(win_prob, 3)
  )
}