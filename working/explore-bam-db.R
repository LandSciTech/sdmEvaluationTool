# Organize files for minim BAM project

library(sf)
library(terra)
library(mefa4)
library(DBI)
library(RSQLite)
library(jsonlite)

path <- "~/Dropbox/a8m/projects-2025/eccc-sdm/02-data/Model Upload/BAM"
conf <- yaml::read_yaml("spec/config.yml")

devtools::load_all("sdmEvalToolCore")
sdmevaltool_options(base = "./misc/base") # use the misc folder
unlink("./misc/base", recursive = TRUE)
dir.create("./misc/base", recursive = TRUE)

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
# spt <- jsonlite::fromJSON("https://borealbirds.github.io/api/v4/species/")
# spt <- spt[spt$id %in% SPP, c("id", "scientific", "english", "french")]
# colnames(spt) <- c(
#     "species_id",
#     "scientific_name",
#     "english_name",
#     "french_name"
# )
# species <- spt

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
    model_description = "BAM version 5 Canada model in BCR 71",
    model_metadata = NA_character_
)
model_id <- "bam_v5_can71"

# ------- users table -----------

users <- data.frame(
    user_id = c("holden", "draper", "okoye"),
    user_name = c("James Holden", "Bobbie Draper", "Elvi Okoye"),
    user_email = c(
        "jim@rocinante.org",
        "bdraper@mcrn.gov",
        "okoye@rce.com"
    ),
    user_affiliation = c("Rocinante", "MCRN", "RCE"),
    admin = c(TRUE, FALSE, FALSE)
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
                as.character(species_id),
                "_",
                component_id
            ),
            model_id = model_id,
            species_id = as.character(species_id),
            component_id = component_id,
            material_create_user = "holden",
            material_create_time = timestamp_to(now()),
            material_modify_user = NA_character_,
            material_modify_time = NA_character_,
            material_settings = material_settings
        )
    )
}
materials <- NULL

# --------- model_metadata ----
# not yet available

# --------- predictor_metadata ----

rule <- get_comp_rule("predictor_metadata", "upload")
fi <- file.path(path, "predictors", "predictor_metadata.csv")
x <- read_file(fi)
x <- x[, rule$columns]
fo <- make_target_path(rule$output$path, data = list(model_id = model_id))
write_file(x, fo)

drule <- get_comp_rule("predictor_metadata", "display")
ms <- jsonlite::toJSON(drule$materials_settings)
materials <- materials_fun(materials, model_id, NA, "predictor_metadata", ms)

# ------- predictor_raster EXCLUDED ------

# rule <- get_comp_rule("predictor_raster", "upload")
# fi <- file.path(path, "predictors", "can71_2000.tif")
# x <- read_file(fi)
# # reproject???
# fo <- make_target_path(rule$output$path, data = list(model_id = model_id))
# write_file(x, fo)

# materials <- materials_fun(materials, model_id, NA, "predictor_raster")

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
spp <- colnames(x)[colnames(x) %in% species$species_id]
# set date/time to POSIX
x$date <- as.POSIXct(x$date)

drule <- get_comp_rule("observations", "display")
ms <- jsonlite::toJSON(drule$materials_settings)

