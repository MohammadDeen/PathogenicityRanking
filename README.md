
# PathogenicityRanking

<!-- badges: start -->
[![R-CMD-check](https://github.com/MohammadDeen/PathogenicityRanking/actions/workflows/R-CMD-check.yaml/badge.svg)](https://github.com/MohammadDeen/PathogenicityRanking/actions/workflows/R-CMD-check.yaml)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)
<!-- badges: end -->

An R package for computing composite pathogenicity scores to rank missense variants using multiple predictors like AlphaMissense, CADD, GERP++, and others.

## Installation

You can install the development version from GitHub:

```r
# Install devtools if you haven't already
install.packages("devtools")

# Install PathogenicityRanking
devtools::install_github("MohammadDeen/PathogenicityRanking")
```

## Quick Start

```r
library(PathogenicityRanking)

# Run analysis on your variant file
results <- run_pathogenicity_analysis(
  input_file = "your_variants.xlsx",
  pdf_output = "pathogenicity_ranking.pdf", 
  png_output = "pathogenicity_ranking.png",
  show_plot = TRUE
)
```

This project provides a reusable R function to evaluate and rank missense variants based on a composite pathogenicity score derived from multiple predictors.

## 📂 Contents

- `PathogenicityRankingProject.Rproj`: RStudio project file
- `run_pathogenicity_analysis.R`: R script defining the function
- `composite_score_results.csv`: Output file generated after running the function (created after first run)
- `variant_pathogenicity_ranking.pdf/png`: Visualization outputs

## 🧪 Function Overview

### `run_pathogenicity_analysis(input_file, pdf_output, png_output, show_plot = TRUE)`

| Argument       | Description |
|----------------|-------------|
| `input_file`   | Path to a `.csv`, `.txt`, or `.xlsx` file with variant data |
| `pdf_output`   | Output filename for the PDF plot |
| `png_output`   | Output filename for the PNG plot |
| `show_plot`    | Whether to display the plot in RStudio (default: TRUE) |

### Required Columns in Input File

The input file must contain the following columns:

- `AAChange.refGeneWithVer`
- `AlphaMissense_score`
- `CADD_phred`
- `GERP++_RS`
- `phyloP17way_primate`
- `MPC_score`
- `REVEL_score`
- `MetaSVM_score`

## ✅ Output

- A composite pathogenicity score is calculated and visualized for each variant.
- Results are saved to CSV and plots are saved in both PDF and PNG format.

## ✍️ Author

**Mohammad Deen Hayatu**

---

Feel free to customize the scoring system or add additional predictors as needed.