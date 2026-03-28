# SDM Model Evaluation Tool User Guide for Modelers

> How to manage materials and deployments

## Installation

Install the following R packages:

- sf
- terra
- DBI
- RSQLite
- jsonlite
- suntools
- sdmEvalToolCore

## Uploading model materials

See the [`data-loading-example.R`](data-loading-example.R) script.

We first load libraries and set up variables:

``` r
library(sf)
library(terra)
library(mefa4)
library(DBI)
library(RSQLite)
library(jsonlite)
library(suntools)
library(sdmEvalToolCore)

path <- "c:/path/to/data/Model Upload/BAM"
conf <- yaml::read_yaml(system.file("config.yml", package = "sdmEvalToolCore"))
DIR <- "misc/sdm_evaluation_results"
dir.create(DIR, recursive = TRUE)

sdmevaltool_options(base = DIR)
```

Use an existing database file (copy it to the root of the `DIR` folder),
or create a new database file and turn foreign key constraints on:

``` r
con <- db_connect(make_target_path("sdm_evaluation_db.sqlite"))
rs <- DBI::dbSendQuery(con, "PRAGMA foreign_keys = ON;")
DBI::dbClearResult(rs)
```

If using a fresh database, use the `db_create_tables()` function to
create the empty tables:

``` r
db_create_tables(con)
```

Due to the foreign key constraint, tables need to be updated respecting
the keys relationships. If a key is used as a foreign key, it needs to
exist in the parent table as a primary key.

The components table should not change, the defaults are used from the
package:

``` r
components <- sdmEvalToolCore::components[, c(
  "component",
  "description",
  "mandatory"
)]
colnames(components) <- c(
  "component_id",
  "component_description",
  "component_mandatory"
)
db_write_table(con, "components", components)
```

The species table should also not change frequently, however, this is
only a small portion of all expected species:

``` r
species <- structure(
  list(
    species_id = c(
      "BBWA", ... , "TEWA"
    ),
    scientific_name = c(
      "Setophaga castanea", ... , "Oreothlypis peregrina"
    ),
    english_name = c(
      "Bay-breasted Warbler", ... , "Tennessee Warbler"
    ),
    french_name = c(
      "Paruline à poitrine baie", ... , "Paruline obscure"
    )
  ),
  row.names = c(15L, 16L, 24L, 33L, 40L, 76L, 90L, 91L, 106L, 113L, 118L),
  class = "data.frame"
)
db_write_table(con, "species", species)
```

The model table:

``` r
model_id <- "bam_v5_can71" # we'll use the model ID later

models <- data.frame(
  model_id = model_id,
  model_name = "BAM v5 Can 71",
  model_description = "BAM version 5 Canada model in BCR 71"
)
db_write_table(con, "models", models)
```

Create the users table next:

``` r
user_id <- "testuser" # user who uploads the materials

users <- data.frame(
  user_id = "testuser",
  user_name = "Test User",
  user_email = "x@y.z",
  user_affiliation = "XYZ",
  admin = FALSE
)
db_write_table(con, "users", users)
```

Predictor metadata:

``` r
rule <- get_comp_rule("predictor_metadata", "upload")
fi <- file.path(path, "predictors", "predictor_metadata.csv")
x <- read_file(fi)
x <- x[, rule$output$columns]

prep_predictor_metadata(
  x = x,
  model_id = model_id,
  user_id = user_id,
  material_settings = NULL,
  con = con,
  update = FALSE
)
```

Model (ODMAP) metadata:

``` r
fi <- file.path(path, "ODMAP", "ODMAP_Knight_2025-12-16.csv")
x <- read_file(fi)

prep_model_metadata(
  x = x,
  model_id = model_id,
  user_id = user_id,
  material_settings = NULL,
  con = con,
  update = FALSE
)
```

Predictor raster (resampled to save space):

``` r
fi <- file.path(path, "predictors", "predictor_stack.tif")
x <- read_file(fi)

prep_predictor_raster(
  x = x,
  resolution = 5,
  model_id = model_id,
  user_id = user_id,
  material_settings = NULL,
  con = con,
  update = FALSE
)
```

Species observations, processing multiple species:

``` r
fi <- file.path(path, "data", "observations_can71.csv")
x <- read_file(fi)
colnames(x)[1:7] <- c("id", "latitude", "longitude",
  "buffer", "time", "method", "year")
prep_observations(
  x = x,
  species = species,
  model_id = model_id,
  user_id = user_id,
  material_settings = NULL,
  con = con,
  update = FALSE
)
```

Model summaries for the species:

``` r
fi <- file.path(path, "predictors", "predictor_importance.csv")
x <- read_file(fi)
colnames(x)[1] <- "species_id"
x$bcr <- NULL

prep_model_summary(
  x = x,
  species = species,
  model_id = model_id,
  user_id = user_id,
  material_settings = NULL,
  con = con,
  update = FALSE
)
```

Model fit for the species:

``` r
fi <- file.path(path, "reliability", "validation_can71.csv")
x <- read_file(fi)
colnames(x)[1] <- "species_id"
x$scientific <- x$english <- x$region <- NULL

prep_model_fit(
  x = x,
  species = species,
  model_id = model_id,
  user_id = user_id,
  material_settings = NULL,
  con = con,
  update = FALSE
)
```

Species predictions:

