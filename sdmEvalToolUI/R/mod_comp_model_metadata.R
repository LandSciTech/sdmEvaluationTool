#' Test the Model Metadata Component
#'
#' @param ... Arguments passed to other functions.
#'
#' @returns A Shiny app object
#'
#' @export
#' @examplesIf have_data()
#' test_comp_model_metadata()

test_comp_model_metadata <- function(...) {
    test_comp("mod_comp_model_metadata", use = "model_id", ...)
}

#' Model Metadata Component UI
#'
#' @param id Shiny module ID
#' @param header Header
#'
#' @returns Shiny UI
#'
#' @export
#' @examples
#' mod_comp_model_metadata_ui()
mod_comp_model_metadata_ui <- function(
    id = "comp_model_metadata",
    header = NULL
) {
    sdm_card(
        header,
        "Placeholder for UI elements"
    )
}


mod_comp_model_metadata_server <- function(
    id = "comp_model_metadata",
    model_id
) {
    moduleServer(id, function(input, output, session) {
        stopifnot(is.reactive(model_id))

        model_metadata <- reactive(model_metadata_prep(model_id()))
        output$model_metadata <- leaflet::renderLeaflet({
            model_metadata() |>
                model_metadata_XXXX()
        })
    })
}


#' Display Model Metadata
#'
#' @param model_metadata Object
#'
#' @returns Output
#'
#' @export
#' @examplesIf have_data()
#' skip_eg()
#' # model_metadata_prep("bam_v5_can71") |> model_metadata_XXXX()

model_metadata_XXXX <- function(model_metadata) {
    #TODO: Model metadata display
}

#' Prepare Model Metadata Data
#'
#' @param model_id Character. Model ID
#'
#' @returns Data frame
#'
#' @export
#' @examplesIf have_data()
#' skip_eg()
#' # model_metadata_prep("bam_v5_can71")

model_metadata_prep <- function(model_id) {
    prep_materials("model_metadata", model_id = model_id)
}
