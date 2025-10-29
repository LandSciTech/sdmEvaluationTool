# SDM Model Evaluation Tool (MET)

## Objective

MET that will enable NOBMWG members to:

- evaluate bird SDMs;
- develop methods for synthesizing expert evaluations with quantitative
  evaluations to inform model improvement and application; and
- to assess what more (if anything) is needed to improve the bird SDM
  evaluation process.

MET attributes include:

1.  **Modular**: The MET consists of independent Modules, each handling
    specific functionality. This minimizes duplication of code within
    and among Modules and links Modules into a usable tool.
2.  **Flexible**: The MET code is stored and shared in a GitHub
    repository that allows ECCC and other Tool Maintainers in the NOBMWG
    to add to or modify all components of the MET.
3.  **Expandable**: The MET allows for the possibility of adding new
    Modules created by Tool Maintainers in future.
4.  **Portable**: Tool Maintainers will be able to run the MET locally
    on their computers with minimal changes, and will understand
    possible future server deployment options and procedures.
5.  **Generalizable**: The MET allows for a variety of species, SDM
    model types, and geographies.
6.  **Spatially explicit**: Users will be able to visualize, interact
    with, and provide feedback on multiple raster and vector layers
    (predictions, uncertainty, covariates, etc).
7.  **Open source**: MET code will be released under a suitable open
    source software license that is compatible with the ODMAP v1 project
    dependency.
8.  **Comparative**: Users will be able to view outputs from multiple
    models (e.g., predictions of multiple species), either side by side
    or by toggling among layers, to gain a deeper understanding of model
    outputs.
9.  **Multiple formats**: Users must be able to upload, view and
    interact with Model Materials in a variety of formats (text, tables,
    rasters, vectors).

## Conceptual model

``` mermaid
erDiagram

    models ||--|{ comments : model_id
    species ||--|{ comments : species_id

    uploads }|..|{ materials : upload_id
    style uploads fill:#fff
    components ||--|{ materials : component_id
    style components fill:#ffa
    style materials fill:#ffa

    metadata }|..|{ models : metadata_id
    style metadata fill:#fff

    models ||--|{ materials : model_id
    style models fill:#ffa
    species ||--|{ materials : species_id
    style species fill:#ffa

    deployments ||--|{ materials : deployment_id
    deployments ||--|{ comments : deployment_id
    deployments ||--|{ evaluations : deployment_id
    deployments ||--|{ access : deployment_id
    users ||--|{ access : deployment_id
    style users fill:#ffa


    users ||--o{ materials : user_id
    style users fill:#ffa
    users ||--o{ evaluations : user_id

    evaluations ||--|| materials : evaluation_id
    users ||--o{ comments : user_id
```

## Tables

The table descriptions establish the keys, define field constraints, and
list the required field names. It is possible to have fields in these
tables other than what is listed if the names are unique across tables
(e.g. prefixed with the singular version of the table name).

Table names are lower case (a single plural noun). Field names are snake
case (lower case with underscores as word separator).

### Users (`users`)

This table contains user names and roles to be used as foreign keys in
other tables to track change history. This table needs to be updated
regularly, requires admin access and writing directly to the database.
See the list of user roles for specific permissions.

| field | type | constraint | description |
|:---|:---|:---|:---|
| `user_id` | text | `PRIMARY KEY` | User ID (a unique ID or the email). |
| `user_name` | text | `NOT NULL` | The user’s full name. |
| `user_email` | text | `UNIQUE NOT NULL` | The user’s email address. |
| `user_affiliation` | text | `NOT NULL` | The user’s primary affiliation, e.g. ECCC, BAM, etc. |
| `admin` | boolean | `NOT NULL` | Boolean flag for admin users. |

### Species (`species`)

A table that lists all potential species, in our case, birds in Canada.
This table is saved to the database once, changes to the `species` table
require admin access directly to the database.

