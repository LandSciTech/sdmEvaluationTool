validate_db <- function(dbname) {
  validate(
    need(
      file.exists(dbname),
      paste0("Data base cannot be found at ", dbname)
    )
  )
}

#' db connect with check
#'
#' Put the checks here rather than sdmEvalToolCore to avoid Shiny dependency
#' in core package.
#'
#' @param dbname DB name.
#' @param ... Arguments passed to [DBI::dbConnect()].
#'
#' @returns A database connection.
#'
#' @export
db_connect_check <- function(dbname = NULL, ...) {
  dbname <- dbname %||% db_path()
  validate_db(dbname)
  db_connect(dbname)
}

#' Validate input ids
#'
#' @param ... Named arguments containing id values to validate (e.g.,
#' deployment_id, model_id, species_id)
#'
#' @returns NULL (invisibly), or throws validation error if any id is missing
#'
#' @export

validate_ids <- function(...) {
  expand_dots(...)
  nms <- names(list(...))
  n <- purrr::map(nms, \(w) {
    need(get(w), paste("Please select a", fmt_pretty(w)))
  })
  validate(!!!n)
}

#' Test if a reactive is ready
#'
#' Silently catches the reactive error and returns TRUE if no error (ready),
#' FALSE if error (not ready).
#'
#' @param r Shiny reactive.
#'
#' @returns Logical whether the reactive is ready (not erroring) or not
#'
#' @noRd
#' @examples
#' r <- shiny::reactive("I'm ready")
#' shiny::isolate(is_ready(r()))
#' r <- shiny::reactive(stop("I'm not ready"))
#' shiny::isolate(is_ready(r()))

is_ready <- function(r) {
  tryCatch(
    expr = {
      r
      TRUE
    },
    error = \(e) FALSE
  )
}

#' Create reactive vals and keep updated
#'
#' Tracks interactive inputs from map selections. Depending on the origin,
#' namespaced if necessary.
#'
#' Used at the component-level for those using spatial selections.
#'
#' @param input Shiny input object.
#' @param map Character. Map name.
#' @param x Character vector. Names of interactive inputs which are namespaced
#'   to the map, so must be namespaced here.
#' @param js_x Character vector. Names of Javascript created interactive inputs
#'   which do not need to be namespaced.
#'
#' @returns A reactiveValues() list, as well as having the side effect of creating
#'   [observe()] for each value in the list to be independently updated.
#'
#' @export

map_reactive_vals <- function(
  input,
  map,
  x = c(
    "draw_all_features",
    "draw_new_feature",
    "draw_stop",
    "marker_click",
    "shape_click"
  ),
  js_x = c(
    "clear_selection", # From EasyButton created in `base_map()`
    "layers_visible"
  ) # From Layers update function in `base_map()`
) {
  rv <- reactiveValues()

  # Update those Namespaced with the map
  x1 <- paste0(map, "_", x)

  # Join all together
  x <- c(x, js_x)
  x1 <- c(x1, js_x)

  # Create individual observers to update the Reactive Values
  purrr::walk2(x, x1, \(x, x1) {
    observe({
      rv[[x]] <- input[[x1]]
    })
  })
  rv
}

#' Create spinner when loading UI elements
#'
#' @param ui_element Character. UI element name.
#'
#' @returns UI element with spinner.
#'
#' @export

sdm_spinner <- function(ui_element) {
  as_fill_carrier(
    shinycssloaders::withSpinner(
      type = 8,
      color.background = bs_get_variables(sdm_theme(), "primary"),
      ui_element
    )
  )
}

#' SDM tool versions of bslib functions
#'
#' - `sdm_card()` - Wrapper for [bslib::card()], provides defaults for `class`,
#'   `full_screen` and `min_height.`
#' - `sdm_card_header()` - Wrapper for [bslib::card_header()], provides default
#'   custom class (see [sdm_theme()]).
#' - `sdm_nav_panel()` - Wrapper for [bslib::nav_panel()], provides default
#'   custom class (see [sdm_theme()]).
#' - `sdm_layout_sidebar()` - Wrapper for [bslib::layout_sidebar()], provides
#'   defaults for `gap` and `border`.
#'
#' @param ... See bslib function
#' @param class Character vector. HTML classes to add to the card.
#' @param full_screen Logical. Option to make card full screen.
#' @param min_height Numeric. Minimum card height.
#' @param title Character. Nav panel title.
#' @param gap Numeric. Veritical gap between sidebar elements.
#' @param border Logical. Whether or not to add a border.
#'
#' @returns bslib function output
#' @name bslib_wrapper

#' @rdname bslib_wrapper
#' @export
sdm_card <- function(
  ...,
  class = "p-0",
  full_screen = TRUE,
  min_height = 400
) {
  card(
    class = class,
    full_screen = full_screen,
    min_height = min_height,
    ...
  )
}

#' @rdname bslib_wrapper
#' @export
sdm_card_header <- function(..., class = "bg-sdm") {
  card_header(..., class = class)
}

#' Generate tool tip
#'
#' No tooltip if text NULL.
#'
#' @param tooltip_text Character. Text to make into the tooltip
#'   contents.
#' @param trigger Code. Generally HTML tag lists to attach tooltip to.
#'   Defaults to (i) icon.
#'
#' @returns bslib tooltip
#'
#' @export
#' @examples
#' sdm_tooltip("testing")
#' sdm_tooltip(
#'   "testing",
#'   tagList("Hi", bsicons::bs_icon("info-circle", title = "Details"))
#' )

sdm_tooltip <- function(
  tooltip_text,
  trigger = bsicons::bs_icon("info-circle", title = "Details")
) {
  if (!is.null(tooltip_text)) {
    t <- tooltip(trigger, tooltip_text)
  } else {
    t <- NULL
  }

  t
}

#' @rdname bslib_wrapper
#' @export
sdm_nav_panel <- function(title, ..., class = "sdm-tab-pane") {
  nav_panel(title, class = class, ...)
}

#' @rdname bslib_wrapper
#' @export
sdm_layout_sidebar <- function(..., gap = 0, border = FALSE) {
  layout_sidebar(
    gap = gap,
    border = border,
    ...
  )
}
