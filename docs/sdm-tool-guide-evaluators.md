# SDM Model Evaluation Tool User Guide for Evaluators

> How to leave and edit evaluations

## Prerequisites

- [R](https://cran.r-project.org/)
- [Rtools](https://cran.r-project.org/bin/windows/Rtools/) on Windows
- [RStudio Desktop](https://posit.co/download/rstudio-desktop/) or a
  similar environment of you choosing

Before installation, first create a new RStudio Project where you’ll
store the data required for this tool. To do so, select *File* \> *New
Project*. When prompted, select *New Directory* and *New Project*. Under
the field *Directory name*, type in *sdmEvaluationTool*, then, click on
the *Browse* button and select a location you’ll remember (e.g.,
`c:/users/user_name/work`).

## Installation

Use this script in R to install required packages and download/extract
the example data set (say ‘yes’ or select the ‘All’ option to update
packages if asked):

``` r
source("https://raw.githubusercontent.com/LandSciTech/sdmEvaluationTool/refs/heads/main/setup.R")
```

## Adding the data set

Remove the `sdm_evaluation_results.zip` and the `sdm_evaluation_results`
folder with its contents. Then save and extract the archive containing
the real deployment sent to you via email or a shared drive link. Use a
system tool or the following command to extract the deployment
materials:

``` r
unzip("./sdm_evaluation_results.zip")
```

### Running the app locally

Start the app by running the following script in R (replace the
`"testuser"` with your user name):

``` r
# load libraries
library(sdmEvalToolCore)
library(sdmEvalToolUI)

# start the app
user_id <- "testuser"
sdm_tool(
  user = user_id,
  tabs = c(
    "overview",
    "predictions",
    "observations",
    "model",
    "predictors",
    "summary"
  )
)
```

A window should pop-up with the loaded app. Alternatively, you can visit
the following link in your browser: <http://localhost:8080>.

If you see an error message `Error: Could not connect to database`, try
setting the right folder with `sdmevaltool_options()`:

``` r
# use your path here to point to the right folder
sdmevaltool_options(base = "./sdm_evaluation_results")
```

## Navigation

## Landing page and instructions

<figure>
<img src="./images/tabs-01.png" alt="Landing" />
<figcaption aria-hidden="true">Landing</figcaption>
</figure>

<figure>
<img src="./images/tabs-02.png" alt="Index" />
<figcaption aria-hidden="true">Index</figcaption>
</figure>

## Model materials

### Spatial predictions

<figure>
<img src="./images/tabs-03.png" alt="Spatial predictions" />
<figcaption aria-hidden="true">Spatial predictions</figcaption>
</figure>

### Observations

<figure>
<img src="./images/tabs-04.png" alt="Observations, charts" />
<figcaption aria-hidden="true">Observations, charts</figcaption>
</figure>

<figure>
<img src="./images/tabs-05.png" alt="Observations, map" />
<figcaption aria-hidden="true">Observations, map</figcaption>
</figure>

### Model fit and summary

<figure>
<img src="./images/tabs-06.png" alt="Model fit and summary" />
<figcaption aria-hidden="true">Model fit and summary</figcaption>
</figure>

### Predictors

<figure>
<img src="./images/tabs-07.png" alt="Predictors" />
<figcaption aria-hidden="true">Predictors</figcaption>
</figure>

### Glossary

<figure>
<img src="./images/tabs-09.png" alt="Predictors" />
<figcaption aria-hidden="true">Predictors</figcaption>
</figure>

## Evaluations

### Spatial evaluations

### Non-spatial evaluations

### Abandoning and resuming evaluations

Models

Species

### Summary

<figure>
<img src="./images/tabs-08.png" alt="Summary" />
<figcaption aria-hidden="true">Summary</figcaption>
</figure>
