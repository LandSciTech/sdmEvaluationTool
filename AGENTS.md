# Repository Guidelines

## Monorepo structure

- This is an R monorepo containing packages, Shiny apps, specifications, and user documentation.
- `sdmEvalToolCore` owns the data model, database and file-management helpers, configuration, and shared data. `sdmEvalToolUI` depends on Core and contains the Shiny modules and app. `sdmEvalToolUp` implements upload-oriented functionality and also depends on Core and UI. Keep that dependency direction.
- `spec/config.yml` is the canonical specification for components, tables, fields, file paths, and related defaults. When it changes, update the packaged configuration and generated data by following `RELEASE.R`.
- `app/` contains an app instance and its deployment data. `misc/` is for local, gitignored test data; `working/` contains interim scripts.

## Development practices

- Follow the package workflow in [`docs/sdm-tool-guide-developers.md`](./docs/sdm-tool-guide-developers.md) and the package-specific sequence in [`RELEASE.R`](./RELEASE.R).
- Use the Air R formatter and the existing tidyverse-oriented style: `snake_case`, native pipes (`|>`), concise anonymous functions (`\(x)`), and `.data`/`.env` pronouns for tidy-evaluation ambiguity.
- Keep functions modular and testable. Document functions with roxygen; use `@examplesIf have_data()` for examples needing local data and `@examplesIf interactive()` for interactive examples.
- Follow existing file and function conventions: `mod_` for Shiny modules, `utils_` for utilities, and `test_` for module tests. Use the template modules as patterns before adding a new page or component.
- In Shiny code, use `validate(need(...))` when users need an explanatory message, and `req()` for requirements that do not need user-facing feedback.
- When changing evaluation questions or response handling, account for nested spatial responses and follow-up rules; update `affirmative()` when question semantics change and test with the dummy data helpers in `test_data.R`.

## Configuration and release checks

- For Core changes, update its `DESCRIPTION` version and `NEWS.md`. For specification changes, edit `spec/config.yml`, copy it to `sdmEvalToolCore/inst/config.yml`, and rebuild generated data with `sdmEvalToolCore/data-raw/DATASET.R`.
- For UI changes, update its `DESCRIPTION` version and `NEWS.md`. Run `devtools::test()` and `devtools::run_examples()`; the UI guide notes these are not covered by local/CI package checks because of data-location requirements. Then document and check the package.
- For `sdmEvalToolUp` changes, use the corresponding documentation, check, and example steps in `RELEASE.R`; load Core first where needed.
- Run `devtools::document()` and `rcmdcheck::rcmdcheck()` for the package you changed. Test Shiny modules with their `test_` helpers and exercise the full app with `sdm_tool()` when appropriate.
- The root [`README.md`](./README.md) describes installation, testing, CI workflows, and a Docker-based vanilla-install check.

## Domain behavior and documentation

- Model materials are associated with models and species; deployments select materials and define evaluation settings, questions, access, and optional spatial subunits. Preserve the IDs, relationships, and file layout defined by the spec.
- Evaluators can save, abandon, and resume evaluations. Synthesis code must not assume responses from different users have identical row order or that every response is present.
- Keep the relevant guide current when behavior changes: see [`docs/README.md`](./docs/README.md) for the modeler, evaluator, synthesis, developer, and administrator guides.