for (species_id in spp) {
    z <- x[, c("lat", "lon", "date", "method", species_id)]
    colnames(z) <- c("latitude", "longitude", "time", "method", "status")
    z <- sf::st_as_sf(z, coords = c("longitude", "latitude"))
    # lon/lat is 4326
    sf::st_crs(z) <- 4326
    # leaflet wants 3857
    z <- sf::st_transform(z, 3857)
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
ms <- jsonlite::toJSON(drule$materials_settings)
for (species_id in SPP) {
    fi <- file.path(path, "predictions", paste0(species_id, "_can71_2020.tif"))
    x <- read_file(fi)
    # reproject???
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
ms <- jsonlite::toJSON(drule$materials_settings)

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
ms <- jsonlite::toJSON(drule$materials_settings)

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

deployments <- data.frame(
    deployment_id = c("deployment1", "deployment2"),
    deployment_name = c("Deployment 1", "Deployment 2"),
    deployment_description = c("Deployment 1.", "Deployment 2."),
    deployment_create_user = c("holden", "holden"),
    deployment_create_time = c(
        timestamp_to(now()),
        timestamp_to(now() + 60 * 60)
    ),
    deployment_settings = c("[]", "[]")
)
d1 <- d2 <- conf$templates$deployment_settings
d1$comments_allowed <- TRUE
d2$preferred_language <- "fr"
d2$use_cases <- list(list(en = "Forestry", fr = "Foresterie"))
deployments$deployment_settings[1] <- jsonlite::toJSON(d1)
deployments$deployment_settings[2] <- jsonlite::toJSON(d2)

# --------- ACCESS -----------

access <- data.frame(
    user_id = "holden",
    deployment_id = c("deployment1"),
    user_roles = "modeler,commenter"
)
access <- rbind(
    access,
    data.frame(
        user_id = c("draper", "sjohnson", "draper", "sjohnson"),
        deployment_id = c(
            "deployment1",
            "deployment1",
            "deployment2",
            "deployment2"
        ),
        user_roles = c(
            "evaluator,commenter",
            "evaluator",
            "modeler,commenter",
            "evaluator,commenter"
        )
    )
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
fo <- make_target_path(
    "deployments/{deployment_id}/deployment_questions.csv",
    data = list(deployment_id = "deployment1")
)
write_file(sdmEvalToolCore::default_questions, fo)
fo <- make_target_path(
    "deployments/{deployment_id}/deployment_questions.csv",
    data = list(deployment_id = "deployment2")
)
write_file(sdmEvalToolCore::default_questions, fo)


# --------- SUBUNITS -----------

# ./deployments/<deployment_id>/deployment_subunits.gpkg
su <- sf::st_read(file.path(path, "subunits", "ecoprovinces.shp"))
su <- sf::st_simplify(su, TRUE, 10)
r <- read_file(file.path(path, "predictions", "CAWA_can71_2020.tif"))
bbox <- sf::st_as_sfc(sf::st_bbox(r))
su <- sf::st_transform(su, sf::st_crs(r))
su <- sf::st_intersection(su, bbox)
su$subunit_id <- su$ECOPROVINC
su <- su[, "subunit_id"]
fo <- make_target_path(
    "deployments/{deployment_id}/deployment_subunits.gpkg",
    data = list(deployment_id = "deployment1")
)
write_file(su, fo)

# --------- COMMENTS -----------

comments <- data.frame(
    deployment_id = "deployment1",
    model_id = model_id,
    species_id = "CAWA",
    comment_create_user = c("draper", "holden"),
    comment_create_time = c(timestamp_to(now()), timestamp_to(now() + 60 * 15)),
    comment_body = c("These results look good.", "All right.")
)

# --------- EVALUATIONS -----------

evaluations <- data.frame(
    deployment_material_id = c(
        "deployment1_bam_v5_can71_CAWA_observations bam_v5_can71",
        "deployment1_bam_v5_can71_CAWA_observations bam_v5_can71"
    ),
    deployment_id = c("deployment1", "deployment1"),
    material_id = c(
        "bam_v5_can71_CAWA_observations bam_v5_can71",
        "bam_v5_can71_CAWA_observations bam_v5_can71"
    ),
    use_cases = "Forestry",
    evaluation_create_user = "draper",
    evaluation_create_time = c(timestamp_to(now()), timestamp_to(now() + 60)),
    evaluation_modify_user = NA_character_,
    evaluation_modify_time = NA_character_,
    evaluation_body = NA_character_,
    note_create_user = NA_character_,
    note_create_time = NA_character_,
    note_body = NA_character_
)
e1 <- conf$components$observations$evaluation$questions
e1[[1]]$response <- "Observations look good to me."
e2 <- conf$components$spatial_prediction$evaluation$questions
e2[[2]]$response <- "5"
e2[[3]]$response <- "Not applicable"
e2[[4]]$response <- "4"
e2[[5]]$response <- "3"
e2[[6]]$response <- "Collect more data."
evaluations$evaluation_body[1] <- jsonlite::toJSON(e1)
evaluations$evaluation_body[2] <- jsonlite::toJSON(e2)

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
check_table(comments, "comments")
check_table(evaluations, "evaluations")

# ./sdm_evaluation_db.sqlite
con <- dbConnect(
    RSQLite::SQLite(),
    make_target_path("sdm_evaluation_db.sqlite")
)

dbWriteTable(con, "species", species, overwrite = TRUE)
dbWriteTable(con, "models", models, overwrite = TRUE)
dbWriteTable(con, "users", users, overwrite = TRUE)
dbWriteTable(con, "components", components, overwrite = TRUE)

dbWriteTable(con, "materials", materials, overwrite = TRUE)
dbWriteTable(
    con,
    "deployment_materials",
    deployment_materials,
    overwrite = TRUE
)
dbWriteTable(con, "deployments", deployments, overwrite = TRUE)
dbWriteTable(con, "access", access, overwrite = TRUE)

dbWriteTable(con, "comments", comments, overwrite = TRUE)
dbWriteTable(con, "evaluations", evaluations, overwrite = TRUE)

unique(sdmEvalToolCore::fields$table)
dbListTables(con)
dbDisconnect(con)

# the output from this script can be found here:
# https://www.dropbox.com/scl/fi/1khm6hhoosgkjtmldqxg7/base.zip?rlkey=xwywv6s5cgjr0ufrxosxnx95w&dl=0
# we can put this inside the ./misc/base folder and use it as the folder location
# (./misc is git ignored)

# TODO:
# this now has no notion of keys
# need to use SQL when creating the tables to define pk's and fk's
