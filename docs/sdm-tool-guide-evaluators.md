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

## Adding the data set

Now download the
[sdv_evaluation_results.zip](https://drive.google.com/file/d/12dZ8vpiNuusICc4b1QyREr1NI8HQAM1t/view?usp=drive_link)
to your *sdmEvaluationTool* project folder. If you have an older version
of *sdv_evaluation_results.zip* in your project folder, replace it with
the new version.

## Installation

Use this script in R to install required packages and download/extract
the example data set (say ‘yes’ or select the ‘All’ option to update
packages if asked):

``` r
source("https://raw.githubusercontent.com/LandSciTech/sdmEvaluationTool/refs/heads/word-refinement/setup_JH.R")
```

Note that if you have a previous deployment of the tool installed, this
setup script will move your old results to an
*sdm_evaluation_results_old* folder.

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
    "predictors",
    "model",
    "summary"
  )
)
```

A window should pop-up with the loaded app. Alternatively, you can visit
the following link in your browser: <http://localhost:7405>.

If you see an error message `Error: Could not connect to database`, try
setting the right folder with `sdmevaltool_options()`:

``` r
# use your path here to point to the right folder
sdmevaltool_options(base = "./sdm_evaluation_results")
```

## Navigation and glossary

The landing page shows an evaluator all the deployments. Each deployment
lists the model related materials (orange buttons) and the species
related materials (blue buttons). The percentages on the right show the
overall progress. Clicking the chevrons left of the species names opens
up a table showing the progress of the evaluation materials.

The left side of the top navigation (1) lets you go through the tabs,
each tab showing one or two deployment materials. Tabs with blue letters
refer to materials for species, tabs with orange letters refer to model
level results. You can change the user role (2) if you have any other
roles.

Select a deployment, model and species from the dropdown menus at the
right side of the top navigation (3). You can also click the orange/blue
buttons to make a similar selection. Model purpose, evaluation
questions, and evaluation polygons can differ among deployments,
allowing the evaluation process to be tailored to the specific needs of
modelers, users and evaluators. In the “Simple for population
assessment” example deployment we have provided much larger evaluation
polygons, removed followup questions, and removed questions about the
model that would be difficult for a non-modeler to answer. Deployment,
model, and species selections determine what is shown in the other tabs.
You can return to the Index tab at any time or use the top navigation to
make changes to these values.

Clicking the question mark icon in the bottom right corner of the page
(4) opens the glossary.

![](./images/tabs/Slide1.png) Search for words in the glossary by typing
into the Search area. You will see topics and descriptions in which the
word appears.

![](./images/tabs/Slide2.png)

Once a deployment is selected, you’ll see a welcome message and
instructions on the right. You can hide this message by clicking the
arrow in the top right corner. The message can be made visible again by
clicking the arrow.

![](./images/tabs/Slide3.png) At any time you can “abandon” a review by
clicking the `X` icon (2). It is helpful to describe your reason for
abandoning the review. You can resume an abandoned review at any time by
clicking the red `X` icon and changing your answer to ‘no’.

![](./images/tabs/Slide4.png)

## Model materials and evaluations

### Spatial predictions

The main part of the tabs are the deployment material (1) and the
evaluation area on the right. The evaluations can be hidden to make the
main area larger. Scroll up and down in the evaluations area.

![](./images/tabs/Slide5.png)

Spatial predictions (1) are shown as raster layers in the interactive
map. Select the base layer, turn on the Distribution or or Uncertainty
layers. There is also a Subunits layer that is used for spatial
evaluations (see below).

Click the Expand button (bottom right corner of the cards that contain
the maps, tables, etc.) to pop the material into a full-screen mode.

Spatial questions (e.g. 2) ask evaluators to identify one or more
evaluation subunits. In this example, the evaluator has indicated that
they are confident about their knowledge of the species in units 71, 72
and 92. The red dot (3) indicates that the evaluator has not yet saved
their responses to the prediction evaluation questions. To save, scroll
to the bottom of the evaluatio questions and click “Save Responses”.

Throughout the questions asterisks (e.g. 4) indicate terms that may not
be familiar to all evaluators. Check the glossary (5) for definitions of
unfamiliar terms.

### Observations

The observations tab has a Charts and a Map component.

In the map, there are dropdowns to filter the observations by (1). In
the map (2), change the base layers, and turn on/off the Absences and
Presences, also the Subunits.

![](./images/tabs/Slide6.png)

Select the options for the charts (1) and the observations summaries (2)
will change accordingly.

![](./images/tabs/Slide7.png)

### Predictors

The Predictors tab contains the Predictor Raster (1) map, use the
dropdown to change the layer. The predictor metadata (2) table is at the
bottom. Use the expand button to make them pop to full-screen.

![Predictors](./images/tabs/Slide8.png) In some cases (e.g. 3)
additional information about the model is useful or essential for
answering a question. Click on the (!) to see relevant model metadata.

### Model fit and summary

The model fit (1) and model summary (2) are shown in the same tab.

![](./images/tabs/Slide9.png)

### Evaluation summary

Summarize your evaluation by answering questions in the summary tab. In
this example, the evaluator believes that the model can be used for the
intended applications in the identified areas, and is very concerned
about using the model for the intended applications in other areas.

![](./images/tabs/Slide10.png)
