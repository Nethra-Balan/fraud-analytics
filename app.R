library(shiny)
library(dplyr)
library(plotly)
library(DT)
source("R/data_prep.R")
source("R/helpers.R")
source("R/plots.R")

data <- load_analysis_data()
quality <- data_quality_report(data)
amount_limits <- range(data$Amount)
time_limits <- range(data$Time)
v_choices <- paste0("V", 1:28)

kpi_card <- function(label, value, class = "") div(class = paste("kpi", class), div(class = "kpi-label", label), div(class = "kpi-value", value))
plot_output <- function(id, height = "310px") plotlyOutput(id, height = height)
static_plot_output <- function(id, height = "310px") plotOutput(id, height = height)
filter_sidebar <- sidebarPanel(
  h4("Investigation controls"),
  p("Filter every dashboard view by transaction amount, timing, class, and V1."),
  sliderInput("amount_range", "Transaction Amount Range", min = amount_limits[1], max = amount_limits[2], value = amount_limits, step = 1, pre = "$"),
  sliderInput("time_range", "Time Range", min = time_limits[1], max = time_limits[2], value = time_limits, step = 1),
  checkboxGroupInput("class_filter", "Fraud / Genuine", choices = c("Genuine", "Fraud"), selected = c("Genuine", "Fraud")),
  sliderInput("v_range", "Additional numeric filter: V1", min = min(data$V1), max = max(data$V1), value = range(data$V1), step = .1),
  selectInput("v_variable", "Additional analysis variable", choices = v_choices, selected = "V1"),
  width = 3
)

ui <- fluidPage(
  includeCSS("www/custom.css"),
  div(class = "app-shell",
    div(class = "app-header", div(div(class = "eyebrow", "Financial intelligence | Use case 4"), h1("Fraud Analytics Command Center"), p(class = "subtitle", "Evidence-led exploration of transaction amount, timing, and observed fraud in the ULB / Worldline credit card dataset.")), div(class = "header-note", "Real dataset: 284,807 transactions", br(), "Class 1 = Fraud  |  Class 0 = Genuine")),
    sidebarLayout(
      filter_sidebar,
      mainPanel(tabsetPanel(id = "tabs",
      tabPanel("Executive Overview", br(),
        uiOutput("overview_finding"),
        uiOutput("overview_kpis"),
        fluidRow(column(6, div(class = "viz-card", h4("Fraud vs genuine"), static_plot_output("overview_bar"))), column(6, div(class = "viz-card", h4("Transaction amount distribution"), static_plot_output("overview_amount")))),
        div(class = "viz-card", h4("Fraud trend by elapsed time"), static_plot_output("overview_time", "340px"))
      ),
      tabPanel("Detailed Analysis", br(),
        uiOutput("analysis_status"), fluidRow(column(6, div(class = "viz-card", h4("Class volume"), static_plot_output("analysis_bar"))), column(6, div(class = "viz-card", h4("Amount by class"), static_plot_output("analysis_amount")))), div(class = "viz-card", h4("Fraud trend by time"), static_plot_output("analysis_time", "330px")), div(class = "viz-card", h4("Additional analysis"), static_plot_output("analysis_extra", "330px"))
      ),
      tabPanel("Data Explorer", br(),
        uiOutput("explorer_summary"), downloadButton("download_data", "Download filtered CSV", class = "btn-primary"), div(class = "table-wrap", DTOutput("data_table"))
      )
    )))
  )
)

server <- function(input, output, session) {
  selected_data <- reactive({
    amount_range <- if (is.null(input$amount_range)) amount_limits else input$amount_range
    time_range <- if (is.null(input$time_range)) time_limits else input$time_range
    class_filter <- if (is.null(input$class_filter)) levels(data$ClassLabel) else input$class_filter
    v_range <- if (is.null(input$v_range)) range(data$V1) else input$v_range
    data %>% filter(Amount >= amount_range[1], Amount <= amount_range[2], Time >= time_range[1], Time <= time_range[2], ClassLabel %in% class_filter, V1 >= v_range[1], V1 <= v_range[2])
  })
  explorer_data <- reactive({
    selected_data()
  })
  output$overview_kpis <- renderUI({ s <- filtered_summary(selected_data()); div(class = "kpi-row", kpi_card("Total transactions", fmt_number(s$Transactions)), kpi_card("Fraud transactions", fmt_number(s$Fraud), "fraud"), kpi_card("Fraud rate", fmt_percent(s$FraudRate), "fraud"), kpi_card("Average transaction amount", fmt_currency(s$AverageAmount))) })
  output$overview_finding <- renderUI({
    d <- selected_data()
    if (nrow(d) == 0) return(empty_message())
    class_amounts <- d %>% group_by(ClassLabel) %>% summarise(Count = n(), Average = mean(Amount), .groups = "drop")
    fraud_average <- class_amounts$Average[class_amounts$ClassLabel == "Fraud"]
    genuine_average <- class_amounts$Average[class_amounts$ClassLabel == "Genuine"]
    amount_readout <- if (length(fraud_average) == 1 && length(genuine_average) == 1) paste0("Average observed amount is ", fmt_currency(fraud_average), " for fraud versus ", fmt_currency(genuine_average), " for genuine transactions. ") else "The current view contains one class only. "
    div(class = "finding", strong("Current filtered readout: "), amount_readout, "Fraud represents ", fmt_percent(mean(d$Class == 1L) * 100), " of the ", fmt_number(nrow(d)), " records in view. Accuracy alone can still conceal missed fraud in this imbalanced setting; precision, recall, and F1-score matter for any future classifier evaluation.")
  })
  output$analysis_status <- renderUI({ if (nrow(selected_data()) == 0) empty_message() else div(class = "finding", strong(fmt_number(nrow(selected_data())), " records in view. "), "Use amount, timing, class, and V1 filters to compare the observed populations.") })
  render_static_chart <- function(id, plot_fn) {
    output[[id]] <- renderPlot({
      d <- selected_data()
      validate(need(nrow(d) > 0, "No records match the current filters."))
      plot_fn(d)
    }, res = 96)
  }
  render_static_chart("overview_bar", fraud_bar)
  render_static_chart("overview_amount", amount_hist)
  render_static_chart("overview_time", time_trend)
  render_static_chart("analysis_bar", fraud_bar)
  render_static_chart("analysis_amount", amount_hist)
  render_static_chart("analysis_time", time_trend)
  output$analysis_extra <- renderPlot({
    d <- selected_data()
    validate(need(nrow(d) > 0, "No records match the current filters."))
    v_distribution(d, input$v_variable)
  }, res = 96)
  output$explorer_summary <- renderUI({ s <- filtered_summary(explorer_data()); div(class = "finding", strong(fmt_number(s$Transactions), " transactions displayed. "), "Fraud rate: ", fmt_percent(s$FraudRate), " | Average amount: ", fmt_currency(s$AverageAmount)) })
  output$data_table <- renderDT({ d <- explorer_data(); datatable(d, filter = "top", extensions = "Buttons", options = list(searching = TRUE, ordering = TRUE, paging = TRUE, searchDelay = 0, pageLength = 15, lengthMenu = c(15, 30, 50), scrollX = TRUE, dom = "Blfrtip", buttons = c("copy", "csv")), rownames = FALSE) }, server = TRUE)
  output$download_data <- downloadHandler(filename = function() paste0("filtered-fraud-transactions-", Sys.Date(), ".csv"), content = function(file) safe_download(explorer_data(), file), contentType = "text/csv")
}
shinyApp(ui, server)