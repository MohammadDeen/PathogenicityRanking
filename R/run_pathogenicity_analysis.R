
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
    dplyr::select(
      Variant = AAChange.refGeneWithVer,
      AlphaMissense = AlphaMissense_score,
      CADD = CADD_phred,
      GERP = `GERP++_RS`,
      phyloP = phyloP17way_primate,
      MPC = MPC_score,
      REVEL = REVEL_score,
      MetaSVM = MetaSVM_score
    ) %>%
    dplyr::filter(!is.na(AlphaMissense) & !is.na(CADD))

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
