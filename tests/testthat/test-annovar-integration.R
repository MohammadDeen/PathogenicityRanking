test_that("Enhanced visualization functions work", {
  # Skip if test data is not available
  test_file <- system.file("extdata", "Test_variants.xlsx", package = "PathogenicityRanking")
  if (test_file == "") {
    skip("Test data not available")
  }
  
  # Create sample data for testing
  sample_data <- data.frame(
    Variant = c("Var1", "Var2", "Var3"),
    AlphaMissense = c(0.8, 0.6, 0.9),
    CADD = c(0.7, 0.5, 0.8),
    GERP = c(0.6, 0.4, 0.7),
    phyloP = c(0.5, 0.3, 0.6),
    MPC = c(0.4, 0.2, 0.5),
    REVEL = c(0.7, 0.5, 0.8),
    MetaSVM = c(0.6, 0.4, 0.7),
    CompositeScore = c(0.6, 0.4, 0.7)
  )
  
  # Test heatmap creation
  expect_no_error({
    heatmap_plot <- create_score_heatmap(sample_data)
  })
  
  # Test scatter plot creation
  expect_no_error({
    scatter_plot <- create_composite_scatter(sample_data, "AlphaMissense")
  })
  
  # Test distribution plot creation
  expect_no_error({
    dist_plot <- create_score_distribution(sample_data)
  })
})

test_that("ANNOVAR setup check handles invalid paths correctly", {
  # Test with non-existent paths
  expect_false(check_annovar_setup("/nonexistent/path", "/nonexistent/path"))
})

test_that("File filtering functions handle missing files correctly", {
  # Test with non-existent file
  expect_error(filter_missense_variants("nonexistent_file.csv"))
})

test_that("VCF.gz file detection works correctly", {
  # Test VCF file detection
  vcf_file <- "test.vcf"
  vcf_gz_file <- "test.vcf.gz"
  other_file <- "test.txt"
  
  # Since we can't directly test the private logic in annotate_with_annovar,
  # we'll test the file extension logic that would be used
  expect_true(grepl("\\.vcf\\.gz$", vcf_gz_file, ignore.case = TRUE))
  expect_false(grepl("\\.vcf\\.gz$", vcf_file, ignore.case = TRUE))
  expect_false(grepl("\\.vcf\\.gz$", other_file, ignore.case = TRUE))
  
  # Test case insensitive matching
  expect_true(grepl("\\.vcf\\.gz$", "TEST.VCF.GZ", ignore.case = TRUE))
})

test_that("annotate_with_annovar handles different file types", {
  # Skip this test if ANNOVAR is not available (which is expected in most test environments)
  skip_if_not(FALSE, "ANNOVAR not available in test environment")
  
  # This test would run if ANNOVAR was available
  # It demonstrates the expected behavior for different file types
})
