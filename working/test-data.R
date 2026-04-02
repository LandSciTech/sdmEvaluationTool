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
# DIR <- "./misc/test"
DIR <- "./misc/sdm_evaluation_results"
sdmevaltool_options(base = DIR) # use the misc folder

unlink(DIR, recursive = TRUE)
dir.create(DIR, recursive = TRUE)

# ------- species table ----------

SPP <- c(
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
)

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

# ------- models table ----------

# this ultimately has to be appended and not recreated
models <- data.frame(
  model_id = "bam_v5_can71",
  model_name = "BAM v5 Can 71",
  model_description = "BAM version 5 Canada model in BCR 71"
)
model_id <- "bam_v5_can71"

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

# -------- MODEL MATERIAL: MODELS --------
# ./materials/<model_id>/
# ./materials/<model_id>/model_metadata.parquet"
# ./materials/<model_id>/predictor_metadata.parquet"
# ./materials/<model_id>/predictor_raster.tif"

materials_fun <- function(
  x,
  model_id,
  species_id,
  component_id,
  material_settings = "[]"
) {
  rbind(
    x,
    data.frame(
      material_id = paste0(
        model_id,
        "_",
        ifelse(is.na(species_id), "ALL", as.character(species_id)),
        "_",
        component_id
      ),
      model_id = model_id,
      species_id = as.character(species_id),
      component_id = component_id,
      material_create_user = "testuser",
      material_create_time = timestamp_to(now()),
      material_modify_user = NA_character_,
      material_modify_time = NA_integer_,
      material_settings = material_settings
    )
  )
}
materials <- NULL

# --------- predictor_metadata ----

rule <- get_comp_rule("predictor_metadata", "upload")
fi <- file.path(path, "predictors", "predictor_metadata.csv")
x <- read_file(fi)
x <- x[, rule$output$columns]
fo <- make_target_path(rule$output$path, data = list(model_id = model_id))
write_file(x, fo)

drule <- get_comp_rule("predictor_metadata", "display")
ms <- jsonlite::toJSON(drule$material_settings)
materials <- materials_fun(materials, model_id, NA, "predictor_metadata", ms)

# --------- model_metadata / ODMAP ----

rule <- get_comp_rule("model_metadata", "upload")
fi <- file.path(path, "ODMAP", "ODMAP_Knight_2025-12-16.csv")
x <- read_file(fi)
fo <- make_target_path(rule$output$path, data = list(model_id = model_id))
write_file(x, fo)

drule <- get_comp_rule("model_metadata", "display")
materials <- materials_fun(materials, model_id, NA, "model_metadata")

# ------- predictor_raster RESAMPLED ------

rule <- get_comp_rule("predictor_raster", "upload")
fi <- file.path(path, "predictors", "predictor_stack.tif")
x <- read_file(fi)
x <- terra::resample(x, 5)
x <- terra::project(x, "epsg:4326")
fo <- make_target_path(rule$output$path, data = list(model_id = model_id))
write_file(x, fo)
materials <- materials_fun(materials, model_id, NA, "predictor_raster")

# we might have to organize predictor summaries and rasters a bit better? Check names etc...

# -------- MODEL MATERIAL: MODELS/SPECIES --------
# ./materials/<model_id>/species/<species_id>/
# ./materials/<model_id>/species/<species_id>/observations.gpkg"
# ./materials/<model_id>/species/<species_id>/spatial_prediction.tif"
# ./materials/<model_id>/species/<species_id>/model_summary.parquet"
# ./materials/<model_id>/species/<species_id>/model_fit.parquet"

# -------- observations -----------

rule <- get_comp_rule("observations", "upload")
fi <- file.path(path, "data", "observations_can71.csv")
x <- read_file(fi)
SPP2 <- colnames(x)[colnames(x) %in% species$species_id]
# set date/time to POSIX
x$date <- as.POSIXct(x$date)

drule <- get_comp_rule("observations", "display")
ms <- jsonlite::toJSON(drule$material_settings)

