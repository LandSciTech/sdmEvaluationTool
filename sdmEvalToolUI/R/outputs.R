#' Copy verbatim output
#'
#' Adds a copy button to a verbatim text block..
#'
#' @param id An identifier for the output to copy.
#'
#' @return Invisibly returns the result of the copy operation.
#' @noRd
#' @examples
#' copy_output(id = "output_1")
#'
#' ui <- page_fillable(
#'   theme = sdm_theme(),
#'   h1("copy_output() Test"),
#'   copy_output("test_output_1"),
#'   copy_output("test_output_2")
#' )
#'
#' server <- function(input, output, session) {
#'   output$test_output_1 <- renderText({
#'     "This is sample output 1\nYou can copy this text!"
#'   })
#'
#'   output$test_output_2 <- renderText({
#'     "This is sample output 2\nWith multiple lines\nTry copying it!"
#'   })
#' }
#'
#' shinyApp(ui, server)

copy_output <- function(id) {
  id_copy <- paste0(id, "_copy")

  tagList(
    div(
      style = "position: relative",
      actionButton(
        id_copy,
        label = NULL,
        icon = icon("copy"),
        class = "btn-mini",
        style = "top: 5px; right: 5px; position: absolute;"
      ),
      verbatimTextOutput(id, placeholder = TRUE) |>
        tagAppendAttributes(
          style = "white-space: pre-wrap; word-wrap: break-word;"
        )
    ),
    tags$script(HTML(sprintf(
      "
      $('#%s').on('click', function() {
        var text = $('#%s').text();
        navigator.clipboard.writeText(text);
        $(this).html('<i class=\"fa fa-check\"></i> Copied!');
        setTimeout(() => {
          $(this).html('<i class=\"fa fa-copy\"></i> Copy');
        }, 2000);
      });
    ",
      id_copy,
      id
    )))
  )
}
