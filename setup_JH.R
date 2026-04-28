# usage:
# source("https://raw.githubusercontent.com/LandSciTech/sdmEvaluationTool/refs/heads/word-refinement/setup_JH.R")

message("=========================================")
message("   Installing the SDM Evaluation Tool")
message("=========================================")
#message("------ Downloading results --------------")
#googledrive::drive_download(
#  "https://drive.google.com/file/d/12dZ8vpiNuusICc4b1QyREr1NI8HQAM1t/view?usp=drive_link",
#  path = "./sdm_evaluation_results.zip",
#  overwrite=T
#)

if(file.exists("./sdm_evaluation_results")){
  if(file.exists("./sdm_evaluation_results_old")){
    stop("You already have old results in your sdm_evaluation_results_old folder.
         To proceed, delete or remove sdm_evaluation_results_old then rerun this script.")
  }
  message("-- Moving old results to sdm_evaluation_results_old --")
  file.rename("./sdm_evaluation_results","./sdm_evaluation_results_old")
}

if(!file.exists("./sdm_evaluation_results.zip")){
  stop("Missing sdm_evaluation_results.zip. Download from https://drive.google.com/file/d/12dZ8vpiNuusICc4b1QyREr1NI8HQAM1t/view?usp=drive_link to your project file.")
}

message("------ Unzipping contents ---------------")
unzip("./sdm_evaluation_results.zip")
message("------ Installing R packages ------------")
if (!requireNamespace("remotes")) {
  install.packages("remotes")
}
remotes::install_github(
  "LandSciTech/sdmEvaluationTool/sdmEvalToolCore@word-refinement",
  dependencies = TRUE
)
remotes::install_github(
  "LandSciTech/sdmEvaluationTool/sdmEvalToolUI@word-refinement",
  dependencies = TRUE
)
message("------ Done! ----------------------------")
message("Try running: `sdmEvalToolUI::sdm_tool(user = \"testuser\")`")
