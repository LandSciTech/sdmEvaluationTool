# SDM Evaluation Tool

## Conceptual model

``` mermaid
erDiagram
    uploads }|..|{ materials : upload_id
    style uploads fill:#fff
    metadata }|..|{ models : metadata_id
    style metadata fill:#fff

    models ||--|{ materials : model_id
    style models fill:#ffa
    species ||--|{ materials : species_id
    style species fill:#ffa

    rules ||..|| components : component_id
    style rules fill:#fff
    components ||--|{ materials : component_id
    usecases ||--|{ questions : usecase_id
    style usecases fill:#ffa
    style questions fill:#ffa
    users ||--o{ materials : user_id
    style users fill:#ffa
    users ||--o{ evaluations : user_id

    style components fill:#ffa
    questions ||--|{ evaluations : question_id
    questions ||--|{ components : question_id
    evaluations ||--|| materials : evaluation_id
```

## Tables

The table descriptions establish the keys, define field constraints, and
list the required field names. It is possible to have fields in these
tables other than what is listed if the names are unique across tables
(e.g. prefixed with the singular version of the table name).

Table names are lower case (a single plural noun). Field names are snake
case (lower case with underscores as word separator).

### Usecases (`usecases`)

The table defines use cases defined by the modeler. The evaluators will
provide feedback in the context of the usecase, such as forestry
applications, etc.

| field          | type | constraint    | description   |
|:---------------|:-----|:--------------|:--------------|
| `usecase_id`   | text | `PRIMARY KEY` | Usecase ID.   |
| `usecase_name` | text | `NOT NULL`    | Usecase name. |

### Questions (`questions`)

Questions are defined for each usecase and component combinations. The
default questions are specified in the configuration. These can be
edited by the modeler for a given usecase.

| field           | type | constraint            | description            |
|:----------------|:-----|:----------------------|:-----------------------|
| `question_id`   | text | `PRIMARY KEY`         | Question ID.           |
| `question_body` | json | `NOT NULL`            | Question body as JSON. |
| `usecase_id`    | text | `REFERENCES usecases` | Usecase ID.            |

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
| `user_roles` | text |  | A comma separated list of user roles, e.g. `modeler,evaluator`. The default role is `viewer` and is assumed even if not mentioned explicitly (value is null). |

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
| `material_id` | text | `PRIMARY KEY` | ID for joining feedback to materials (in the form of `<species_id>_<model_id>_<component_id>`). |
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
| `question_id` | text | `REFERENCES questions` | Question ID. |
| `evaluation_create_user` | text | `REFERENCES users (user_id)` | Time of initial evaluation (foreign key). |
| `evaluation_create_time` | timestamp | `NOT NULL` | Time of initial upload. |
| `evaluation_modify_user` | text | `REFERENCES users (user_id)` | User who last modified (foreign key). |
| `evaluation_modify_time` | timestamp | `NOT NULL` | Time of last modification. |
| `evaluation_body` | json | `NOT NULL` | JSON blob with the evaluation according to component display rules reflecting last modification. |
| `comment_create_user` | text | `REFERENCES users (user_id)` | Time of initial evaluation (foreign key). |
| `comment_create_time` | timestamp | `NOT NULL` | Time of initial upload. |
| `comment_modify_user` | text | `REFERENCES users (user_id)` | User who last modified (foreign key). |
| `comment_modify_time` | timestamp | `NOT NULL` | Time of last modification. |
| `comment_body` | json | `NOT NULL` | JSON blob with the comment on an evaluation according to component display rules reflecting last modification. |

## Notes

Allowed values and access types for user roles:

| Role | Model materials | Evaluations |
|----|----|----|
| `viewer` | Read | Read |
| `evaluator` | Read | Read, Write (create new, edit theirs) |
| `modeler` | Read, Write (create new, edit theirs) | Read |
| `admin` | Read, Write (create new, edit all, delete) | Read, Write (create new, edit all, delete) |

This table needs to be updated regularly, requires admin access and
writing directly to the database.

Mandatory components are prerequisites for starting evaluations. After
initial development, versioning and backward compatibility should be a
concern so that previous entries will not break.

