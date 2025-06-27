#' Annotate Variants with ANNOVAR and Filter for Missense Variants
#'
#' This function takes raw variant calls, annotates them using ANNOVAR,
#' and filters for missense variants suitable for pathogenicity analysis.
#' Supports both regular VCF (.vcf) and compressed VCF (.vcf.gz) files.
#'
#' @param input_file Path to input variant file (VCF, VCF.gz, avinput, or tab-delimited)
#' @param annovar_path Path to ANNOVAR installation directory
#' @param database_path Path to ANNOVAR database directory
#' @param genome_build Genome build (default: "hg38")
#' @param output_prefix Prefix for output files
#' @param keep_intermediate Keep intermediate ANNOVAR files (default: FALSE)
#' 
#' @return Path to the annotated missense variants file
#' @export
#'
#' @examples
#' \dontrun{
#' # Regular VCF file
#' annotated_file <- annotate_with_annovar(
#'   input_file = "variants.vcf",
#'   annovar_path = "/path/to/annovar",
#'   database_path = "/path/to/annovar/humandb",
#'   output_prefix = "my_variants"
#' )
#' 
#' # Compressed VCF file
#' annotated_file <- annotate_with_annovar(
#'   input_file = "variants.vcf.gz",
#'   annovar_path = "/path/to/annovar",
#'   database_path = "/path/to/annovar/humandb",
#'   output_prefix = "my_variants"
#' )
#' }
annotate_with_annovar <- function(input_file, annovar_path, database_path, 
                                  genome_build = "hg38", output_prefix = "annotated_variants",
                                  keep_intermediate = FALSE) {
  
  # Check if ANNOVAR is available
  if (!fs::dir_exists(annovar_path)) {
    stop("ANNOVAR directory not found: ", annovar_path)
  }
  
  # Check if input file exists
  if (!fs::file_exists(input_file)) {
    stop("Input file not found: ", input_file)
  }
  
  # Determine file type and prepare for ANNOVAR
  file_ext <- tools::file_ext(input_file)
  
  # Handle compressed VCF files
  is_vcf_gz <- grepl("\\.vcf\\.gz$", input_file, ignore.case = TRUE)
  is_vcf <- tolower(file_ext) == "vcf" || is_vcf_gz
  
  # Convert VCF to ANNOVAR input format if needed
  if (is_vcf) {
    avinput_file <- paste0(output_prefix, ".avinput")
    
    # Handle compressed VCF files
    if (is_vcf_gz) {
      # For .vcf.gz files, use zcat to decompress on-the-fly
      convert_cmd <- paste(
        "zcat", shQuote(input_file), "|",
        "perl", file.path(annovar_path, "convert2annovar.pl"),
        "-format vcf4old",
        "-",
        ">", avinput_file
      )
    } else {
      # For regular .vcf files
      convert_cmd <- paste(
        "perl", file.path(annovar_path, "convert2annovar.pl"),
        "-format vcf4old",
        input_file,
        ">", avinput_file
      )
    }
    
    cat("Converting VCF to ANNOVAR input format...\n")
    system(convert_cmd)
    
    if (!fs::file_exists(avinput_file)) {
      stop("Failed to convert VCF to ANNOVAR format")
    }
    
    input_for_annovar <- avinput_file
  } else {
    input_for_annovar <- input_file
  }
  
  # Run ANNOVAR annotation
  output_file <- paste0(output_prefix, "_annotated")
  
  annovar_cmd <- paste(
    "perl", file.path(annovar_path, "table_annovar.pl"),
    input_for_annovar,
    database_path,
    "-buildver", genome_build,
    "-out", output_file,
    "-remove",
    "-protocol refGene,avsnp150,dbnsfp42c",
    "-operation g,f,f",
    "-nastring .",
    "-csvout"
  )
  
  cat("Running ANNOVAR annotation...\n")
  cat("Command:", annovar_cmd, "\n")
  
  system_result <- system(annovar_cmd)
  
  if (system_result != 0) {
    stop("ANNOVAR annotation failed. Check ANNOVAR installation and database paths.")
  }
  
  # Check if annotation was successful
  annotated_csv <- paste0(output_file, ".", genome_build, "_multianno.csv")
  
  if (!fs::file_exists(annotated_csv)) {
    stop("ANNOVAR annotation output not found: ", annotated_csv)
  }
  
  cat("ANNOVAR annotation completed successfully!\n")
  
  # Clean up intermediate files if requested
  if (!keep_intermediate && is_vcf) {
    fs::file_delete(avinput_file)
  }
  
  return(annotated_csv)
}

