# read tables

devtools::load_all("sdmEvalToolCore")
sdmevaltool_options(base = "./misc/base") # use the misc folder

lang <- "english"
userid <- "draper"
deploymentid <- "deployment1"
modelid <- "bam_v5_can71"

con <- db_connect()
DBI::dbListTables(con)

# note: components should be pulled from the package
comps <- sdmEvalToolCore::components

userinfo <- db_read_user_info(con, userid, deploymentid)
attr(userinfo, "user_roles")

dm <- db_read_deployment_materials(con, deploymentid)

comms <- db_read_comments(con, deploymentid)
evals <- db_read_evaluations(con, deploymentid)


z <- dplyr::tbl(con, "materials") |> dplyr::collect()
z$material_id
e <- dplyr::tbl(con, "evaluations") |> dplyr::collect()
dm <- dplyr::tbl(con, "deployment_materials") |> dplyr::collect()

DBI::dbDisconnect(con)
