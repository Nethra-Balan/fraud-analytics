# Fraud Analytics Command Center

## Problem statement
Financial fraud is rare but costly. This RShiny dashboard explores the observed transaction patterns in the ULB / Worldline credit card fraud dataset, with emphasis on transaction amount and timing. It is an analytical dashboard, not a fraud prediction model.

## Objectives
- Quantify genuine and fraudulent transactions with reactive KPIs.
- Compare amount and elapsed-time behavior across the two observed classes.
- Provide an interactive, searchable and downloadable data explorer.

## Dataset
This project uses the actual **Credit Card Fraud Detection** dataset from ULB and Worldline: [Kaggle source](https://www.kaggle.com/datasets/mlg-ulb/creditcardfraud). The required file is `data/dataset.csv` and contains `Time`, `V1` through `V28`, `Amount`, and `Class` (0 = Genuine, 1 = Fraud). The source dataset contains 284,807 records and 492 fraud records.

## Data preparation
`R/data_prep.R` imports the CSV with `readr`, verifies the exact expected column names, converts numeric fields and `Class`, and standardizes class labels. Missing rows in required analysis fields are removed. Invalid class values, negative elapsed times, and negative amounts are excluded as impossible values. Duplicate rows are counted in the quality report; no synthetic or sample records are created. Major checks include `str()`, `head()`, `summary()`, `dplyr::glimpse()`, missing-value counts, duplicate counts, numeric validation, and class validation during the preparation workflow.

Derived variables are `ClassLabel`, `TransactionHour`, `TimeGroup`, and ordered `AmountBand`. `ClassLabel` makes the class field readable, while the time and amount groups support business summaries.

## Dashboard architecture
- **Data layer:** CSV import, schema assertion, type conversion and cleaning.
- **Transformation layer:** dplyr-derived fields, grouped summaries and fraud rates.
- **Reactive layer:** shared `reactive()` filters, reactive KPIs, charts, table and download.
- **Visualization layer:** ggplot2 charts wrapped with Plotly tooltips.
- **UI layer:** core Shiny `fluidPage`, `sidebarLayout`, `tabsetPanel`, KPI cards, custom CSS and responsive panels.

## Three-tab structure
1. **Executive Overview:** four KPIs, class mix, amount distribution, elapsed-time trend and a reactive evidence-based readout comparing the current filtered fraud and genuine amount averages and fraud share.
2. **Detailed Analysis:** amount range, elapsed-time range, class, V1 numeric filter, selectable V-variable, four interactive analysis charts, and the business question: “How do transaction amount and transaction timing differ between observed fraudulent and genuine transactions?”
3. **Data Explorer:** filtered DT table with search, sorting, pagination, summary statistics and CSV download.

## KPIs and visualizations
The KPIs are total transactions, fraud transactions, fraud rate, and average transaction amount. The charts cover fraud versus genuine volume, amount distribution, fraud/time trend, fraud rate by time group, and the selected V-variable distribution by class. The dashboard uses clear teal and red distinctions for Genuine and Fraud.

## Interactivity and advanced Shiny features
All analysis outputs update from the shared reactive filter. The application uses `reactive()`, `renderPlotly()` with Plotly tooltips, `validate(need())` for empty selections, reactive `DT::renderDT()`, and `downloadHandler()` for the currently filtered explorer data. Empty filters show a user-friendly message, avoid invalid charts, keep KPI summaries at zero, and export an empty CSV with headers rather than crashing.

Accuracy is insufficient for this highly imbalanced classification problem: a model can label nearly everything genuine and achieve high accuracy while missing fraudulent transactions. Precision, recall and F1-score should therefore be reported when a classifier is eventually evaluated. This dashboard does not claim to perform prediction.

## Installation and running
Install R 4.6.1 or later, then install the packages used by the app if necessary:

```r
install.packages(c("shiny", "dplyr", "tidyr", "ggplot2", "plotly", "DT", "readr", "scales"))
```

From this project directory run:

```text
"C:\Program Files\R\R-4.6.1\bin\Rscript.exe" -e "shiny::runApp('.')"
```

Alternatively open `app.R` in RStudio and select **Run App**.

## Project structure
```text
fraud-analytics/
├── app.R
├── data/dataset.csv
├── R/data_prep.R
├── R/helpers.R
├── R/plots.R
├── www/custom.css
├── screenshots/
└── README.md
```

## Analytical questions
- How does transaction amount differ between classes?
- How does fraud frequency vary across elapsed time and time-of-day groups?
- Why can accuracy mislead when fraud is rare?

## Limitations and future enhancements
The anonymized V fields have no direct business interpretation, the dataset represents one historical collection, and the dashboard is descriptive rather than predictive. Future work could add model evaluation with stratified validation, precision-recall curves, alert-threshold analysis, drift monitoring, and role-based deployment controls.