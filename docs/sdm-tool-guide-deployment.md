# SDM Model Evaluation Tool User Guide for Administrators

> How to deploy the tool

## Deployment options

The SDM Model Evaluation Tool can be deployed in several ways, depending
on your needs and resources. Here are some common options:

1.  **shinyapps.io**: A cloud-based hosting service for Shiny
    applications. This is the easiest option for deployment, as it
    requires no server setup. You can deploy your app directly from R
    using the `rsconnect` package.
2.  More options to be added here later.

## Deployment on shinyapps.io

> Note that Posit will be migrating all shinyapps.io users to Connect
> Cloud at the end of 2026, read more about the migration
> [here](https://forum.posit.co/t/important-update-shinyapps-io-is-moving-to-connect-cloud/209804).

Prerequisites:

- An account on [shinyapps.io](https://www.shinyapps.io/)
- The `rsconnect` package installed in R. You can install it using the
  command `install.packages("rsconnect")`

### Step 1: Create the app folder

Create a folder for the app, e.g. `app`.

### Step 2: Add deployment materials

Move the deployment materials into the `app/sdm_evaluation_results`
folder.

### Step 3: Add the app code and users

Make sure that the sdmEvalToolCore and sdmEvalToolUI packages are
installed via remotes or pak (and not installed locally using
`devtools::install()` or similar, because otherwise rsconnect will not
be able to find the packages when deploying the app).

``` r
# using remotes for the latest version of the main branch
remotes::install_github(
  "LandSciTech/sdmEvaluationTool/sdmEvalToolCore"
)
remotes::install_github(
  "LandSciTech/sdmEvaluationTool/sdmEvalToolUI"
)

# using pak for a specific version/branch
pak::pak("dhope/sdmEvaluationTool/sdmEvalToolCore@dh-dev")
pak::pak("dhope/sdmEvaluationTool/sdmEvalToolUI@dh-dev")
```

Create a file inside the `app` folder named `app/app.R` and copy the
contents of the SDM Model Evaluation Tool into this file:

``` r
library(sdmEvalToolCore)
library(sdmEvalToolUI)

con <- withr::local_db_connection(sdmEvalToolUI::db_connect_check())
users <- sdmEvalToolCore::db_read_table(con, "users")
users$user <- users$user_id
users$password <- "pass1234"

sdm_tool(user_db = users)
```

The authentication functionality of the SDM Model Evaluation Tool relies
on the shinymanager package. Install the shinymanager package with
`install.packages("shinymanager")`. For now, we hard coded the passwords
in the app code.

You can add username/password combinations to the `users` data frame as
needed, but make sure to keep the `user` and `password` columns. Use a
csv file or similar to store the credentials if you have many users, and
read it in with `read.csv()` or similar.

### Step 4: Deploy the app

Deploy the app using the rsconnect package.

``` r
account = "analythium" # use your account here

# only needed the first time to link R to your shinyapps.io account
rsconnect::setAccountInfo(
  name = account,
  token = "xxxxxx",
  secret = "xxxxxx")

rsconnect::deployApp("app", 
  appName = "sdm-tool-test",
  appTitle = "SDM Tool Test",
  account = account,
  forceUpdate = TRUE)
```

This will deploy the app to shinyapps.io under your account.

You can access the test application at
<https://analythium.shinyapps.io/sdm-tool-test/>. Use the
username/password combination testuser/pass1234.
