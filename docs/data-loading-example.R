# Organize files for minim BAM project

library(sf)
library(terra)
library(mefa4)
library(DBI)
library(RSQLite)
library(jsonlite)
library(suntools)
devtools::load_all("sdmEvalToolCore")

path <- "~/Dropbox/a8m/projects-2025/eccc-sdm/02-data/Model Upload/BAM"
conf <- yaml::read_yaml("spec/config.yml")
DIR <- "./misc/test2"
# DIR <- "./misc/sdm_evaluation_results"
sdmevaltool_options(base = DIR) # use the misc folder

unlink(DIR, recursive = TRUE)
dir.create(DIR, recursive = TRUE)

# --------- create new database file ------------

con <- db_connect(make_target_path("sdm_evaluation_db.sqlite"))
rs <- DBI::dbSendQuery(con, "PRAGMA foreign_keys = ON;")
DBI::dbClearResult(rs)

dbListTables(con)
db_create_tables(con)
dbListTables(con)

# -------- components ----------

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

# ------- users table -----------

# users <- data.frame(
#     user_id = c("holden", "draper", "okoye"),
#     user_name = c("James Holden", "Bobbie Draper", "Elvi Okoye"),
#     user_email = c(
#         "jim@rocinante.org",
#         "bdraper@mcrn.gov",
#         "okoye@rce.com"
#     ),
#     user_affiliation = c("Rocinante", "MCRN", "RCE"),
#     admin = c(TRUE, FALSE, FALSE)
# )
users <- data.frame(
  user_id = "testuser",
  user_name = "Test User",
  user_email = "x@y.z",
  user_affiliation = "XYZ",
  admin = FALSE
)
db_write_table(con, "users", users)

# ------- species table ----------

species <- structure(
  list(
    species_id = c(
      "BBWA",
      "BBWO",
      "BLPW",
      "CAWA",
      "CONW",
      "LEYE",
      "OSFL",
      "OVEN",
      "RUBL",
      "SOSA",
      "TEWA"
    ),
    scientific_name = c(
      "Setophaga castanea",
      "Picoides arcticus",
      "Setophaga striata",
      "Cardellina canadensis",
      "Oporornis agilis",
      "Tringa flavipes",
      "Contopus cooperi",
      "Seiurus aurocapilla",
      "Euphagus carolinus",
      "Tringa solitaria",
      "Oreothlypis peregrina"
    ),
    english_name = c(
      "Bay-breasted Warbler",
      "Black-backed Woodpecker",
      "Blackpoll Warbler",
      "Canada Warbler",
      "Connecticut Warbler",
      "Lesser Yellowlegs",
      "Olive-sided Flycatcher",
      "Ovenbird",
      "Rusty Blackbird",
      "Solitary Sandpiper",
      "Tennessee Warbler"
    ),
    french_name = c(
      "Paruline à poitrine baie",
      "Pic à dos noir",
      "Paruline rayée",
      "Paruline du Canada",
      "Paruline à gorge grise",
      "Petit Chevalier",
      "Moucherolle à côtés olive",
      "Paruline couronnée",
      "Quiscale rouilleux",
      "Chevalier solitaire",
      "Paruline obscure"
    )
  ),
  row.names = c(15L, 16L, 24L, 33L, 40L, 76L, 90L, 91L, 106L, 113L, 118L),
  class = "data.frame"
)
db_write_table(con, "species", species)

# ------- models table ----------

user_id <- "testuser" # user who uploads the materials
model_id <- "bam_v5_can71"
models <- data.frame(
  model_id = model_id,
  model_name = "BAM v5 Can 71",
  model_description = "BAM version 5 Canada model in BCR 71"
)
db_write_table(con, "models", models)

# --------- predictor_metadata ----

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

# --------- model_metadata / ODMAP ----

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

# ------- predictor_raster RESAMPLED ------

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
# FIXME: we might have to organize predictor summaries and rasters a bit better? Check names etc...

# -------- observations -----------

fi <- file.path(path, "data", "observations_can71.csv")
x <- read_file(fi)
colnames(x)[1:7] <- c(
  "id",
  "latitude",
  "longitude",
  "buffer",
  "time",
  "method",
  "year"
)
prep_observations(
  x = x,
  species = species,
  model_id = model_id,
  user_id = user_id,
  material_settings = NULL,
  con = con,
  update = FALSE
)

# -------- model summary -----------

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

# -------- model fit -----------

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

# -------- spatial_prediction ----

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

# --------- DEPLOYMENTS -----------

rule <- get_comp_rule("deployment_settings", "upload")
fi <- file.path(path, "welcome", "evaluator_welcome.md")
x <- read_file(fi)

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
d1 <- d2 <- conf$templates$deployment_settings
d1$use_case <- list(list(en = "Population assessment", fr = ""))
d2$use_case <- list(list(en = "Spatial prioritization", fr = ""))
d1$instructions_to_evaluators <- paste0(x, collapse = "\n")
d2$instructions_to_evaluators <- paste0(x, collapse = "\n")
deployments$deployment_settings[1] <- jsonlite::toJSON(d1)
deployments$deployment_settings[2] <- jsonlite::toJSON(d2)

db_write_table(con, "deployments", deployments)

# --------- deployment settings -----------

for (j in 1:nrow(deployments)) {
  prep_deployment_settings(
    deployment_id = deployments$deployment_id[j],
    x = fromJSON(deployments$deployment_settings[j])
  )
}

# --------- deployment questions -----------

# default questions - no drilldown
prep_deployment_questions(
  deployment_id = "deployment1",
  x = NULL
)

# default questions - with drilldown
q <- sdmEvalToolCore::default_questions
q$followup_level[5] <- 3
prep_deployment_questions(
  deployment_id = "deployment2",
  x = q
)

# --------- ACCESS -----------

access <- data.frame(
  user_id = user_id,
  deployment_id = deployments$deployment_id,
  user_roles = "evaluator"
)
db_write_table(con, "access", access)

# --------- DEPLOYMENT MATERIALS -----------

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

# --------- deployment subunits -----------

# raster template
r <- read_file(file.path(path, "predictions", "CAWA_can71_2020.tif"))

prep_deployment_subunits(
  deployment_id = "deployment1",
  x = NULL,
  reference = r,
  n = c(20, 20),
  square = TRUE
)

# ecoprovinces
su <- sf::st_read(file.path(path, "subunits", "ecoprovinces.shp"))
su$subunit_id <- su$ECOPROVINC
# note this does not compare observation locations to the template
# points can sometimes fall outside of raster cells

prep_deployment_subunits(
  deployment_id = "deployment2",
  x = su,
  reference = r
)

sort(unique(sdmEvalToolCore::fields$table))
dbListTables(con)
db_disconnect(con)

if (FALSE) {
  file.copy(
    make_target_path("sdm_evaluation_db.sqlite"),
    make_target_path("sdm_evaluation_db_og.sqlite")
  )

  od <- setwd("misc")
  utils::zip(
    "./sdm_evaluation_results.zip",
    file.path(
      "sdm_evaluation_results",
      list.files("sdm_evaluation_results", recursive = TRUE)
    )
  )
  setwd(od)
}
