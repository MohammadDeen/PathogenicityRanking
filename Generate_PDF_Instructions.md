# Instructions for Generating PDF Documentation

## Option 1: Using RStudio (Recommended)
1. Open RStudio
2. Open the file: PathogenicityRanking_Documentation.Rmd
3. Click the "Knit" button or press Ctrl+Shift+K
4. Select "Knit to PDF"
5. The PDF will be generated in the same directory

## Option 2: Using R Console
```r
# Install required packages if not already installed
if (!requireNamespace("rmarkdown", quietly = TRUE)) {
  install.packages("rmarkdown")
}
if (!requireNamespace("tinytex", quietly = TRUE)) {
  install.packages("tinytex")
  tinytex::install_tinytex()  # For LaTeX support
}

# Render the documentation to PDF
rmarkdown::render("PathogenicityRanking_Documentation.Rmd", output_format = "pdf_document")
```

## Option 3: Using Command Line (if R is in PATH)
```bash
Rscript -e "rmarkdown::render('PathogenicityRanking_Documentation.Rmd', output_format = 'pdf_document')"
```

## Output
The generated PDF will be named: **PathogenicityRanking_Documentation.pdf**

## Requirements
- R (>= 4.0.0)
- rmarkdown package
- tinytex package (for LaTeX/PDF support)
- pandoc (usually comes with RStudio)

## Troubleshooting
If you encounter LaTeX errors, install tinytex:
```r
install.packages("tinytex")
tinytex::install_tinytex()
```