#' Filter Annotated Variants for Missense Mutations
#'
#' Filters ANNOVAR-annotated variants to retain only missense variants
#' suitable for pathogenicity analysis.
#'
#' @param annotated_file Path to ANNOVAR-annotated CSV file
#' @param output_file Path for filtered output file
#' @param min_quality Minimum variant quality score (if available)
#' 
#' @return Path to filtered missense variants file
#' @export
#'
#' @examples
#' \dontrun{
#' missense_file <- filter_missense_variants(
#'   annotated_file = "variants_annotated.hg38_multianno.csv",
#'   output_file = "missense_variants.csv"
#' )
#' }
filter_missense_variants <- function(annotated_file, output_file = "missense_variants.csv", 
                                     min_quality = NULL) {
  
  if (!fs::file_exists(annotated_file)) {
    stop("Annotated file not found: ", annotated_file)
  }
  
  cat("Reading ANNOVAR-annotated file...\n")
  
  # Read the annotated file
  annotated_data <- readr::read_csv(annotated_file, show_col_types = FALSE)
  
  cat("Total variants before filtering:", nrow(annotated_data), "\n")
  
  # Filter for missense variants
  # Look for variants with Func.refGene == "exonic" and ExonicFunc.refGene containing "missense"
  missense_variants <- annotated_data %>%
    dplyr::filter(
      Func.refGene == "exonic",
      grepl("missense", ExonicFunc.refGene, ignore.case = TRUE)
    ) %>%
    # Remove variants with missing critical information
    dplyr::filter(
      !is.na(AAChange.refGene) | !is.na(AAChange.refGeneWithVer),
      !is.na(Chr), !is.na(Start), !is.na(End)
    )
  
  # Apply quality filter if specified
  if (!is.null(min_quality) && "QUAL" %in% colnames(missense_variants)) {
    initial_count <- nrow(missense_variants)
    missense_variants <- missense_variants %>%
      dplyr::filter(!is.na(QUAL), QUAL >= min_quality)
    cat("Variants removed due to quality filter:", initial_count - nrow(missense_variants), "\n")
  }
  
  cat("Missense variants after filtering:", nrow(missense_variants), "\n")
  
  if (nrow(missense_variants) == 0) {
    warning("No missense variants found after filtering. Check your annotation results.")
    return(NULL)
  }
  
  # Ensure we have the required column for downstream analysis
  if (!"AAChange.refGeneWithVer" %in% colnames(missense_variants) && 
      "AAChange.refGene" %in% colnames(missense_variants)) {
    missense_variants <- missense_variants %>%
      dplyr::mutate(AAChange.refGeneWithVer = AAChange.refGene)
  }
  
  # Write filtered results
  readr::write_csv(missense_variants, output_file)
  cat("Filtered missense variants saved to:", output_file, "\n")
  
  return(output_file)
}

