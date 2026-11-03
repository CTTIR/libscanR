# Chemometrics module
mod_chemometrics_ui <- function(id) {
  ns <- shiny::NS(id)
  bslib::navset_tab(
    id = ns("tabs"),
    bslib::nav_panel("PCA",
      bslib::layout_sidebar(
        sidebar = bslib::sidebar(
          title = "PCA",
          shiny::numericInput(ns("pca_n"), "Components", value = 5,
                              min = 2, max = 20),
          shiny::textInput(ns("pca_color"), "Color by (column)",
                           value = "tissue"),
          shiny::actionButton(ns("run_pca"), "Run PCA",
                              class = "btn-primary w-100"),
          shiny::uiOutput(ns("pca_state"))
        ),
        bslib::card(bslib::card_header("Scores"),
                    plotly::plotlyOutput(ns("pca_scores"),
                                         height = "400px")),
        bslib::card(bslib::card_header("Scree"),
                    shiny::plotOutput(ns("pca_scree"), height = "250px")),
        bslib::card(bslib::card_header("Loadings (PC1)"),
                    shiny::plotOutput(ns("pca_loadings"), height = "300px"))
      )
    ),
    bslib::nav_panel("PLS-DA",
      bslib::layout_sidebar(
        sidebar = bslib::sidebar(
          title = "PLS-DA",
          shiny::textInput(ns("plsda_col"), "Class column",
                           value = "tissue"),
          shiny::numericInput(ns("plsda_n"), "Components",
                              value = 3, min = 2, max = 20),
          shiny::selectInput(ns("plsda_validation"), "Performance evaluation",
                            choices = c("Cross-validation" = "CV",
                                        "Leave-one-out" = "LOO",
                                        "Training only" = "none"), selected = "CV"),
          shiny::actionButton(ns("run_plsda"), "Train",
                              class = "btn-primary w-100"),
          shiny::helpText("Training performance is optimistic. Cross-validation estimates performance within this dataset; it does not establish clinical validity."),
          shiny::uiOutput(ns("plsda_state"))
        ),
        bslib::card(bslib::card_header("Scores"),
                    shiny::plotOutput(ns("plsda_scores"), height = "400px")),
        bslib::card(bslib::card_header("Confusion matrix"),
                    shiny::plotOutput(ns("plsda_cm"), height = "300px"))
      )
    ),
    bslib::nav_panel("Cluster",
      bslib::layout_sidebar(
        sidebar = bslib::sidebar(
          title = "Clustering",
          shiny::selectInput(ns("cluster_method"), "Method",
                             choices = c("kmeans", "hclust")),
          shiny::sliderInput(ns("cluster_k"), "k", min = 2, max = 15,
                             value = 3),
          shiny::actionButton(ns("run_cluster"), "Run",
                              class = "btn-primary w-100"),
          shiny::uiOutput(ns("cluster_state"))
        ),
        bslib::card(bslib::card_header("Cluster assignments"),
                    DT::DTOutput(ns("cluster_tbl")))
      )
    )
  )
}