FIXME: need to link this to uploads (upload entries, files).

The UI will enforce role based access rules.

Note: the body has to conform with component display rules which is not
checked by the database and is the job for the UI to enforce.

Display rule for comments are simpler than for evaluations, we consider
text comments for now.

Updates to evaluations will be frequent as evaluators provide more data.
Every new entry and edit will be saved with user ID and timestamp when
Save button is clicked after adding the entry.

## Components

### Observations (`observations`)

Detections or counts by location and timestamp for a single or multiple
species.

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

**Input**: TBD once we integrate ODMAP into the UI.

**Output**: TBD once we integrate ODMAP into the UI.

Output path: `materials/{model_id}/model_metadata.parquet`

**Display**: TBD once we integrate ODMAP into the UI.

### Predictor Metadata (`predictor_metadata`)

Predictor metadata.

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

**Input**: A spatial raster file in tif format where bands are different
spatial predictors. Names of the layers should match the predictor
column in the predictor metadata.

**Output**: The tif file is saved as is.

Output path: `materials/{model_id}/predictors/predictor_raster.tif`

**Display**: A raster map in Leaflet, bands are added as layers and can
be selected from the layers icon of the map.

### Spatial Prediction (`spatial_prediction`)

Expected value as band 1, variation as band 2.

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

**Input**: A table summarizing the model fit, statistics as rows (listed
in the column called statistic). The multi-species version lists Species
IDs in the column species_id. The value of the fit statistic is in the
column called value. Fit metrics are also listed in the project
metadata.

**Output**: The input file is filtered for individual species and saved.

Output path:
`materials/{model_id}/species/{species_id}/model_fit.parquet`

**Display**: The table is displayed as a reactable table.

### Model materials upload

Single and multi-species uploads are defined here. We can define what
kind of component it is, e.g. a table, a raster file, etc. What kind of
files are accepted, how to parse multi-species results (i.e. species are
columns, or rows, what columns are expected for tables). The `path`
property tells where to look for the result from this component.

### Display

The display section of the component specification determines what kind
of functionality is required. We have corresponding
`mod_<component_id>_ui` and `mod_<component_id>_server` module functions
to be used in the Shiny app. The placement of the component can also be
determined here, i.e. which page/tab/section it will be displayed.

### Evaluation

This specifies what kind of evaluation is to be implemented for the
component.

FIXME: add more content here.

### Reporting

This specifies how to summarize the component in reports.

FIXME: add more content here.

## Materials upload

When materials are uploaded, we expect the following sequence of
actions:

1.  Metadata is uploaded or entered, this will allow to identify the
    model
2.  Once the model is identified, we can also upload predictor variable
    info (maps, descriptions)
3.  We can also upload the species information:
    - Observations
    - Model summaries (coefficients, variable importance)
    - Spatial predictions (density, coefficient of variation)
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
./materials/<model_id>/
./materials/<model_id>/model_metadata.parquet
./materials/<model_id>/predictors/predictor_metadata.parquet
./materials/<model_id>/predictors/predictor_raster.tif

./materials/<model_id>/species/<species_id>/
./materials/<model_id>/species/<species_id>/observations.parquet
./materials/<model_id>/species/<species_id>/spatial_prediction.tif
./materials/<model_id>/species/<species_id>/model_summary.parquet
./materials/<model_id>/species/<species_id>/model_fit.parquet
```

Model materials are saved after upload, this is also when the database
is updated with the new information.

Questions for the usecases are saved as:

``` text
./materials/<model_id>/usecases/<usecase_id>/questions.parquet
```

## Database and evaluations

The evaluations for each material are stored in a database, alongside
the other tables outlined in the conceptual overview. For the local file
system setup, the database is placed as follows:

``` text
./sdm_evaluation_db.sqlite
```

## TODO

- [x] Make YAML for components
- [ ] Describe single/multi-species upload specs
- [x] Outline mandatory component displays specs
- [ ] Describe a framework for more flexible handling of GoF components
- [ ] Create mock app UI for summary, spp1 landing, etc