``` r
for (species_id in species$species_id) {
  fi <- file.path(path, "predictions", paste0(species_id, "_can71_2020.tif"))
  x <- read_file(fi)

  prep_spatial_prediction(
    x = x,
    model_id = model_id,
    species_id = species_id,
    user_id = user_id,
    material_settings = NULL,
    con = con,
    update = FALSE
  )
}
```

## Material settings

Default material settings are defined in the YAML specification. To
access these, you can use the following:

``` r
component_id <- "predictor_metadata"
str(get_comp_rule(component_id, "display")$material_settings)
```

    ## List of 1
    ##  $ legend:List of 2
    ##   ..$ en: chr "Predictor metadata table."
    ##   ..$ fr: chr ""

This default is used when using the above `prep_<component_id>()`
functions. Using the same structure, we can pass a new legend:

``` r
prep_predictor_metadata(
  x = x,
  model_id = model_id,
  user_id = user_id,
  material_settings = list(en = "Table with predictor metadata.", fr = ""),
  con = con,
  update = TRUE
)
```

Using `update = TRUE` we can update an existing material.

## Managing deployments

Create 2 deployments, keeping the `deploylemt_settings` empty (`[]`) for
now. This field is JSON, we’ll add the value later:

``` r
deployments <- data.frame(
  deployment_id = c("deployment1", "deployment2"),
  deployment_name = c("BAM: Pop. Assessment", "BAM: Prioritization"),
  deployment_description = c(
    "BAM: population assessment",
    "BAM: spatial prioritization"
  ),
  deployment_create_user = "testuser",
  deployment_create_time = timestamp_to(now()),
  deployment_settings = c("[]", "[]")
)
```

Let’s read in the welcome message (markdown file):

``` r
rule <- get_comp_rule("deployment_settings", "upload")
fi <- file.path(path, "welcome", "evaluator_welcome.md")
x <- read_file(fi)
```

Next we define the `deployment_settings` using the welcome message and
the use case:

``` r
d1 <- d2 <- conf$templates$deployment_settings
d1$use_case <- list(list(en = "Population assessment", fr = ""))
d2$use_case <- list(list(en = "Spatial prioritization", fr = ""))
d1$instructions_to_evaluators <- paste0(x, collapse = "\n")
d2$instructions_to_evaluators <- paste0(x, collapse = "\n")
deployments$deployment_settings[1] <- jsonlite::toJSON(d1)
deployments$deployment_settings[2] <- jsonlite::toJSON(d2)
```

We write the table to the database:

``` r
db_write_table(con, "deployments", deployments)
```

Write the deployment settings to the files as well:

``` r
for (j in 1:nrow(deployments)) {
  prep_deployment_settings(
    deployment_id = deployments$deployment_id[j],
    x = fromJSON(deployments$deployment_settings[j])
  )
}
```

The default deployment questions can be written to the files using the
following expression (you can also provide your own as the argument
`x`):

``` r
prep_deployment_questions(
  deployment_id = "deployment1",
  x = NULL
)
```

The file now can be edited as needed.

If drilldown questions are needed, edit the `followup_level` field and
apply the `combine_questions()` function like:

``` r
q <- sdmEvalToolCore::default_questions
q$followup_level[5] <- 3
q <- combine_questions(q)

prep_deployment_questions(
  deployment_id = "deployment2",
  x = q
)
```

Define user access to the deployments (add evaluator user names here):

``` r
access <- data.frame(
  user_id = user_id,
  deployment_id = deployments$deployment_id,
  user_roles = "evaluator"
)
db_write_table(con, "access", access)
```

The deployment materials repeat the materials for each deployment. To do
this part, we read in the materials (filter if deployments involve a
subset), add the deployment ID. Finally, write the table to the
database:

``` r
materials <- db_read_table(con, "materials")

deployment_materials <- data.frame(
  deployment_material_id = paste0(
    rep(
      c("deployment1_", "deployment2_"),
      each = length(materials$material_id)
    ),
    materials$material_id
  ),
  deployment_id = rep(
    c("deployment1", "deployment2"),
    each = length(materials$material_id)
  ),
  material_id = materials$material_id
)

db_write_table(
  con,
  "deployment_materials",
  deployment_materials
)
```

Deployment subunits can be set up as a regular grid based on the extent
of a reference raster (distribution maps) and the spatial points
(observations) object:

``` r
# raster template
r <- read_file(file.path(path, "predictions", "CAWA_can71_2020.tif"))
# spatial points template
xy <- read_file(file.path(path, "data", "observations_can71.csv"))
xy <- xy[, c("lat", "lon")]
xy <- sf::st_as_sf(xy, coords = c("lon", "lat"))
sf::st_crs(xy) <- 4326

prep_deployment_subunits(
  deployment_id = "deployment1",
  x = NULL,
  reference_raster = r,
  reference_points = xy,
  n = c(20, 20),
  square = TRUE
)
```

Alternatively, deployment subunits can be defined based on custom vector
layers, e.g. ecoregions/ecoprovinces. In this case the subunit vector
layer will be transformed to epsg:4326 and clipped to the bounding box
of the reference layers:

``` r
# ecoprovinces
su <- sf::st_read(file.path(path, "subunits", "ecoprovinces.shp"))
su$subunit_id <- su$ECOPROVINC

prep_deployment_subunits(
  deployment_id = "deployment2",
  x = su,
  reference_raster = r,
  reference_points = xy
)
```