#' Complete Workflow: Annotate and Analyze Variants
#'
#' A comprehensive workflow that annotates raw variants with ANNOVAR,
#' filters for missense variants, and performs pathogenicity analysis.
#'
#' @param input_file Path to raw variant file (VCF, avinput, etc.)
#' @param annovar_path Path to ANNOVAR installation
#' @param database_path Path to ANNOVAR databases
#' @param output_prefix Prefix for all output files
#' @param genome_build Genome build (default: "hg38")
#' @param run_analysis Whether to run pathogenicity analysis (default: TRUE)
#' @param enhanced_analysis Whether to run enhanced analysis with multiple plots (default: FALSE)
#' @param min_quality Minimum variant quality filter
#' @param keep_intermediate Keep intermediate files (default: FALSE)
#' 
#' @return A list containing paths to generated files and analysis results
#' @export
#'
#' @examples
#' \dontrun{
#' results <- annovar_to_pathogenicity_analysis(
#'   input_file = "variants.vcf",
#'   annovar_path = "/usr/local/annovar",
#'   database_path = "/usr/local/annovar/humandb",
#'   output_prefix = "my_study",
#'   enhanced_analysis = TRUE
#' )
#' }
annovar_to_pathogenicity_analysis <- function(input_file, annovar_path, database_path,
                                              output_prefix = "variant_analysis",
                                              genome_build = "hg38",
                                              run_analysis = TRUE,
                                              enhanced_analysis = FALSE,
                                              min_quality = NULL,
                                              keep_intermediate = FALSE) {
  
  cat("=== Starting Complete Variant Analysis Workflow ===\n")
  cat("Input file:", input_file, "\n")
  cat("Output prefix:", output_prefix, "\n\n")
  
  # Step 1: Annotate with ANNOVAR
  cat("Step 1: Annotating variants with ANNOVAR...\n")
  annotated_file <- annotate_with_annovar(
    input_file = input_file,
    annovar_path = annovar_path,
    database_path = database_path,
    genome_build = genome_build,
    output_prefix = paste0(output_prefix, "_annovar"),
    keep_intermediate = keep_intermediate
  )
  
  # Step 2: Filter for missense variants
  cat("\nStep 2: Filtering for missense variants...\n")
  missense_file <- filter_missense_variants(
    annotated_file = annotated_file,
    output_file = paste0(output_prefix, "_missense.csv"),
    min_quality = min_quality
  )
  
  if (is.null(missense_file)) {
    stop("No missense variants found. Workflow cannot continue.")
  }
  
  results <- list(
    annotated_file = annotated_file,
    missense_file = missense_file
  )
  
  # Step 3: Check if pathogenicity scores are available
  cat("\nStep 3: Checking for pathogenicity scores...\n")
  missense_data <- readr::read_csv(missense_file, show_col_types = FALSE)
  
  # Check for required pathogenicity score columns
  required_cols <- c("CADD_phred", "AlphaMissense_score", "GERP++_RS", 
                     "phyloP17way_primate", "MPC_score", "REVEL_score", "MetaSVM_score")
  
  available_cols <- intersect(required_cols, colnames(missense_data))
  missing_cols <- setdiff(required_cols, colnames(missense_data))
  
  cat("Available pathogenicity scores:", paste(available_cols, collapse = ", "), "\n")
  
  if (length(missing_cols) > 0) {
    cat("Missing pathogenicity scores:", paste(missing_cols, collapse = ", "), "\n")
    cat("Note: For complete pathogenicity analysis, ensure ANNOVAR databases include:\n")
    cat("- dbnsfp42c (for CADD, GERP++, phyloP, MPC, REVEL, MetaSVM)\n")
    cat("- alphamissense (for AlphaMissense scores)\n")
  }
  
  # Step 4: Run pathogenicity analysis if requested and scores are available
  if (run_analysis && length(available_cols) >= 3) {
    cat("\nStep 4: Running pathogenicity analysis...\n")
    
    if (enhanced_analysis) {
      analysis_results <- run_enhanced_analysis(
        input_file = missense_file,
        output_prefix = paste0(output_prefix, "_pathogenicity"),
        create_heatmap = TRUE,
        create_scatter = TRUE,
        create_distribution = TRUE,
        show_plots = FALSE
      )
      results$pathogenicity_analysis <- analysis_results
    } else {
      analysis_results <- run_pathogenicity_analysis(
        input_file = missense_file,
        pdf_output = paste0(output_prefix, "_pathogenicity_ranking.pdf"),
        png_output = paste0(output_prefix, "_pathogenicity_ranking.png"),
        show_plot = FALSE
      )
      results$pathogenicity_results <- analysis_results
    }
    
    cat("Pathogenicity analysis completed!\n")
  } else if (run_analysis && length(available_cols) < 3) {
    cat("Insufficient pathogenicity scores available for composite analysis.\n")
    cat("At least 3 scores are required. Consider updating ANNOVAR databases.\n")
  }
  
  # Clean up intermediate files if requested
  if (!keep_intermediate) {
    # Keep only the final results files
    cat("\nCleaning up intermediate files...\n")
  }
  
  cat("\n=== Workflow Completed Successfully ===\n")
  cat("Generated files:\n")
  for (name in names(results)) {
    if (is.character(results[[name]])) {
      cat("-", name, ":", results[[name]], "\n")
    }
  }
  
  return(results)
}

