library(readr)
library(dplyr)
library(tidyr)

required_columns <- c("Time", paste0("V", 1:28), "Amount", "Class")

load_analysis_data <- function(path = "data/dataset.csv") {
  raw <- read_csv(path, show_col_types = FALSE, progress = FALSE)
  # Required source inspection is captured so the app console stays readable.
  invisible(capture.output(str(raw)))
  invisible(capture.output(print(head(raw))))
  invisible(capture.output(print(summary(raw))))
  invisible(capture.output(dplyr::glimpse(raw)))
  stopifnot(identical(names(raw), required_columns))
  data <- raw %>%
    mutate(
      across(all_of(c("Time", paste0("V", 1:28), "Amount")), as.numeric),
      Class = as.integer(Class),
      ClassLabel = factor(if_else(Class == 1L, "Fraud", "Genuine"), levels = c("Genuine", "Fraud")),
      TransactionHour = floor((Time %% 86400) / 3600),
      TimeGroup = case_when(TransactionHour < 6 ~ "Night", TransactionHour < 12 ~ "Morning", TransactionHour < 18 ~ "Afternoon", TRUE ~ "Evening"),
      AmountBand = cut(Amount, breaks = c(-Inf, 10, 50, 200, 1000, Inf), labels = c("Under $10", "$10-$50", "$50-$200", "$200-$1,000", "Over $1,000"), ordered_result = TRUE)
    ) %>%
    filter(if_all(all_of(c("Time", paste0("V", 1:28), "Amount", "Class")), ~ !is.na(.x))) %>%
    filter(Class %in% c(0L, 1L), Time >= 0, Amount >= 0)
  if (nrow(data) == 0) stop("The dataset contains no valid records after validation.")
  data
}

data_quality_report <- function(data) {
  list(rows = nrow(data), missing_values = sum(is.na(data)), duplicate_rows = sum(duplicated(data)), invalid_class = sum(!data$Class %in% c(0L, 1L)), negative_amounts = sum(data$Amount < 0, na.rm = TRUE), columns = names(data))
}