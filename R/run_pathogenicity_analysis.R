#' Run Composite Pathogenicity Analysis on Missense Variants
#'
#' This function reads a variant annotation file (.csv, .txt, or .xlsx),
#' extracts relevant pathogenicity scores, computes normalized values,
#' calculates a composite score, and generates visual output as PDF and PNG.
#'
#' @param input_file Path to the input variant file (.csv, .txt, or .xlsx).
#' @param pdf_output Filename for the output PDF plot.
#' @param png_output Filename for the output PNG plot.
#' @param show_plot Logical. If TRUE, displays the plot in RStudio.
#'
#' @return A data frame with normalized values and composite scores.
#' @export
#'
#' @examples
#' \dontrun{
#' run_pathogenicity_analysis("variants.xlsx", "output.pdf", "output.png")
#' }
run_pathogenicity_analysis <- function(input_file, pdf_output, png_output, show_plot = TRUE) {
  if (!fs::file_exists(input_file)) {
    stop("Input file not found: ", input_file)
  }

  if (grepl("\\.(csv)$", input_file, ignore.case = TRUE)) {
    df <- readr::read_csv(input_file)
  } else if (grepl("\\.(txt)$", input_file, ignore.case = TRUE)) {
    df <- readr::read_delim(input_file, delim = "\t")
  } else if (grepl("\\.(xlsx)$", input_file, ignore.case = TRUE)) {
    df <- readxl::read_excel(input_file)
  } else {
    stop("Unsupported file type. Please use .csv, .txt, or .xlsx.")
  }

  df_selected <- df %>%
    select(
      Variant       = AAChange.refGeneWithVer,
      AlphaMissense = AlphaMissense_score,
      CADD          = CADD_phred,
      GERP          = `GERP++_RS`,
      phyloP        = phyloP17way_primate,
      MPC           = MPC_score,
      REVEL         = REVEL_score,
      MetaSVM       = MetaSVM_score
    ) %>%
    # 1) turn every column (even numeric ones) into character
    # 2) replace "." with NA
    # 3) coerce back to numeric
    mutate(across(-Variant, ~ as.numeric(na_if(as.character(.), ".")))) %>%
    filter(!is.na(AlphaMissense), !is.na(CADD))

  normalize <- function(x) {
    if (all(is.na(x)) || max(x, na.rm = TRUE) == 0) return(x)
    x / max(x, na.rm = TRUE)
  }

  df_norm <- df_selected %>%
    dplyr::mutate(across(-Variant, normalize)) %>%
    dplyr::rowwise() %>%
    dplyr::mutate(CompositeScore = mean(c_across(-Variant), na.rm = TRUE)) %>%
    dplyr::ungroup()

  df_sorted <- df_norm %>% dplyr::arrange(desc(CompositeScore))

  plot_obj <- ggplot2::ggplot(df_sorted,
                              ggplot2::aes(x = CompositeScore, y = stats::reorder(Variant, CompositeScore))) +
    ggplot2::geom_col(fill = "#0072B2") +
    ggplot2::labs(
      title = "Composite Pathogenicity Ranking",
      x = "Composite Score (Normalized)",
      y = "Variant"
    ) +
    ggplot2::theme_minimal(base_size = 14) +
    ggplot2::theme(
      panel.grid.major.y = element_blank(),
      panel.grid.major.x = element_line(color = "grey80"),
      plot.title = element_text(face = "bold")
    )

  if (show_plot) {
    print(plot_obj)
  }

  ggplot2::ggsave(pdf_output, plot = plot_obj, width = 10, height = 6)
  ggplot2::ggsave(png_output, plot = plot_obj, width = 10, height = 6, dpi = 300)

  readr::write_csv(df_sorted, "composite_score_results.csv")

  return(df_sorted)
}

#' Create a Heatmap of Individual Pathogenicity Scores
#'
#' @param data A data frame with normalized pathogenicity scores
#' @param title Plot title
#' @return A ggplot2 heatmap object
#' @export
create_score_heatmap <- function(data, title = "Pathogenicity Score Heatmap") {
  # Prepare data for heatmap
  heatmap_data <- data %>%
    dplyr::select(-CompositeScore) %>%
    tidyr::pivot_longer(cols = -Variant, names_to = "Score_Type", values_to = "Score") %>%
    dplyr::mutate(
      Variant = factor(Variant, levels = rev(data$Variant)),
      Score_Type = factor(Score_Type, levels = c("AlphaMissense", "CADD", "GERP", "phyloP", "MPC", "REVEL", "MetaSVM"))
    )
  
  ggplot2::ggplot(heatmap_data, ggplot2::aes(x = Score_Type, y = Variant, fill = Score)) +
    ggplot2::geom_tile(color = "white", size = 0.1) +
    ggplot2::scale_fill_gradient2(
      low = "#2166ac", mid = "#f7f7f7", high = "#b2182b",
      midpoint = 0.5, name = "Normalized\nScore"
    ) +
    ggplot2::labs(
      title = title,
      x = "Pathogenicity Score Type",
      y = "Variant"
    ) +
    ggplot2::theme_minimal() +
    ggplot2::theme(
      axis.text.x = ggplot2::element_text(angle = 45, hjust = 1),
      axis.text.y = ggplot2::element_text(size = 8),
      plot.title = ggplot2::element_text(face = "bold"),
      panel.grid = ggplot2::element_blank()
    )
}