| field | type | constraint | description |
|:---|:---|:---|:---|
| `species_id` | text | `PRIMARY KEY` | Upper case 4-letter code, e.g. `OVEN` for Ovenbird. |
| `scientific_name` | text | `UNIQUE NOT NULL` | Scientific name. |
| `english_name` | text | `UNIQUE NOT NULL` | Common name in English. |
| `french_name` | text | `UNIQUE NOT NULL` | Common name in French (use UTF-8 encoding). |

### Models (`models`)

A table listing models. The model name and ID acts as an abbreviation of
the model approach/extent/etc. and also acts as a version identifier,
e.g. `can_glm_v1.1` would mean that GLM models were used for models with
Canadian extent and this is version 1.1. Updates are done via uploading
or creating a method metadata file. This action should be quite
infrequent.

| field | type | constraint | description |
|:---|:---|:---|:---|
| `model_id` | text | `PRIMARY KEY` | Model ID, lower case, alphanumeric, `.` and `_` allowed. |
| `model_name` | text | `UNIQUE NOT NULL` | A human readable version of `model_id` displayed in the app. |
| `model_description` | text | `UNIQUE NOT NULL` | A human readable version of `model_id` displayed in the app. |
| `model_metadata` | text | `UNIQUE NOT NULL` | A file path or URL pointing used to find the ODMAP metadata for the model. |

### Components (`components`)

Components that can be uploaded and evaluated. Each component will have
its Shiny module implementing the expected behavior for upload, display,
and evaluation. e.g. a component can have corresponding
`mod_<component_id>_ui` and `mod_<component_id>_server` module
functions. Mandatory components are prerequisites for starting
evaluations. Updates are done via parsing the `components.yaml` file by
admins. After initial development, versioning and backward compatibility
should be a concern so that previous entries will not break.

| field | type | constraint | description |
|:---|:---|:---|:---|
| `component_id` | text | `PRIMARY KEY` | Component ID, lower case with `_`, also used in Shiny module names. |
| `component_description` | text | `NOT NULL` | Component description. |
| `component_mandatory` | boolean | `NOT NULL` | Is the component mandatory (value is `TRUE`). |

### Materials (`materials`)

Upload materials are used to be displayed and evaluated. Updates to the
file system and the database will be regular as modelers upload new
materials.

| field | type | constraint | description |
|:---|:---|:---|:---|
| `material_id` | text | `PRIMARY KEY` | ID for joining feedback to materials (in the form of `<deployment_id>_<species_id>_<model_id>_<component_id>`). |
| `deployment_id` | text | `REFERENCES deployments` | Deployment ID (foreign key). |
| `model_id` | text | `REFERENCES models` | Model ID (foreign key). |
| `species_id` | text | `REFERENCES species` | Species ID (foreign key). |
| `component_id` | text | `REFERENCES components` | Component ID (foreign key). |
| `material_create_user` | text | `REFERENCES users (user_id)` | User who uploaded the model material (foreign key). |
| `material_create_time` | timestamp | `NOT NULL` | Time of initial upload. |
| `material_modify_user` | text | `REFERENCES users (user_id)` | User who modified the model material (foreign key). |
| `material_modify_time` | timestamp | `NOT NULL` | Time of last modification. |

### Evaluations (`evaluations`)

Evaluations are the basic feedback on the materials. There is no
explicitly defined primary key, sort and filter to find entries to
display. The body has to conform with component display rules which is
not checked by the database and is the job for the UI to enforce.
Display rule for comments are simpler than for evaluations, we consider
text comments. Updates to evaluations will be frequent as evaluators
provide more data.

