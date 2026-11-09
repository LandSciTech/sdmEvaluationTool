# sdmEvalToolUp

`sdmEvalToolUp` is the upload-oriented package in the SDM Evaluation Tool
monorepo. It is intended to build on `sdmEvalToolCore` for shared data-model
and file-management functionality, and the `sdmEvalToolUI` for user interface components.

The package is currently a scaffold; it does not yet expose upload
workflows.

## Installation

```r
pak::pak("LandSciTech/sdmEvaluationTool/sdmEvalToolUp")
```

## Development

Document and check the package from the repository root:

```r
devtools::document("sdmEvalToolUp")
rcmdcheck::rcmdcheck("sdmEvalToolUp", args = "--no-manual")
```

See [`RELEASE.R`](../RELEASE.R) for the repository's package release workflow.
