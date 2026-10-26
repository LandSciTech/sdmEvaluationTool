# Upload UI Design

## Deployment considerations

It is important to consider how the Upload UI will be deployed, locally or on a remote server, independently or combined with the Evaluation UI.

- The Upload UI is launched locally:
  - Its purpose is the provide an interactive way of organizing materials and deployments
  - The files and database need to be deployed for the Evaluation UI
  - This would be an acceptable solution for Shinyapps (Posit Connect) based deployments
    because integration the Evaluation and Upload UIs would be challenging
    (i.e. can't have 2 app routes within the same deployment) **DISCUSSION NEEDED**
- The Upload UI a standalone application and is not integrated with the Evaluation UI:
  - It manages files and database common to both the Upload and Evaluation UIs
  - Suitable for Shiny Server or ShinyProxy based deployments

Certain tables would fall outside the scope of the Upload UI and would need to be 
managed through direct database manipulation.

- Components: this table is governed by the configuration YAML and the Core package
- Species: it is likely easier if the species table is also pre-uploaded to the 
  database and can be downloaded as needed to make sure other related materials 
  reference the correct species IDs
- Users: the users table is probably also best managed through direct database manipulation,
  note that the access table would be part of the Upload UI management scope **DISCUSSION NEEDED**

Configuration changes needed for the Upload UI module 
(the Evaluation UI needs to filter Models and Deployments with an published status):

- `model_status` can take the following values:
  - `draft`: The model and model_materials are in draft status and cannot be used for Deployments but can be edited in the Upload UI
  - `published`: The model and model_materials are published and available for Deployments
  - `archived`: The model and model_materials are archived and no longer available for Deployments
- `deployment_status` can take the following values:
  - `draft`: The deployment is in draft status and cannot be used for Evaluations but can be edited in the Upload UI
  - `published`: The deployment is published and available for Evaluations
  - `archived`: The deployment is archived and no longer available for Evaluations

Access to the Upload UI:

- Users with administrative privileges will have access to the Upload UI and can manage materials, deployments, and related configurations
- Option 1: all admin users have access to all models/deployments and the DB registers who created or modified them
- Option 2: each admin user can only view and manage the models/deployments they have created **DISCUSSION NEEDED**

## UI Layout

### 1. Overview

This page is intended to provide a high-level overview of the models, deployments.
It provides summaries for:

- Models: List the models and their statuses
- Deployments: List the deployments and their statuses


### 2. Model Materials Upload & Settings

Managing status:

- Start a new draft Model
- Edit and existing draft Model
- Publish a draft Model
- Archive a published Model

Different tabs for managing model materials:

- Species ID is NA:
  - Predictor metadata (mandatory): file upload + validation
  - Model metadata (mandatory): file upload
    - Prediction map layer metadata (mandatory): included in metadata
  - Predictor raster (not mandatory): file upload, resampling if too big, basic validation
- Species ID is provided:
  - Observations (mandatory): file upload + validation
  - Model summary (mandatory, should it be? **DISCUSSION NEEDED**): file upload + validation
  - Model fit (mandatory, should it be? **DISCUSSION NEEDED**): file upload + validation
  - Spatial predictions (mandatory): multiple file upload + validation
    - UI need to handle upload for different species
    - List species with existing uploads (re-upload possible?)
    - List species without uploads for easy identification and upload
    - Validate against map layer metadata expectations (i.e. layer ID, resolution, extent)
- Overall validation before publishing:
  - Species with materials must have the same material across all relevant tabs 
    (e.g., spatial prediction, observations, model summary, model fit)
  - Present table summarizing the completeness and consistency of materials for each species and model level materials
    (this table is similar to the Evaluation completeness table)

### 3. Deployment Upload & Settings

Managing status:

- Start a new draft Deployment
- Edit an existing draft Deployment
- Publish a draft Deployment
- Archive a published Deployment

Different tabs for managing deployment materials:

- Deployment settings (mandatory):
  - Use cases
  - Instructions for the deployment (this is currently an app level setting, may need to be customized per deployment)
  - Spatial prediction layers: select the map layers to be displayed for the deployment
- Deployment subunits (not mandatory):
  - Upload custom subunit layer (perform some validation: compare extent with other materials like observations and prediction layers)
  - Or auto generate grid or hexagon subunits (specify resolution or size) consistent with the extent of other materials like observations and prediction layers
- Deployment questions (not mandatory): allow to download default questions table to modify
  - Upload deployment questions file (validate format and content)
  - Or use default questions
- Deployment materials (mandatory):
  - Select model
  - Select available materials and species to be considered for this deployment
  - Default to include all available materials and species
  - Can select only a subset of available materials and species for this deployment
- Overall validation before publishing:
  - Check that mandatory deployment settings, materials, and species selections are complete and consistent

### 4. User Management

This section allows administrative users to manage user accounts and their access privileges within the Upload UI:

- Add new users and assign them appropriate roles and access levels
- Edit existing user information and update their access privileges
- Remove users who no longer require access to the Upload UI
- Manage the access table to control which users have access to specific published deployments as evaluators