| field | type | constraint | description |
|:---|:---|:---|:---|
| `material_id` | text | `REFERENCES materials` | Material ID. |
| `deployment_id` | text | `REFERENCES deployments` | Deployment ID (foreign key). |
| `use_cases` | text | `NOT NULL` | Use case applicable to the evaluation, can be selected from a list provided by the modeler as part of the deployment definition. |
| `evaluation_create_user` | text | `REFERENCES users (user_id)` | User who created the initial evaluation (foreign key). |
| `evaluation_create_time` | timestamp | `NOT NULL` | Time of initial the initial evaluation. |
| `evaluation_modify_user` | text | `REFERENCES users (user_id)` | User who last modified (foreign key). |
| `evaluation_modify_time` | timestamp | `NOT NULL` | Time of last modification. |
| `evaluation_body` | json | `NOT NULL` | JSON blob with the evaluation according to component display rules reflecting last modification. |
| `note_create_user` | text | `REFERENCES users (user_id)` | User who created the note. |
| `note_create_time` | timestamp | `NOT NULL` | Time of note creation. |
| `note_body` | json | `NOT NULL` | JSON blob with the note on an evaluation reflecting last modification. |

### Comments (`comments`)

Comments are chat-like exchanges of ideas tied to a model-species
combination, visible to users with discussion roles.

| field | type | constraint | description |
|:---|:---|:---|:---|
| `deployment_id` | text | `REFERENCES deployments` | Deployment ID (foreign key). |
| `model_id` | text | `REFERENCES models` | Model ID (foreign key). |
| `species_id` | text | `REFERENCES species` | Species ID (foreign key). |
| `comment_create_user` | text | `REFERENCES users (user_id)` | User who created the note. |
| `comment_create_time` | timestamp | `NOT NULL` | Time of comment creation. |
| `comment_body` | json | `NOT NULL` | JSON blob with the note on an evaluation reflecting last modification. |

### Deployments (`deployments`)

Deployment is a set of results organized for a specific audience for
evaluation.

| field                    | type | constraint    | description      |
|:-------------------------|:-----|:--------------|:-----------------|
| `deployment_id`          | text | `PRIMARY KEY` | Deployment ID.   |
| `deployment_name`        | text | `NOT NULL`    | Deployment name. |
| `deployment_description` | text | `NOT NULL`    | Deployment name. |

### User Access (`access`)

Describe what access users have for deployments

| field | type | constraint | description |
|:---|:---|:---|:---|
| `user_id` | text | `REFERENCES users` | User ID (foreign key). |
| `deployment_id` | text | `REFERENCES deployments` | Deployment ID (foreign key). |
| `user_roles` | text | `NOT NULL` | A comma separated list of user roles, e.g. `modeler,evaluator`. The default role is `viewer` and is assumed even if not mentioned explicitly (value is null). |

## Users and user roles

Allowed values and access types for user roles:

| Role | Model materials | Evaluations | Discussions |
|----|----|----|----|
| `viewer` | Read | Read | None |
| `commenter` | Read | Read | Read, Write |
| `evaluator` | Read | Read, Write (create new, edit theirs) | Read, Write |
| `modeler` | Read, Write (create new, edit theirs) | Read | Read, Write |
| `admin` | Read, Write (create new, edit all, delete) | Read, Write (create new, edit all, delete) | Read, Write |

The UI will enforce role based access rules.

The `users` table needs to be updated regularly, requires admin access
and writing directly to the database.

The admin role cannot be selected by users when setting up deployment
access roles for other users.

When providing multiple roles to a user, the user will have the union of
privileges associated with those roles.

## Components

The configuration for components outlines the materials upload
expectations. We specify what expect the **inputs** and the **outputs**
to look like. The `path` property tells where to look for the result
from this component.

The display section of the component specification determines what kind
of functionality is required. We have corresponding
`mod_<component_id>_ui` and `mod_<component_id>_server` module functions
to be used in the Shiny app. The placement of the component can also be
determined here, i.e. which page/tab/section it will be displayed.

### Observations (`observations`)

Detections or counts by location and timestamp for a single or multiple
species.

**Mandatory**: Yes

