
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

# Basic analysis
results <- run_pathogenicity_analysis(
  input_file = "your_variants.xlsx",
  pdf_output = "pathogenicity_ranking.pdf", 
  png_output = "pathogenicity_ranking.png",
  show_plot = TRUE
)

# Enhanced analysis with multiple visualizations
enhanced_results <- run_enhanced_analysis(
  input_file = "your_variants.xlsx",
  output_prefix = "comprehensive_analysis",
  create_heatmap = TRUE,
  create_scatter = TRUE,
  create_distribution = TRUE
)
```

## ✨ Features

- **Multiple file formats**: CSV, TXT, XLSX support
- **Comprehensive scoring**: Integrates 8 pathogenicity predictors
- **Advanced visualizations**: Bar charts, heatmaps, scatter plots, distributions
- **Flexible analysis**: Basic and enhanced analysis workflows
- **Publication-ready**: High-quality PDF and PNG outputs
- **Real-world examples**: Comprehensive vignette with practical applications

## 📂 Contents

- `PathogenicityRankingProject.Rproj`: RStudio project file
- `run_pathogenicity_analysis.R`: R script defining the function
- `composite_score_results.csv`: Output file generated after running the function (created after first run)
- `variant_pathogenicity_ranking.pdf/png`: Visualization outputs

## 🧪 Available Functions

### Core Functions

#### `run_pathogenicity_analysis()`
Basic pathogenicity analysis with ranking visualization.

| Argument       | Description |
|----------------|-------------|
| `input_file`   | Path to a `.csv`, `.txt`, or `.xlsx` file with variant data |
| `pdf_output`   | Output filename for the PDF plot |
| `png_output`   | Output filename for the PNG plot |
| `show_plot`    | Whether to display the plot in RStudio (default: TRUE) |

#### `run_enhanced_analysis()`
Comprehensive analysis with multiple visualization types.

| Argument       | Description |
|----------------|-------------|
| `input_file`   | Path to variant file |
| `output_prefix` | Prefix for all output files |
| `create_heatmap` | Generate heatmap visualization |
| `create_scatter` | Generate scatter plots |
| `create_distribution` | Generate distribution plot |

### Visualization Functions

- **`create_score_heatmap()`**: Individual score heatmap across predictors
- **`create_composite_scatter()`**: Composite vs individual score relationships  
- **`create_score_distribution()`**: Distribution analysis of composite scores
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