mod_chemometrics_server <- function(id, rv) {
  shiny::moduleServer(id, function(input, output, session) {
    pca_status <- shiny::reactiveVal("Ready. Run PCA for the current data.")
    plsda_status <- shiny::reactiveVal("Ready. Train for the current data.")
    cluster_status <- shiny::reactiveVal("Ready. Run clustering for the current data.")
    output$pca_state <- shiny::renderUI(.ls_app_result_status(pca_status(),
      rv$pca_result, "Ready. Run PCA for the current data and settings."))
    output$plsda_state <- shiny::renderUI(.ls_app_result_status(plsda_status(),
      rv$plsda_result, "Ready. Train for the current data and settings."))
    output$cluster_state <- shiny::renderUI(.ls_app_result_status(cluster_status(),
      rv$cluster_result, "Ready. Run clustering for the current data and settings."))
    shiny::observeEvent(list(input$pca_n, rv$raw_data, rv$processed_data), {
      rv$pca_result <- NULL
      pca_status("Ready. Run PCA for the current data and settings.")
    }, ignoreInit = TRUE, priority = 20)
    shiny::observeEvent(list(input$plsda_col, input$plsda_n,
                             input$plsda_validation, rv$raw_data,
                             rv$processed_data), {
      rv$plsda_result <- NULL
      plsda_status("Ready. Train for the current data and settings.")
    }, ignoreInit = TRUE, priority = 20)
    shiny::observeEvent(list(input$cluster_method, input$cluster_k,
                             rv$raw_data, rv$processed_data), {
      rv$cluster_result <- NULL
      cluster_status("Ready. Run clustering for the current data and settings.")
    }, ignoreInit = TRUE, priority = 20)
    shiny::observeEvent(input$run_pca, {
      rv$pca_result <- NULL
      result <- .ls_app_attempt(libscanR::ls_pca(.ls_app_dataset(rv),
        n_components = input$pca_n), pca_status)
      if (result$ok) {
        rv$pca_result <- result$value
        pca_status("Complete. Scores describe the current dataset.")
      }
    })

    output$pca_scores <- plotly::renderPlotly({
      shiny::req(rv$pca_result)
      cb <- input$pca_color
      if (!cb %in% names(rv$pca_result$sample_info)) cb <- NULL
      p <- libscanR::ls_plot_pca(rv$pca_result, color_by = cb)
      plotly::ggplotly(p)
    })
    output$pca_scree <- shiny::renderPlot({
      shiny::req(rv$pca_result)
      libscanR::ls_plot_scree(rv$pca_result)
    }, alt = function() {
      if (is.null(rv$pca_result)) return("No current PCA result.")
      sprintf("PCA scree plot: variance explained by the first %d components of the current dataset.",
              rv$pca_result$n_components)
    })
    output$pca_loadings <- shiny::renderPlot({
      shiny::req(rv$pca_result)
      libscanR::ls_plot_loadings(rv$pca_result, pc = 1, n_top = 5)
    }, alt = "First principal-component loadings against wavelength, with the five strongest loadings labelled.")

    shiny::observeEvent(input$run_plsda, {
      rv$plsda_result <- NULL
      result <- .ls_app_attempt(
        libscanR::ls_plsda(.ls_app_dataset(rv), grouping = input$plsda_col,
                           n_components = input$plsda_n,
                           validation = input$plsda_validation), plsda_status)
      if (result$ok) {
        rv$plsda_result <- result$value
        basis <- switch(result$value$evaluation_basis %||% "unknown",
          cross_validation = "Cross-validation", leave_one_out = "Leave-one-out",
          training = "Training only", "Unspecified evaluation")
        plsda_status(sprintf("Complete. %s accuracy: %.1f%%.", basis,
                             100 * result$value$accuracy))
      }
    })

    output$plsda_scores <- shiny::renderPlot({
      shiny::req(rv$plsda_result)
      libscanR::ls_plot_plsda(rv$plsda_result, type = "scores")
    }, alt = "PLS-DA component scores for the fitted dataset, coloured by its observed classes.")
    output$plsda_cm <- shiny::renderPlot({
      shiny::req(rv$plsda_result)
      libscanR::ls_plot_plsda(rv$plsda_result, type = "confusion")
    }, alt = function() {
      if (is.null(rv$plsda_result)) return("No current PLS-DA result.")
      sprintf("PLS-DA confusion matrix comparing observed and predicted classes. Evaluation basis: %s; accuracy %.1f percent.",
              gsub("_", " ", rv$plsda_result$evaluation_basis %||% "unspecified"),
              100 * rv$plsda_result$accuracy)
    })

    shiny::observeEvent(input$run_cluster, {
      rv$cluster_result <- NULL
      result <- .ls_app_attempt(libscanR::ls_cluster(.ls_app_dataset(rv),
        method = input$cluster_method, k = input$cluster_k), cluster_status)
      if (result$ok) {
        rv$cluster_result <- result$value
        cluster_status("Complete. Cluster labels describe the current dataset.")
      }
    })

    output$cluster_tbl <- DT::renderDT({
      shiny::req(rv$cluster_result)
      df <- data.frame(
        sample_id = rv$cluster_result$sample_info$sample_id,
        cluster = rv$cluster_result$cluster
      )
      DT::datatable(df, options = list(pageLength = 15, dom = "tip"))
    })
  })
}
