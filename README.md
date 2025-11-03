# sdmEvaluationTool

This repo contains R packages, Shiny apps, and documentation that describes
and implements the SDM Evaluation Tool.

- [`misc`](./misc/): A folder where we keep gitignored files (materials used for testing, etc.)
- [`spec`](./spec/): SDM Evaluation Tool specifications.
- [`sdmEvalToolCore`](./sdmEvalToolCore/): R package implementing the SDM Evaluation Tool core functionality
- [`sdmEvalToolUI`](./sdmEvalToolUI/): R package implementing the SDM Evaluation Tool UI and Shiny apps
- [`working`](./working/): Scripts used in the interim.

## Testing

The R packages can be checked locally following the [`RELEASE.R`](./RELEASE.R)
file.

The GitHub Action workflows are triggered when changes are made to files in the
corresponding folders, see YAML files inside the [`.github/workflows`](./.github/workflows/) folder.

## Contributing

See the [`CONTRIBUTING.md`](./CONTRIBUTING.md) file.

## License

TBD
