# try to do grids
library(sf)
x <- sf::st_read("misc/base/deployments/deployment1/deployment_subunits.gpkg")

x1 <- st_make_grid(x)
x2 <- st_make_grid(x, square = FALSE)

df <- st_sf(subunit_id = 1:length(x1), geometry = x1)
df <- st_transform(df, 4326)

st_write(
    df,
    "_tmp/test-app/base/deployments/deployment1/deployment_subunits.gpkg",
    delete_dsn = TRUE
)

st_write(
    x,
    "_tmp/test-app/base/deployments/deployment1/deployment_subunits.gpkg",
    delete_dsn = TRUE
)
