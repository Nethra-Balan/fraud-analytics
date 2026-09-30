library(dplyr)

fmt_number <- function(value) format(value, big.mark = ",", scientific = FALSE, trim = TRUE)
fmt_currency <- function(value) paste0("$", format(round(value, 2), big.mark = ",", nsmall = 2, trim = TRUE))
fmt_percent <- function(value) paste0(format(round(value, 2), nsmall = 2, trim = TRUE), "%")
filtered_summary <- function(data) {
  if (nrow(data) == 0) return(tibble(Transactions = 0, Fraud = 0, FraudRate = 0, AverageAmount = 0))
  data %>% summarise(Transactions = n(), Fraud = sum(Class == 1L), FraudRate = mean(Class == 1L) * 100, AverageAmount = mean(Amount))
}
empty_message <- function(text = "No records match the current filters.") shiny::div(class = "empty-state", text)
safe_download <- function(data, path) readr::write_csv(data, path)