for (species_id in SPP2) {
  z <- x[, c("lat", "lon", "date", "method", species_id)]
  colnames(z) <- c("latitude", "longitude", "time", "method", "status")
  z <- sf::st_as_sf(z, coords = c("longitude", "latitude"))
  # lon/lat is 4326
  sf::st_crs(z) <- 4326
  # leaflet wants 4326
  z <- sf::st_transform(z, 4326)

  sr <- suntools::sunriset(
    crds = z,
    dateTime = z$time,
    direction = "sunrise",
    POSIXct.out = TRUE
  )
  z$hssr <- as.numeric(difftime(z$time, sr$time, units = "hours"))

  fo <- make_target_path(
    rule$output$path,
    data = list(model_id = model_id, species_id = species_id)
  )
  write_file(z, fo)

  materials <- materials_fun(
    materials,
    model_id,
    species_id,
    "observations",
    ms
  )
}

# -------- spatial_prediction ----

rule <- get_comp_rule("spatial_prediction", "upload")
drule <- get_comp_rule("spatial_prediction", "display")
ms <- jsonlite::toJSON(drule$material_settings)
for (species_id in SPP) {
  fi <- file.path(path, "predictions", paste0(species_id, "_can71_2020.tif"))
  x <- read_file(fi)
  x <- terra::project(x, "epsg:4326")
  fo <- make_target_path(
    rule$output$path,
    data = list(model_id = model_id, species_id = species_id)
  )
  write_file(x, fo)

  materials <- materials_fun(
    materials,
    model_id,
    species_id,
    "spatial_prediction",
    ms
  )
}

# -------- model summary -----------

rule <- get_comp_rule("model_summary", "upload")
fi <- file.path(path, "predictors", "predictor_importance.csv")
x <- read_file(fi)

drule <- get_comp_rule("model_summary", "display")
ms <- jsonlite::toJSON(drule$material_settings)

for (species_id in SPP) {
  z <- x[x$spp == species_id, -(1:2)]
  fo <- make_target_path(
    rule$output$path,
    data = list(model_id = model_id, species_id = species_id)
  )
  write_file(z, fo)

  materials <- materials_fun(
    materials,
    model_id,
    species_id,
    "model_summary",
    ms
  )
}

# -------- model fit -----------

rule <- get_comp_rule("model_fit", "upload")
fi <- file.path(path, "reliability", "validation_can71.csv")
x <- read_file(fi)

drule <- get_comp_rule("model_fit", "display")
ms <- jsonlite::toJSON(drule$material_settings)

for (species_id in SPP) {
  z <- x[x$id == species_id, -(1:4)]
  z <- data.frame(metric = colnames(z), value = unlist(z))
  fo <- make_target_path(
    rule$output$path,
    data = list(model_id = model_id, species_id = species_id)
  )
  write_file(z, fo)

  materials <- materials_fun(materials, model_id, species_id, "model_fit", ms)
}

# --------- DEPLOYMENTS -----------

# population assessment, distribution mapping, spatial prioritization, habitat mapping

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

# --------- ACCESS -----------

access <- data.frame(
  user_id = "testuser",
  deployment_id = c(
    "deployment1",
    "deployment2"
  ),
  user_roles = "evaluator"
)

# --------- DEPLOYMENT MATERIALS -----------

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

# --------- QUESTIONS -----------

# ./deployments/<deployment_id>/deployment_questions.csv
q <- sdmEvalToolCore::default_questions
v <- sapply(q$values, \(z) {
  paste0(z, collapse = ", ")
})
# q$values <- ifelse(q$type == "spatial", v, "")
q$values <- v
fo <- make_target_path(
  "deployments/{deployment_id}/deployment_questions.csv",
  data = list(deployment_id = "deployment1")
)
write_file(q, fo)

q <- sdmEvalToolCore::default_questions
q$followup_level[5] <- 3
q <- combine_questions(q)
v <- sapply(q$values, \(z) {
  paste0(z, collapse = ", ")
})
# q$values <- ifelse(q$type == "spatial", v, "")
q$values <- v
fo <- make_target_path(
  "deployments/{deployment_id}/deployment_questions.csv",
  data = list(deployment_id = "deployment2")
)
write_file(q, fo)

