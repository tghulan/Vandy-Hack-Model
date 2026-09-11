# Vandy Hack Model

A predictive model for Vanderbilt football game outcomes, combining Elo ratings and SP+ ratings as inputs to a Bayesian regression model and an XGBoost model.

## Overview

This project estimates point margins and win probabilities for Vanderbilt football games using a blend of two approaches:

- **Bayesian regression (`brms`)**: models the relationship between rating differentials (SP+, Elo) and game margin, producing a point estimate along with an uncertainty interval.
- **XGBoost**: a gradient-boosted tree model trained on the same features, used to compare against the Bayesian estimate and highlight where the two approaches agree or diverge.

## Files

- `Vandy_Full_Game_Prediction.R` — full prediction pipeline: builds feature inputs (rating differentials, conference game flag, neutral site flag), generates margin and win probability estimates from the Bayesian model, and produces total point estimates.
- `Vandy_Model.R` — core model-building script: fits the Bayesian and XGBoost models on historical data.

## Inputs

- SP+ ratings (home/away)
- Elo ratings (home/away)
- Conference game flag
- Neutral site flag
- Returning production differential

## Output

For each matchup, the model produces:
- Estimated point margin (with 95% credible interval)
- Estimated total points
- Win probability

## Status

In development. Current focus is refining feature importance comparisons between the Bayesian and XGBoost approaches, and validating margin predictions against actual game results.

## Initial requirements

This program uses data from CollegeFootballData.com. API keys are free and available via https://collegefootballdata.com/key.

After receiving an API key, perform these steps to secure it on your machine and make it available to the API queries:

- Make sure the `usethis` library is installed (`install.packages('usethis')`)
- In the R console, enter `usethis::edit_r_environ()`
- Add this line (replace the holder text with your API key): `Sys.setenv(CFBD_API_KEY = "YOUR_KEY_HERE")`
- Save the file and close it. 
- Do a full restart/termination of the R session.