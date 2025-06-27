# Testing Guide for PathogenicityRanking Package

## Overview
This document outlines the testing procedures for the PathogenicityRanking package, especially focusing on the new ANNOVAR integration features.

## Testing Checklist

### ✅ Pre-Merge Testing Requirements

Before merging the `develop` branch to `main`, ensure all the following tests pass:

#### 1. **Function Loading Tests**
- [ ] All new functions load without errors
- [ ] Function exports are properly defined in NAMESPACE
- [ ] Dependencies are correctly specified

#### 2. **ANNOVAR Integration Tests**
- [ ] `check_annovar_setup()` works with valid ANNOVAR installation
- [ ] `annotate_with_annovar()` handles VCF and avinput files
- [ ] `filter_missense_variants()` correctly filters missense variants
- [ ] `annovar_to_pathogenicity_analysis()` completes full workflow

#### 3. **Enhanced Visualization Tests**
- [ ] `create_score_heatmap()` generates proper heatmaps
- [ ] `create_composite_scatter()` creates scatter plots
- [ ] `create_score_distribution()` shows score distributions
- [ ] `run_enhanced_analysis()` produces all visualizations

#### 4. **Error Handling Tests**
- [ ] Functions handle missing files gracefully
- [ ] Invalid ANNOVAR paths are detected
- [ ] Missing required columns are reported
- [ ] Quality filters work correctly

#### 5. **Data Quality Tests**
- [ ] Test data contains all required columns
- [ ] Normalization functions work correctly
- [ ] Composite scoring algorithm is accurate
- [ ] Output files are generated in correct formats

## Manual Testing Procedure

### Step 1: Run the Testing Script
```r
# From R console in the package directory
source("test_package.R")
```

### Step 2: Configure ANNOVAR (If Available)
If you have ANNOVAR installed:

1. Edit `test_package.R` 
2. Update the ANNOVAR paths:
   ```r
   annovar_path <- "/your/path/to/annovar"
   database_path <- "/your/path/to/annovar/humandb"
   ```
3. Uncomment the ANNOVAR setup check line
4. Run the test script again

### Step 3: Test with Real Data
1. Prepare a small VCF file with known missense variants
2. Run the complete ANNOVAR workflow:
   ```r
   results <- annovar_to_pathogenicity_analysis(
     input_file = "your_test.vcf",
     annovar_path = "/path/to/annovar",
     database_path = "/path/to/annovar/humandb",
     output_prefix = "test_run"
   )
   ```

### Step 4: Package Quality Check
```bash
# Run R CMD check
chmod +x check_package_quality.sh
./check_package_quality.sh
```

### Step 5: Installation Test
```r
# Test installation from GitHub
devtools::install_github("MohammadDeen/PathogenicityRanking", ref = "develop")
library(PathogenicityRanking)
```

## Unit Testing

Run automated unit tests:
```r
# Install testthat if needed
install.packages("testthat")

# Run tests
testthat::test_dir("tests/testthat")
```

## Performance Testing

For large datasets:
1. Test with >1000 variants
2. Monitor memory usage
3. Check processing time
4. Verify output quality

## Documentation Testing

Verify all examples work:
```r
# Test all documented examples
example(run_pathogenicity_analysis)
example(run_enhanced_analysis)
example(check_annovar_setup)
```

## Common Issues and Solutions

### ANNOVAR Not Found
**Issue**: `check_annovar_setup()` returns FALSE  
**Solution**: 
- Verify ANNOVAR installation path
- Check file permissions
- Ensure required databases are downloaded

### Missing Pathogenicity Scores
**Issue**: Limited scores available after ANNOVAR annotation  
**Solution**:
- Update ANNOVAR databases
- Install dbnsfp42c database
- Check database compatibility with genome build

### Visualization Errors
**Issue**: Plot generation fails  
**Solution**:
- Check data dimensions
- Verify required columns exist
- Ensure ggplot2 dependencies are met

### Memory Issues
**Issue**: Large files cause memory errors  
**Solution**:
- Process files in chunks
- Filter variants early in pipeline
- Increase system memory allocation

## Troubleshooting Commands

```r
# Check package structure
devtools::check()

# Verify dependencies
devtools::check_dependencies()

# Test documentation
devtools::document()

# Build and install locally
devtools::install()
```

## Success Criteria

All tests must pass before merging to main:

1. ✅ **No errors** in R CMD check
2. ✅ **All functions** load and execute correctly  
3. ✅ **Documentation** is complete and accurate
4. ✅ **Examples** run without errors
5. ✅ **Unit tests** pass
6. ✅ **ANNOVAR integration** works (if ANNOVAR available)
7. ✅ **Enhanced visualizations** generate correctly
8. ✅ **Package installs** from GitHub without issues

## Post-Merge Verification

After merging to main:

1. Test installation from main branch
2. Verify GitHub Actions CI passes
3. Check that documentation renders correctly
4. Confirm all badges are working
5. Test the complete user workflow from README

---

**Note**: This testing framework ensures the stability and reliability of the PathogenicityRanking package before public release.
