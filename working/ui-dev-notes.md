# Developer notes for the UI

## Setup for Development mode
- Open Issues -> Display model materials (Task 1) -> https://github.com/LandSciTech/sdmEvaluationTool/issues/1
- Specs README -> https://github.com/LandSciTech/sdmEvaluationTool/blob/main/spec/README.md
- Testing in terminal -> `R -q -e "devtools::load_all(); test_page_observations()"`

## Definitions
- Comments are a page - Option to add a comment to that species/model combination
- Species pages are - Comments, and then the components pages

## App Layout
- page_navbar()
  - sidebar - Overall sidebar `mod_sidebar_ui()` / `mod_sidebar_server()`
  - nav_panel() - Page Modules (e.g., `mod_page_observations_ui()`)
    - sidebar() - *Right-side* sidebar for page-related evaluation questions

## General
- Use Air formatter (use `#fmt: skip` to skip formatting specific sections
- Use bslib for Shiny dashboard 
- Module naming
    - Top level pages `mod_page_<name_.R` - `mod_page_<name>_ui()` and `mod_page_<name>_server()`
    - Components `mod_comp_<component_id>_ui` and `mod_comp_<component_id>_server` (spec/README.md)
- There are some problems when input names have spaces, so always convert to "_" and back as needed (cf values for questions)

## Things to consider
- Use `brand.yml` for theming to allow easy changes? - https://posit-dev.github.io/brand-yml/


## Devtools

- To add a test user to your database:

```
db_write_table(
  db_connect(),
  "users",
  data.frame(
    user_id = "testuser",
    user_name = "Steffi LaZerte",
    user_email = "",
    user_affiliation = "",
    admin = TRUE
  ),
  mode = "insert"
)

db_write_table(
  db_connect(),
  "access",
  data.frame(
    user_id = "testuser",
    deployment_id = "deployment1",
    user_roles = "evaluator"
  ),
  mode = "insert"
)
```