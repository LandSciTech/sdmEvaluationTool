# usage:
# source("https://raw.githubusercontent.com/LandSciTech/sdmEvaluationTool/refs/heads/main/setup.R")

message("=========================================")
message("   Installing the SDM Evaluation Tool")
message("=========================================")
#message("------ Downloading results --------------")
#download.file(
#  "https://peter.solymos.org/testapi/sdmevaltool/sdm_evaluation_results.zip",
#  "./sdm_evaluation_results.zip",
#  method = "libcurl"
#)
#Note asking people to replace the demo results with the their results causes confusion. Better to start with their results.

message("------ Checking for inputs --------------")
if(file.exists("./sdm_evaluation_results")){
  if(file.exists("./sdm_evaluation_results_old")){
    stop("You already have old results in your sdm_evaluation_results_old folder.
         To proceed, delete or remove sdm_evaluation_results_old then rerun this script.")
  }
  message("-- Moving old results to sdm_evaluation_results_old --")
  file.rename("./sdm_evaluation_results","./sdm_evaluation_results_old")
}

if(!file.exists("./sdm_evaluation_results.zip")){
  stop("Missing sdm_evaluation_results.zip. Download from https://drive.google.com/file/d/12dZ8vpiNuusICc4b1QyREr1NI8HQAM1t/view?usp=drive_link to your project folder.")
}

message("------ Unzipping contents ---------------")
unzip("./sdm_evaluation_results.zip")
message("------ Installing R packages ------------")
if (!requireNamespace("remotes")) {
  install.packages("remotes")
}
remotes::install_github(
  "LandSciTech/sdmEvaluationTool/sdmEvalToolCore",
  dependencies = TRUE
)
remotes::install_github(
  "LandSciTech/sdmEvaluationTool/sdmEvalToolUI",
  dependencies = TRUE
)
message("------ Done! ----------------------------")
message("Try running: `sdmEvalToolUI::sdm_tool(user = \"testuser\")`")