# --------- deployment settings -----------

fo <- make_target_path(
  "deployments/{deployment_id}/deployment_settings.json",
  data = list(deployment_id = "deployment1")
)
write_file(fromJSON(deployments$deployment_settings[1]), fo)
fo <- make_target_path(
  "deployments/{deployment_id}/deployment_settings.json",
  data = list(deployment_id = "deployment2")
)
write_file(fromJSON(deployments$deployment_settings[2]), fo)

# --------- SUBUNITS -----------

# ./deployments/<deployment_id>/deployment_subunits.gpkg
r <- read_file(file.path(path, "predictions", "CAWA_can71_2020.tif"))
r <- terra::project(r, "epsg:4326")

fi <- file.path(path, "data", "observations_can71.csv")
xy <- read_file(fi)
xy <- xy[, c("lat", "lon", "date", "method")]
xy <- sf::st_as_sf(xy, coords = c("lon", "lat"))
# lon/lat is 4326
sf::st_crs(xy) <- 4326

bbox1 <- sf::st_as_sfc(sf::st_bbox(r))
bbox2 <- sf::st_as_sfc(sf::st_bbox(xy))
bbox <- sf::st_as_sfc(sf::st_bbox(bbox1, bbox2))

su <- sf::st_read(file.path(path, "subunits", "ecoprovinces.shp"))
su <- sf::st_simplify(su, TRUE, 10)
su <- sf::st_transform(su, 4326)
su <- sf::st_intersection(su, bbox)
su$subunit_id <- su$ECOPROVINC
su <- su[, "subunit_id"]

su_gr <- sf::st_make_grid(su, n = 20)
# su_gr <- sf::st_make_grid(su, n = 20, square = FALSE)

su2 <- sf::st_sf(subunit_id = as.character(1:length(su_gr)), geometry = su_gr)
su2 <- sf::st_transform(su2, 4326)

su2$id <- seq_len(nrow(su2))
u <- rasterize(su2, r[[1]], "id")
values(u)[is.na(values(r[[1]]))] <- NA
su2$keep <- su2$id %in% na.omit(unique(values(u)[, 1]))

ii <- sf::st_intersects(xy, su2, sparse = FALSE)
su2$keep <- su2$keep | colSums(ii) > 0

su2 <- su2[su2$keep, ]
su2$keep <- NULL
su2$id <- NULL


fo <- make_target_path(
  "deployments/{deployment_id}/deployment_subunits.gpkg",
  data = list(deployment_id = "deployment1")
)
write_file(su2, fo)

fo <- make_target_path(
  "deployments/{deployment_id}/deployment_subunits.gpkg",
  data = list(deployment_id = "deployment2")
)
write_file(su, fo)

# --------- COMMENTS ----------- Excluded

# --------- EVALUATIONS ----------- Excluded

# -------- DATABASE ------

# unique(sdmEvalToolCore::fields$table)
check_table(users, "users")
check_table(species, "species")
check_table(components, "components")
check_table(models, "models")
check_table(materials, "materials")
check_table(deployments, "deployments")
check_table(deployment_materials, "deployment_materials")
check_table(access, "access")

# ./sdm_evaluation_db.sqlite
con <- db_connect(make_target_path("sdm_evaluation_db.sqlite"))
rs <- DBI::dbSendQuery(con, "PRAGMA foreign_keys = ON;")
DBI::dbClearResult(rs)

dbListTables(con)
db_create_tables(con)
dbListTables(con)

db_write_table(con, "species", species)
db_write_table(con, "models", models)
db_write_table(con, "users", users)
db_write_table(con, "components", components)

db_write_table(con, "materials", materials)
db_write_table(con, "deployments", deployments)
db_write_table(
  con,
  "deployment_materials",
  deployment_materials
)
db_write_table(con, "access", access)

sort(unique(sdmEvalToolCore::fields$table))
dbListTables(con)
db_disconnect(con)

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
