#' Join questions and follow-ups
#'
#' @param q A data frame with questions.
#'
#' @examples
#' q <- sdmEvalToolCore::default_questions
#' q$followup_level[5] <- 3
#' combine_questions(q)
#'
#' @export
combine_questions <- function(q) {
  dq <- sdmEvalToolCore::default_questions
  fq <- sdmEvalToolCore::followup_questions
  comp <- sdmEvalToolCore::components

  if (any(!(q$component %in% comp$component))) {
    stop("Undefined component found in questions table.")
  }

  # no follow-ups
  if (all(q$followup_level < 1)) {
    return(q)
  }

  # follow-ups
  qq <- dq[character(0), ]
  for (i in which(q$followup_level > 0)) {
    l <- q$followup_level[i]
    f <- fq[fq$followup_level <= l, ]
    f$component <- q$component[i]
    f$order <- q$order[i]
    f$part <- f$followup_level+q$part[i] #q$part[i]
    f$metadata_id <- q$metadata_id[i]
    qq <- rbind(qq, f[, colnames(qq)])
    q$followup_level[i] <- 0
  }

  o <- rbind(q, qq)
  o[order(o$component, o$order, o$part, o$followup_level), ]
}
