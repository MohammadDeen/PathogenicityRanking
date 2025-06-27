# ===============================================
# PathogenicityRanking Package Testing Script
# ===============================================
# 
# This script provides comprehensive testing for the new ANNOVAR integration
# features. Run each section step-by-step to verify functionality.

library(PathogenicityRanking)
library(dplyr)
library(readr)

# Set working directory to tests folder
setwd("tests")

# ===============================================
# TEST 1: Basic Function Loading
# ===============================================
cat("\n=== TEST 1: Function Loading ===\n")

# Test if all new functions are available
functions_to_test <- c(
  "annotate_with_annovar",
  "filter_missense_variants", 
  "annovar_to_pathogenicity_analysis",
  "check_annovar_setup",
  "create_score_heatmap",
  "create_composite_scatter",
  "create_score_distribution",
  "run_enhanced_analysis"
)

for (func in functions_to_test) {
  if (exists(func)) {
    cat("✅", func, "- LOADED\n")
  } else {
    cat("❌", func, "- NOT FOUND\n")
  }
}

# ===============================================
# TEST 2: ANNOVAR Setup Check (Manual Configuration Required)
# ===============================================
cat("\n=== TEST 2: ANNOVAR Setup Check ===\n")
cat("Please configure your ANNOVAR paths below:\n")

# CONFIGURE THESE PATHS FOR YOUR SYSTEM:
annovar_path <- "/path/to/your/annovar"        # UPDATE THIS PATH
database_path <- "/path/to/your/annovar/humandb"  # UPDATE THIS PATH

cat("Testing with paths:\n")
cat("ANNOVAR path:", annovar_path, "\n")
cat("Database path:", database_path, "\n")

# Uncomment the line below after setting correct paths:
# setup_ok <- check_annovar_setup(annovar_path, database_path)

cat("⚠️  Please update ANNOVAR paths above and uncomment the setup check\n")

# ===============================================
# TEST 3: Enhanced Visualization Functions
# ===============================================
cat("\n=== TEST 3: Enhanced Visualization Functions ===\n")

# Test with the existing test data
test_data_file <- "../vignettes/Test_variants.xlsx"

if (file.exists(test_data_file)) {
  cat("Testing enhanced analysis functions...\n")
  
  tryCatch({
    # Test basic analysis first
    cat("Running basic pathogenicity analysis...\n")
    basic_results <- run_pathogenicity_analysis(
      input_file = test_data_file,
      pdf_output = "test_basic_ranking.pdf",
      png_output = "test_basic_ranking.png",
      show_plot = FALSE
    )
    cat("✅ Basic analysis - PASSED\n")
    
    # Test individual visualization functions
    cat("Testing individual visualization functions...\n")
    
    # Heatmap
    heatmap_plot <- create_score_heatmap(basic_results, "Test Heatmap")
    cat("✅ Heatmap creation - PASSED\n")
    
    # Scatter plot
    scatter_plot <- create_composite_scatter(basic_results, "AlphaMissense", "Test Scatter")
    cat("✅ Scatter plot creation - PASSED\n")
    
    # Distribution plot
    dist_plot <- create_score_distribution(basic_results, title = "Test Distribution")
    cat("✅ Distribution plot creation - PASSED\n")
    
    # Enhanced analysis
    cat("Testing enhanced analysis workflow...\n")
    enhanced_results <- run_enhanced_analysis(
      input_file = test_data_file,
      output_prefix = "test_enhanced",
      create_heatmap = TRUE,
      create_scatter = TRUE,
      create_distribution = TRUE,
      show_plots = FALSE
    )
    cat("✅ Enhanced analysis workflow - PASSED\n")
    
  }, error = function(e) {
    cat("❌ Visualization test failed:", e$message, "\n")
  })
  
} else {
  cat("❌ Test data file not found:", test_data_file, "\n")
  cat("Please ensure Test_variants.xlsx exists in the vignettes folder\n")
}

# ===============================================
# TEST 4: File Format Handling
# ===============================================
cat("\n=== TEST 4: File Format Handling ===\n")

# Test VCF and avinput files (without ANNOVAR for now)
test_files <- c(
  "test_data/sample_variants.vcf",
  "test_data/sample_variants.avinput"
)

for (test_file in test_files) {
  if (file.exists(test_file)) {
    cat("✅ Test file exists:", test_file, "\n")
  } else {
    cat("❌ Test file missing:", test_file, "\n")
  }
}

# ===============================================
# TEST 5: Error Handling
# ===============================================
cat("\n=== TEST 5: Error Handling ===\n")

# Test with non-existent file
tryCatch({
  run_pathogenicity_analysis("nonexistent_file.xlsx", "out.pdf", "out.png", show_plot = FALSE)
}, error = function(e) {
  cat("✅ Error handling for missing file - PASSED:", e$message, "\n")
})

# Test ANNOVAR setup with invalid paths
tryCatch({
  check_annovar_setup("/invalid/path", "/invalid/path")
}, error = function(e) {
  cat("✅ Error handling for invalid ANNOVAR paths - PASSED\n")
})

# ===============================================
# TEST 6: Data Quality Checks
# ===============================================
cat("\n=== TEST 6: Data Quality Checks ===\n")

if (file.exists(test_data_file)) {
  # Load test data and check structure
  test_data <- readxl::read_excel(test_data_file)
  
  required_cols <- c("AAChange.refGeneWithVer", "AlphaMissense_score", "CADD_phred", 
                     "GERP++_RS", "phyloP17way_primate", "MPC_score", "REVEL_score", "MetaSVM_score")
  
  present_cols <- intersect(required_cols, colnames(test_data))
  missing_cols <- setdiff(required_cols, colnames(test_data))
  
  cat("Required columns present:", length(present_cols), "/", length(required_cols), "\n")
  if (length(missing_cols) > 0) {
    cat("Missing columns:", paste(missing_cols, collapse = ", "), "\n")
  }
  
  # Check data completeness
  completeness <- test_data %>%
    summarise(across(all_of(present_cols), ~sum(!is.na(.)) / n() * 100))
  
  cat("Data completeness by column:\n")
  for (col in names(completeness)) {
    cat(sprintf("  %s: %.1f%%\n", col, completeness[[col]]))
  }
}

# ===============================================
# SUMMARY
# ===============================================
cat("\n=== TESTING SUMMARY ===\n")
cat("✅ Complete this checklist before merging to main:\n")
cat("  □ All functions load without errors\n")
cat("  □ ANNOVAR setup check works with valid paths\n")
cat("  □ Enhanced visualization functions work\n")
cat("  □ File format handling is correct\n")
cat("  □ Error handling works as expected\n")
cat("  □ Data quality checks pass\n")
cat("  □ Real ANNOVAR annotation workflow tested\n")
cat("  □ Package builds without warnings\n")
cat("  □ Documentation is complete and accurate\n")

cat("\n=== NEXT STEPS ===\n")
cat("1. Configure ANNOVAR paths in this script\n")
cat("2. Test ANNOVAR integration with real data\n")
cat("3. Run R CMD check on the package\n")
cat("4. Test installation from GitHub\n")
cat("5. Verify all examples in documentation work\n")
cat("6. When all tests pass, merge develop to main\n")

cat("\nTesting script completed!\n")