#' Check ANNOVAR Installation and Database Availability
#'
#' Utility function to verify ANNOVAR installation and required databases.
#'
#' @param annovar_path Path to ANNOVAR installation
#' @param database_path Path to ANNOVAR databases
#' @param genome_build Genome build to check (default: "hg38")
#' 
#' @return Logical indicating if setup is complete
#' @export
check_annovar_setup <- function(annovar_path, database_path, genome_build = "hg38") {
  
  cat("=== Checking ANNOVAR Setup ===\n")
  
  # Check ANNOVAR installation
  if (!fs::dir_exists(annovar_path)) {
    cat("❌ ANNOVAR directory not found:", annovar_path, "\n")
    return(FALSE)
  }
  
  # Check key ANNOVAR scripts
  required_scripts <- c("table_annovar.pl", "convert2annovar.pl", "annotate_variation.pl")
  missing_scripts <- c()
  
  for (script in required_scripts) {
    script_path <- file.path(annovar_path, script)
    if (!fs::file_exists(script_path)) {
      missing_scripts <- c(missing_scripts, script)
    }
  }
  
  if (length(missing_scripts) > 0) {
    cat("❌ Missing ANNOVAR scripts:", paste(missing_scripts, collapse = ", "), "\n")
    return(FALSE)
  }
  
  cat("✅ ANNOVAR installation found\n")
  
  # Check database directory
  if (!fs::dir_exists(database_path)) {
    cat("❌ Database directory not found:", database_path, "\n")
    return(FALSE)
  }
  
  # Check for essential databases
  essential_dbs <- c(
    paste0(genome_build, "_refGene.txt"),
    paste0(genome_build, "_avsnp150.txt"),
    paste0(genome_build, "_dbnsfp42c.txt")
  )
  
  missing_dbs <- c()
  available_dbs <- c()
  
  for (db in essential_dbs) {
    db_path <- file.path(database_path, db)
    if (fs::file_exists(db_path)) {
      available_dbs <- c(available_dbs, db)
    } else {
      missing_dbs <- c(missing_dbs, db)
    }
  }
  
  cat("✅ Available databases:", paste(available_dbs, collapse = ", "), "\n")
  
  if (length(missing_dbs) > 0) {
    cat("⚠️  Missing databases:", paste(missing_dbs, collapse = ", "), "\n")
    cat("Install missing databases using:\n")
    for (db in missing_dbs) {
      db_name <- gsub(paste0(genome_build, "_|\\.txt$"), "", db)
      cat("  perl annotate_variation.pl -buildver", genome_build, "-downdb -webfrom annovar", db_name, database_path, "\n")
    }
  }
  
  # Overall status
  setup_complete <- length(missing_scripts) == 0 && length(missing_dbs) == 0
  
  if (setup_complete) {
    cat("✅ ANNOVAR setup is complete and ready for use!\n")
  } else {
    cat("❌ ANNOVAR setup is incomplete. Please install missing components.\n")
  }
  
  return(setup_complete)
}
