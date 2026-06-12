# devtools::load_all("sdmEvalToolCore")
library(sdmEvalToolCore)

# ----- create --------

con <- db_connect(":memory:")

rs <- DBI::dbSendQuery(con, "PRAGMA foreign_keys = ON;")
DBI::dbClearResult(rs)

db_create_tables(con)

# ----- key constraints ---------

users <- data.frame(
  user_id = c("holden", "draper", "okoye"),
  user_name = c("James Holden", "Bobbie Draper", "Elvi Okoye"),
  user_email = c(
    "jim@rocinante.org",
    "bdraper@mcrn.gov",
    "okoye@rce.com"
  ),
  user_affiliation = c("Rocinante", "MCRN", "RCE"),
  admin = c(TRUE, FALSE, FALSE),
  password = c("pass1", "pass2", "pass3")
)
access <- data.frame(
  user_id = c("holden", "draper", "okoye", "draper", "okoye"),
  deployment_id = c(
    "deployment1",
    "deployment1",
    "deployment1",
    "deployment2",
    "deployment2"
  ),
  user_roles = c(
    "modeler,commenter",
    "evaluator,commenter",
    "evaluator",
    "modeler,commenter",
    "evaluator,commenter"
  )
)
db_write_table(con, "users", users, "insert")

# this should fail: deployments table missing
tmp <- try(db_write_table(con, "access", access, "insert"))
stopifnot(inherits(tmp, "try-error"))

deployments <- data.frame(
  deployment_id = c("deployment1", "deployment2"),
  deployment_name = c("Deployment 1", "Deployment 2"),
  deployment_description = c("Deployment 1.", "Deployment 2."),
  deployment_create_user = c("holden", "draper"),
  deployment_create_time = c(
    timestamp_to(now()),
    timestamp_to(now() + 60 * 60)
  ),
  deployment_settings = c("[]", "[]")
)
# try again
db_write_table(con, "deployments", deployments, "insert")
db_write_table(con, "access", access, "insert")

# --------- update --------------

d <- users[users$user_id == "draper", ]
d$admin <- !d$admin
db_write_table(con, "users", d, "update")
r <- dplyr::tbl(con, "users") |>
  dplyr::filter(user_id == "draper") |>
  dplyr::collect()
stopifnot(d$admin == fromBoolean(r$admin))


d <- data.frame(
  user_id = "draper2",
  user_name = "Bobbie Draper 2",
  user_email = "bdraper2@mcrn.gov",
  user_affiliation = "MCRN",
  admin = FALSE,
  password = "pass2"
)
db_write_table(con, "users", d, "update") # does nothing
r <- dplyr::tbl(con, "users") |>
  dplyr::collect()
stopifnot(all(dim(users) == dim(r)))

db_write_table(con, "users", d, "upsert")
r <- dplyr::tbl(con, "users") |>
  dplyr::collect()
stopifnot(nrow(users) + 1 == nrow(r))

db_disconnect(con)