**Input**: Observations are organized as survey events as rows (unique
combinations of location \[longitude/latitude\] and date/time). The
table has the following mandatory fields: latitude, longitude, time, and
method. Latitude and longitude are coordinates as decimal degrees
(EPSG:4326). Time is in a format coercible to POSIX time,
e.g. 2019-06-01 7:21:00 AM. Method is a string denoting the survey
method. Other columns holding the observations should be named using
Species IDs, i.e. 4-letter codes (e.g. OVEN, TEWA, etc.) consistent with
the species list being used. The cell values in the species columns
should be non-negative integers (i.e. 0, 1, 2, … or 0/1) indicating the
detections (\>0) and non-detections of the species during the survey
events. The single-species and multi-species data format are identical
except for the number of species whose data is in the table. The table
can be in csv (make sure that time is formatted properly), rds and
parquet (these latter formats should have time as POSIX).

**Output**: The output is a spatial point data frame with columns: time,
method, and status (coordinates are part of the geometry column).

Output path:
`materials/{model_id}/species/{species_id}/observations.gpkg`

**Display**: Display non-detections (status == 0) detections (status \>
0) in different colors. Show detections by default (green), allow an
option to turn on non-detections (grey). Use circle markers in Leaflet.
We can use unique(method) and year of survey as dropdown filters.
Method, time, status should be part of popup message on click.

### Model Metadata (`model_metadata`)

ODMAP protocol metadata.

**Mandatory**: Yes

**Input**: TBD once we integrate ODMAP into the UI.

**Output**: TBD once we integrate ODMAP into the UI.

Output path: `materials/{model_id}/metadata/model_metadata.parquet`

**Display**: TBD once we integrate ODMAP into the UI.

### Predictor Metadata (`predictor_metadata`)

Predictor metadata.

**Mandatory**: Yes

**Input**: The file should contain the recommended columns but is not
strictly enforced. The table should give information about the
predictors (one predictor per row). The file can be csv, rds, or
parquet. The predictor column should list the short names of the
predictors that match the band names in the predictor raster.

**Output**: A file is written with the listed columns.

Output path:
`materials/{model_id}/predictors/predictor_metadata.parquet`

**Display**: The table is displayed as a reactable table.

### Predictor Raster (`predictor_raster`)

Predictor raster, a multi-band TIF with spatial predictors as bands.

**Mandatory**: No

**Input**: A spatial raster file in tif format where bands are different
spatial predictors. Names of the layers should match the predictor
column in the predictor metadata.

**Output**: The tif file is saved as is.

Output path: `materials/{model_id}/predictors/predictor_raster.tif`

**Display**: A raster map in Leaflet, bands are added as layers and can
be selected from the layers icon of the map.

### Prediction Subunits (`prediction_subunits`)

Spatial polygons defining subunits over the spatial predictions.

**Mandatory**: No

**Input**: A spatial polygons file with geometries and a key called
`subunit_id`. Each deployment can have its own subunits.

**Output**: Same file structure as the input file including subunit IDs
and geometries, saved as a Geopackage

Output path: `deployments/{deployment_id}/subunits.gpkg`

**Display**: The subunits layer is overlaid on top of the spatial
prediction (raster) map.

### Spatial Prediction (`spatial_prediction`)

Expected value as band 1, variation as band 2.

**Mandatory**: Yes

**Input**: A spatial raster in tif format. The 1st band is interpreted
as the distribution layer (abundance, occurrence probability, density)
with non-negative real values. The second layer, if present, is
interpreted as a layer with uncertainty (non-negative values, SE, CoV,
CI or PI width, etc.).

**Output**: The file is saved as is. The metadata will be used to label
the map appropriately (what the units are etc.).

Output path:
`materials/{model_id}/species/{species_id}/spatial_prediction.tif`

**Display**: A raster map in Leaflet, with 2 bands: one for “abundance”
one for “uncertainty”. There is a single-species mode, and a comparison
model. In comparison mode, we use a slider to reveal differences. We
need a dropdown to choose which map to compare against. Same species &
different model, same model & different species.

### Model Summary (`model_summary`)

Model summary including variable importance metrics or coefficients for
predictor variables.

**Mandatory**: Yes

