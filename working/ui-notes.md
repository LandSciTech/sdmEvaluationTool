# UI notes

## Materials Upload App

Modelers upload model materials.
Model materials get organized on file server and database.

1. Upload model materials into `./uploads`
2. Validate new upload
3. Organize components inside `./materials` (raster files, data objects)
4. Update database

- Phase 1:
  - database will be a set of files or a single SQLite database
  - results will be in a folder of the local file system
- Phase 2:
  - database will be centralized (PostgreSQL or similar) on a server
  - results will be on file server (best streaming performance for GeoTIFFs)

The config details data formats.

UI: TBD

## Materials Evaluation App

View:

- get an overview of models/species with completion metrics
- view model materials (results) for a single spp/model
- compare multiple species/models

Evaluate:

- evaluate results for a single species/model
- comment of an existing evaluation

Report:

- generate report from results and evaluations for single species/model

Organization of the app:

<https://excalidraw.com/#json=papgRUldcX8fdQISslrsZ,Ra7KDsrGUgwl6j38VgFDMg>

Evaluations are displayed as wells (colored bg) with user name / timestamp
at the bottom.
There are small icons as buttons in the corner that can be clicked to
add or edit a note. Clicking the button opens a modal where
the evaluation can be provided, and a save button.
Once saved, the modal closes and the evaluation area displays the note.

TODO:

Part 1: Peter & Steffi

- develop a summary page (models/species overview)
- develop display modules for each component
- the goal is to display results for the BAM (and ONBBA) project

Part 2: Peter

- upload app

Part 3: Steffi

- develop evaluation modules

Part 4:

- develop reporting modules
- integrate with ODMAP
