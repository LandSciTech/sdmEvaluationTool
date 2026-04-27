# usage:
# source("https://raw.githubusercontent.com/LandSciTech/sdmEvaluationTool/refs/heads/word-refinement/setup_JH.R")

message("=========================================")
message("   Installing the SDM Evaluation Tool")
message("=========================================")
message("------ Downloading results --------------")
if (!requireNamespace("googledrive")) {
  install.packages("googledrive")
}
googledrive::drive_download(
  as_id("12dZ8vpiNuusICc4b1QyREr1NI8HQAM1t"),
  path = "./sdm_evaluation_results.zip",
  overwrite = TRUE
)
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