#' Create a Scatter Plot of Composite Scores vs Individual Scores
#'
#' @param data A data frame with normalized pathogenicity scores
#' @param score_type Which individual score to plot against composite score
#' @param title Plot title
#' @return A ggplot2 scatter plot object
#' @export
create_composite_scatter <- function(data, score_type = "AlphaMissense", title = NULL) {
  if (is.null(title)) {
    title <- paste("Composite Score vs", score_type)
  }
  
  ggplot2::ggplot(data, ggplot2::aes_string(x = score_type, y = "CompositeScore")) +
    ggplot2::geom_point(alpha = 0.7, size = 3, color = "#0072B2") +
    ggplot2::geom_smooth(method = "lm", se = TRUE, color = "#d55e00") +
    ggplot2::labs(
      title = title,
      x = paste("Normalized", score_type, "Score"),
      y = "Composite Score"
    ) +
    ggplot2::theme_minimal() +
    ggplot2::theme(plot.title = ggplot2::element_text(face = "bold"))
}

#' Create a Distribution Plot of Composite Scores
#'
#' @param data A data frame with composite scores
#' @param bins Number of histogram bins
#' @param title Plot title
#' @return A ggplot2 histogram object
#' @export
create_score_distribution <- function(data, bins = 20, title = "Distribution of Composite Scores") {
  ggplot2::ggplot(data, ggplot2::aes(x = CompositeScore)) +
    ggplot2::geom_histogram(bins = bins, fill = "#0072B2", alpha = 0.7, color = "white") +
    ggplot2::geom_vline(
      xintercept = median(data$CompositeScore, na.rm = TRUE),
      color = "#d55e00", linetype = "dashed", size = 1
    ) +
    ggplot2::labs(
      title = title,
      x = "Composite Score",
      y = "Number of Variants",
      caption = "Dashed line shows median score"
    ) +
    ggplot2::theme_minimal() +
    ggplot2::theme(plot.title = ggplot2::element_text(face = "bold"))
}

#' Enhanced Pathogenicity Analysis with Multiple Visualizations
#'
#' @param input_file Path to the input variant file (.csv, .txt, or .xlsx).
#' @param output_prefix Prefix for output files (will add suffixes for different plots)
#' @param create_heatmap Logical. Create heatmap visualization?
#' @param create_scatter Logical. Create scatter plots?
#' @param create_distribution Logical. Create distribution plot?
#' @param show_plots Logical. Display plots in RStudio?
#' @return A list containing the data and all plot objects
#' @export
run_enhanced_analysis <- function(input_file, output_prefix = "pathogenicity_analysis",
                                  create_heatmap = TRUE, create_scatter = TRUE, 
                                  create_distribution = TRUE, show_plots = TRUE) {
  
  # Run basic analysis
  results <- run_pathogenicity_analysis(
    input_file = input_file,
    pdf_output = paste0(output_prefix, "_ranking.pdf"),
    png_output = paste0(output_prefix, "_ranking.png"),
    show_plot = show_plots
  )
  
  plot_list <- list()
  
  # Create heatmap
  if (create_heatmap) {
    heatmap_plot <- create_score_heatmap(results)
    plot_list$heatmap <- heatmap_plot
    
    if (show_plots) print(heatmap_plot)
    
    ggplot2::ggsave(paste0(output_prefix, "_heatmap.pdf"), heatmap_plot, width = 10, height = 8)
    ggplot2::ggsave(paste0(output_prefix, "_heatmap.png"), heatmap_plot, width = 10, height = 8, dpi = 300)
  }
  
  # Create scatter plots
  if (create_scatter) {
    score_types <- c("AlphaMissense", "CADD", "GERP", "REVEL")
    for (score in score_types) {
      scatter_plot <- create_composite_scatter(results, score)
      plot_list[[paste0("scatter_", score)]] <- scatter_plot
      
      if (show_plots) print(scatter_plot)
      
      ggplot2::ggsave(
        paste0(output_prefix, "_scatter_", score, ".pdf"), 
        scatter_plot, width = 8, height = 6
      )
      ggplot2::ggsave(
        paste0(output_prefix, "_scatter_", score, ".png"), 
        scatter_plot, width = 8, height = 6, dpi = 300
      )
    }
  }
  
  # Create distribution plot
  if (create_distribution) {
    dist_plot <- create_score_distribution(results)
    plot_list$distribution <- dist_plot
    
    if (show_plots) print(dist_plot)
    
    ggplot2::ggsave(paste0(output_prefix, "_distribution.pdf"), dist_plot, width = 8, height = 6)
    ggplot2::ggsave(paste0(output_prefix, "_distribution.png"), dist_plot, width = 8, height = 6, dpi = 300)
  }
  
  return(list(
    data = results,
    plots = plot_list
  ))
}
