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

- [`docs`](./docs/): Documentation for _evaluators_, _modelers_, and _developers_.
- [`misc`](./misc/): A folder where we keep gitignored files (materials used for testing, etc.)
- [`sdmEvalToolCore`](./sdmEvalToolCore/): R package implementing the SDM Evaluation Tool core functionality
- [`sdmEvalToolUI`](./sdmEvalToolUI/): R package implementing the SDM Evaluation Tool UI modules and Shiny apps
- [`spec`](./spec/): SDM Evaluation Tool specifications.
- [`working`](./working/): Scripts used in the interim.

## Install

Prerequisites:

- [R](https://cran.r-project.org/)
- [Rtools](https://cran.r-project.org/bin/windows/Rtools/) on Windows
- [RStudio Desktop](https://posit.co/download/rstudio-desktop/) or a similar environment of you choosing

Before installation, first create a new RStudio Project where you'll store the 
data required for this tool. To do so, select _File_ > _New Project_. When prompted, select _New Directory_ and _New Project_. Under the field _Directory name_, type in _sdmEvaluationTool_, then, click on the *Browse* button and select a location you'll remember (e.g., `c:/users/user_name/work`).

Use this script in R to install required packages and download/extract the example 
data set (say 'yes' or select the 'All' option to update packages if asked):

```R
source("https://raw.githubusercontent.com/LandSciTech/sdmEvaluationTool/refs/heads/main/setup.R")
```

You can now run the following script:

```R
# load libraries
library(sdmEvalToolCore)
library(sdmEvalToolUI)

# start the app
sdm_tool(user = "testuser")
```

A window should pop-up with the loaded app. Alternatively, you can visit the following link in your browser: <http://localhost:8080>.

If you see an error message `Error: Could not connect to database`,
try setting the right folder with `sdmevaltool_options()`:

```R
# use your path here to point to the right folder
sdmevaltool_options(base = "./sdm_evaluation_results")
```

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

[Apache License 2.0](./LICENSE)

See file headers for additional copyright information.
