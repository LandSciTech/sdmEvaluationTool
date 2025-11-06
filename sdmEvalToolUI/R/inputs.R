text_input <- function(...) {
  expand_dots(...)
  textInput(id, label)
}

slider_input <- function(...) {
  expand_dots(...)
  sliderInput(inputId = id, label = label, min = 0, max = 10)
}

gold_standard_input <- function(...) {
  expand_dots(...)
  sliderInput(inputId = id, label = label, min = 0, max = 5, ...)
}