**Input**: A table summarizing the models, usually predictors as rows
(listed in the column called predictor). The multi-species version lists
Species IDs in the column species_id. The predictors should match names
in the predictor metadata. Other columns can be named freely,
e.g. var_importance, coefficient, StdError etc.

**Output**: The input file is filtered for individual species and saved.

Output path:
`materials/{model_id}/species/{species_id}/model_summary.parquet`

**Display**: The table is displayed as a reactable table.

### Model Fit (`model_fit`)

Model fit statistics.

**Mandatory**: Yes

**Input**: A table summarizing the model fit, statistics as rows (listed
in the column called statistic). The multi-species version lists Species
IDs in the column species_id. The value of the fit statistic is in the
column called value. Fit metrics are also listed in the project
metadata.

**Output**: The input file is filtered for individual species and saved.

Output path:
`materials/{model_id}/species/{species_id}/model_fit.parquet`

**Display**: The table is displayed as a reactable table.

## Materials upload

When materials are uploaded, we expect the following sequence of
actions:

1.  Metadata is uploaded or entered, this will allow to identify the
    model
2.  Once the model is identified, we can also upload predictor variable
    info (maps, descriptions)
3.  We can also upload the species information:
    - Spatial predictions (density, coefficient of variation)
    - Observations
    - Model summaries (coefficients, variable importance)
    - Model fit metrics

We are following the model/species nesting order, but the list of
potential species is the same for all models.

Input files can be provided in different formats (csv, rda, parquet,
gpkg). We write flat files in rda or parquet formats because these are
fast to read/write, compact, and type-safe (i.e. preserves dates). It
can also be used to store spatial information for vector layers. Spatial
raster files are saved as multi-band TIF files.

When the info is uploaded, we organize the files inside the
`./materials/` folder the following way:

``` text
./sdm_evaluation_db.sqlite

./materials/<model_id>/
./materials/<model_id>/metadata/model_metadata.csv
./materials/<model_id>/predictors/predictor_metadata.parquet
./materials/<model_id>/predictors/predictor_raster.tif

./materials/<model_id>/species/<species_id>/
./materials/<model_id>/species/<species_id>/observations.parquet
./materials/<model_id>/species/<species_id>/spatial_prediction.tif
./materials/<model_id>/species/<species_id>/model_summary.parquet
./materials/<model_id>/species/<species_id>/model_fit.parquet

./deployments/{deployment_id}/metadata.json
./deployments/{deployment_id}/questions.csv
./deployments/{deployment_id}/subunits.gpkg
```

Model materials are saved after upload, this is also when the database
is updated with the new information.

Questions will have an expected table format, and a csv file can be
uploaded similarly to metadata.

Subunits can be used to make evaluations more specific. In the 1st
phase, we will make sure subunits can be identified (popups, paste ID to
clipboard). In next phase, we will develop more sophisticated ways of
providing subunit level feedback if this is identified as a priority. If
no subunits are provided for a deployment, the subunits will not show.

The evaluations for each material are stored in the SQLite database,
alongside the other tables outlined in the conceptual overview.

## Deployments

For each deployment there is:

- 1 evaluation question table (`questions.csv`),
- 1 evaluation polygon layer (`subunits.gpkg`),
- 1 free form opportunity for modeler to explain the evaluation to the
  evaluators,
- a set of use cases (at least one)
- and whether comments are allowed or not (`metadata.json`).

User access can be set differently for each deployment. I.e. the same
user can function as `modeler,commenter` for one and
`evaluator,commenter` for another.

When making a new deployment, the modeler can select from (1) starting
new materials upload or (2) reusing existing model materials from
previous uploads.

## Future changes to consider

Repeatedly storing some of the materials will not be sustainable. We
will revisit organizing predictor variables independently, this way the
evaluation app will have the ability to link to it. If this is a file
server, we can have static HTML files displaying rasters:

``` bash
./shared/predictors/<predictor_id>/predictor_raster.tif
./shared/predictors/<predictor_id>/index.html
```
