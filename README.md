# sdmEvaluationTool

```text
███████╗██████╗ ███╗   ███╗    ████████╗ ██████╗  ██████╗ ██╗     
██╔════╝██╔══██╗████╗ ████║    ╚══██╔══╝██╔═══██╗██╔═══██╗██║     
███████╗██║  ██║██╔████╔██║       ██║   ██║   ██║██║   ██║██║     
╚════██║██║  ██║██║╚██╔╝██║       ██║   ██║   ██║██║   ██║██║     
███████║██████╔╝██║ ╚═╝ ██║       ██║   ╚██████╔╝╚██████╔╝███████╗
╚══════╝╚═════╝ ╚═╝     ╚═╝       ╚═╝    ╚═════╝  ╚═════╝ ╚══════╝
```

This repo contains R packages, Shiny apps, and documentation that describes
and implements the SDM Evaluation Tool.

- [`misc`](./misc/): A folder where we keep gitignored files (materials used for testing, etc.)
- [`sdmEvalToolCore`](./sdmEvalToolCore/): R package implementing the SDM Evaluation Tool core functionality
- [`sdmEvalToolUI`](./sdmEvalToolUI/): R package implementing the SDM Evaluation Tool UI modules and Shiny apps
- [`spec`](./spec/): SDM Evaluation Tool specifications.
- [`working`](./working/): Scripts used in the interim.

## Install

Before installation, it is advised to set the preferred working directory using
RStudio (Session > Set Working Directory > Choose Directory) or `setwd()`:

```R
setwd("path/to/work/directory")
```

Use this script in R to install required packages and download/extract the example data set:

```R
source("https://raw.githubusercontent.com/LandSciTech/sdmEvaluationTool/refs/heads/main/setup.R")
```

You can now run the following script:

```R
# load libraries
library(sdmEvalToolCore)
library(sdmEvalToolUI)

# use this option if your folders got mixed up
# sdmevaltool_options(base = "./sdm_evaluation_results")

# start the app
sdm_tool()
```

Lastly, visit the following link in your browser: <http://localhost:8080>

If you see an error message `Error: Could not connect to database`,
try setting the right folder with `sdmevaltool_options()` as shown above.

## Testing

The R packages can be checked locally following the [`RELEASE.R`](./RELEASE.R)
file.

The GitHub Action workflows are triggered when changes are made to files in the
corresponding folders, see YAML files inside the [`.github/workflows`](./.github/workflows/) folder.

To test a vanilla install of the packages, use [Docker](https://docs.docker.com/get-started/introduction/get-docker-desktop/):

```bash
# build the image
docker build -t sdmevaltool:v1 .

# run the image
docker run -p 8080:8080 sdmevaltool:v1
```

Visit <http://localhost:8080>.

## Contributing

See the [`CONTRIBUTING.md`](./CONTRIBUTING.md) file.

## License

TBD
