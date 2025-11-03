# Developer notes for the UI

## Setup for Development mode
- Open Issues -> Display model materials (Task 1) -> https://github.com/LandSciTech/sdmEvaluationTool/issues/1
- Specs README -> https://github.com/LandSciTech/sdmEvaluationTool/blob/main/spec/README.md
- Testing in terminal -> `R -q -e "devtools::load_all(); test_page_observations()"`

## Things to consider

- Use `brand.yml` for theming to allow easy changes? - https://posit-dev.github.io/brand-yml/
- Use Air formatter (use `#fmt: skip` to skip formatting specific sections
- Use bslib for Shiny dashboard 
- Module naming
    - Top level tabs `mod_tab_<name_.R` - `mod_tab_<name>_ui()` and `mod_tab_<name>_server()`
    - Components `mod_<component_id>_ui` and `mod_<component_id>_server` (spec/README.md)
        - TODO: What about `mod_comp_<component_id>`?

## To Do

- Side bar - Deployment / Model / Species
- Overview - Table depends on the role of the viewer
- Comments are a page - Option to add a comment to that species/model combination
- Species pages are - Comments, and then the components pages


## Questions 
- The model level materials should apply to all species. I am thinking of using a set of tags for the components where we can color-code the model and species level components. e.g. [Metadata:blue] [Predictor summary:blue] [Predictions:green] [Model fit:green] (imagine that each if these tags have background color applied). This would also make the table more compact because these could be places in the same single column called Materials.
    - TODO: How would this be more compact? A single cell that lists all the materials finished?

- one column with labels (like 'observations')
