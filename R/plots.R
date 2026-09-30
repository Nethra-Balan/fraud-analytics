library(ggplot2)
library(dplyr)

plot_theme <- theme_minimal(base_family = "Lato") + theme(plot.title = element_text(face = "bold", size = 14, color = "#17212b"), axis.title = element_text(color = "#53606d"), panel.grid.minor = element_blank(), legend.position = "bottom")
fraud_bar <- function(data) data %>% count(ClassLabel) %>% ggplot(aes(ClassLabel, n, fill = ClassLabel, text = paste("Transactions:", scales::comma(n)))) + geom_col(width = .62) + scale_fill_manual(values = c(Genuine = "#1c8c83", Fraud = "#dc5a4f")) + scale_y_continuous(labels = scales::comma) + labs(title = "Observed transaction mix", x = NULL, y = "Transactions") + plot_theme
amount_hist <- function(data) {
	if (nrow(data) > 20000) { set.seed(42); data <- slice_sample(data, n = 20000) }
	ggplot(data, aes(Amount, fill = ClassLabel)) + geom_histogram(bins = 45, alpha = .78, position = "identity") + scale_fill_manual(values = c(Genuine = "#1c8c83", Fraud = "#dc5a4f")) + scale_x_continuous(labels = scales::dollar_format()) + labs(title = "Transaction amount distribution", x = "Amount", y = "Transactions", fill = NULL) + plot_theme
}
time_trend <- function(data) data %>% mutate(TimeBin = floor(Time / 3600)) %>% count(TimeBin, ClassLabel) %>% ggplot(aes(TimeBin, n, color = ClassLabel, text = paste("Time hour:", TimeBin, "| Transactions:", n))) + geom_line(linewidth = .9) + scale_color_manual(values = c(Genuine = "#1c8c83", Fraud = "#dc5a4f")) + scale_y_continuous(labels = scales::comma) + labs(title = "Transaction volume over elapsed time", x = "Elapsed hour", y = "Transactions", color = NULL) + plot_theme
time_group_rate <- function(data) data %>% group_by(TimeGroup) %>% summarise(Transactions = n(), FraudRate = mean(Class == 1L) * 100, .groups = "drop") %>% ggplot(aes(TimeGroup, FraudRate, fill = TimeGroup, text = paste("Fraud rate:", round(FraudRate, 2), "%"))) + geom_col(width = .65, show.legend = FALSE) + scale_fill_manual(values = c(Night = "#23395d", Morning = "#e6a23c", Afternoon = "#1c8c83", Evening = "#dc5a4f")) + labs(title = "Fraud rate by time of day", x = NULL, y = "Fraud rate (%)") + plot_theme
v_distribution <- function(data, variable) {
	if (nrow(data) > 20000) { set.seed(42); data <- slice_sample(data, n = 20000) }
	ggplot(data, aes(x = .data[[variable]], fill = ClassLabel, text = paste(variable, round(.data[[variable]], 3), "|", ClassLabel))) + geom_density(alpha = .45) + scale_fill_manual(values = c(Genuine = "#1c8c83", Fraud = "#dc5a4f")) + labs(title = paste(variable, "distribution by class"), x = variable, y = "Density", fill = NULL) + plot_theme
}