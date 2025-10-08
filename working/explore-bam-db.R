# Organize files for minim BAM project

library(sf)
library(terra)
library(mefa4)
library(DBI)
library(RSQLite)

path <- "~/Dropbox/a8m/projects-2025/eccc-sdm/02-data/Model Upload/BAM"
conf <- yaml::read_yaml("spec/config.yml")

devtools::load_all("sdmEvalToolCore")
sdmevaltool_options(base = "~/Dropbox/a8m/projects-2025/eccc-sdm/02-data/base")


# ------- species table ----------

SPP <- c("BBWA", "BBWO", "BLPW", "CAWA", "CONW", "LEYE", "OSFL", "OVEN", "RUBL", "SOSA", "TEWA")
spt <- jsonlite::fromJSON("https://borealbirds.github.io/api/v4/species/")
spt <- spt[spt$id %in% SPP, c("id", "scientific", "english", "french")]
colnames(spt) <- c("species_id", "scientific_name", "english_name", "french_name")
species <- spt

# ------- models table ----------

# this ultimately has to be appended and not recreated
models <- data.frame(
    model_id = "bam_v5_can71",
    model_name = "BAM v5 Can 71",
    model_description = "BAM version 5 Canada model in BCR 71",
    model_metadata = NA_character_)
model_id <- "bam_v5_can71"

# ------- users table -----------

users <- data.frame(
    user_id = "psolymos",
    user_name = "Peter Solymos",
    user_email = "peter@analythium.io",
    user_affiliation = "Analythium",
    user_roles = "admin")

# -------- components ----------

components <- sdmEvalToolCore::components[,c("component", "description", "mandatory")]
colnames(components) <- c("component_id", "component_description", "component_mandatory")

# -------- MODEL MATERIAL: MODELS --------
# ./materials/<model_id>/
# ./materials/<model_id>/model_metadata.parquet"
# ./materials/<model_id>/predictor_metadata.parquet"
# ./materials/<model_id>/predictor_raster.tif"

materials_fun <- function(x, model_id, species_id, component_id) {
    rbind(x, data.frame(
        material_id = uuid::UUIDgenerate(),
        model_id = model_id,
        species_id = as.character(species_id),
        component_id = component_id,
        material_create_user = "psolymos",
        material_create_time = timestamp_to(now()),
        material_modify_user = NA_character_,
        material_modify_time = NA_character_))
}
materials <- NULL

# --------- model_metadata ----
# not yet available

# --------- predictor_metadata ----

rule <- get_comp_rule("predictor_metadata", "upload")
fi <- file.path(path, "predictors", "predictor_metadata.csv")
x <- read_file(fi)
x <- x[,rule$columns]
fo <- make_target_path(rule$output$path, data = list(model_id=model_id))
write_file(x, fo)

materials <- materials_fun(materials, model_id, NA, "predictor_metadata")

# ------- predictor_raster ------

rule <- get_comp_rule("predictor_raster", "upload")
fi <- file.path(path, "predictors", "can71_2000.tif")
x <- read_file(fi)
# reproject???
fo <- make_target_path(rule$output$path, data = list(model_id=model_id))
write_file(x, fo)

materials <- materials_fun(materials, model_id, NA, "predictor_raster")

# we might have to organize predictor summaries and rasters a bit better? Check names etc...

# -------- MODEL MATERIAL: MODELS/SPECIES --------
# ./materials/<model_id>/<species_id>/
# ./materials/<model_id>/<species_id>/observations.gpkg"
# ./materials/<model_id>/<species_id>/spatial_prediction.tif"
# ./materials/<model_id>/<species_id>/model_summary.parquet"
# ./materials/<model_id>/<species_id>/model_fit.parquet"

# -------- observations -----------

rule <- get_comp_rule("observations", "upload")
fi <- file.path(path, "data", "observations_can71.csv")
x <- read_file(fi)
spp <- colnames(x)[colnames(x) %in% species$species_id]
# set date/time to POSIX
x$date <- as.POSIXct(x$date)

for (species_id in spp) {
    z <- x[,c("lat", "lon", "date", "method", species_id)]
    colnames(z) <- c("latitude", "longitude", "time", "method", "status")
    z <- sf::st_as_sf(z, coords = c("longitude", "latitude"))
    # lon/lat is 4326
    sf::st_crs(z) <- 4326
    # leaflet wants 3857
    z <- sf::st_transform(z, 3857)
    fo <- make_target_path(rule$output$path, 
        data = list(model_id=model_id, species_id=species_id))
    write_file(z, fo)

    materials <- materials_fun(materials, model_id, species_id, "observations")

}

# -------- spatial_prediction ----

rule <- get_comp_rule("spatial_prediction", "upload")
for (species_id in SPP) {
    fi <- file.path(path, "predictions", paste0(species_id, "_can71_2020.tif"))
    x <- read_file(fi)
    # reproject???
    fo <- make_target_path(rule$output$path, 
        data = list(model_id=model_id, species_id=species_id))
    write_file(x, fo)

    materials <- materials_fun(materials, model_id, species_id, "spatial_prediction")

}

# -------- model summary -----------

rule <- get_comp_rule("model_summary", "upload")
fi <- file.path(path, "predictors", "predictor_importance.csv")
x <- read_file(fi)

for (species_id in SPP) {
    z <- x[x$spp == species_id,-(1:2)]
    fo <- make_target_path(rule$output$path, 
        data = list(model_id=model_id, species_id=species_id))
    write_file(z, fo)

    materials <- materials_fun(materials, model_id, species_id, "model_summary")

}


# -------- model fit -----------

rule <- get_comp_rule("model_fit", "upload")
fi <- file.path(path, "reliability", "validation_can71.csv")
x <- read_file(fi)

for (species_id in SPP) {
    z <- x[x$id == species_id,-(1:4)]
    z <- data.frame(metric=colnames(z), value=unlist(z))
    fo <- make_target_path(rule$output$path, 
        data = list(model_id=model_id, species_id=species_id))
    write_file(z, fo)

    materials <- materials_fun(materials, model_id, species_id, "model_fit")

}

# -------- DATABASE ------

# ./sdm_evaluation_db.sqlite
con <- dbConnect(RSQLite::SQLite(), make_target_path("sdm_evaluation_db.sqlite"))

dbWriteTable(con, "species", species, overwrite=TRUE)
dbWriteTable(con, "models", models, overwrite=TRUE)
dbWriteTable(con, "users", users, overwrite=TRUE)
dbWriteTable(con, "components", components, overwrite=TRUE)

dbWriteTable(con, "materials", materials, overwrite=TRUE)

dbListTables(con)
dbDisconnect(con)

# the output from this script can be found here:
# https://www.dropbox.com/scl/fi/1khm6hhoosgkjtmldqxg7/base.zip?rlkey=xwywv6s5cgjr0ufrxosxnx95w&dl=0
# we can put this inside the _tmp folder and use it as the folder location
# (_tmp is git ignored)
