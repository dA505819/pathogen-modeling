#' @title Predict infection state of pathogens
#' @param ... mlr task objects
#' @template learner
#' @template param_set
#' @template tune_ctrl
#' @template resampling
#' @param prediction_data List of prediction data.frame(s)
#' @param prediction_grid Raster Grid to which the prediction should be mapped to
#' @param desc_resampling Resampling description
#'
#' @details `prediction_data` is a list of Tasks. If the learner ID has a
#'   pathogen in its name, e.g. GAM has, then the prediction will only be done
#'   for this task. Otherwise, prediction will be done for all supplied tasks.

prediction_custom <- function(..., learner, param_set, tune_ctrl, resampling,
                              prediction_data, prediction_grid,
                              desc_resampling) {
  configureMlr(on.learner.error = "warn", on.error.dump = TRUE)

  # browser()
  # # check if a supplied learner has one of the following keywords in its name
  # # if yes, we need to subset `tasks_pred` to the specific task
  # if (any(map_lgl(c("diplodia", "fusarium", "armillaria", "heterobasidion"), ~
  #                 grepl(.x, deparse(substitute(learner)))))) {
  #   str_deparse(substitute(lrn_gam_fusarium_pred))
  #
  #   # subset the specific task
  #   tasks = list(tasks_pred[[which(map_lgl(c("diplodia", "fusarium", "armillaria", "heterobasidion"), ~
  #                                      grepl(.x, deparse(substitute(learner)))))]])
  # } else {
  #   tasks = list(...)
  # }
  tasks <- list(...)

  # unlist if a list of multiple tasks was supplied
  if (any(class(tasks[[1]][[1]]) %in% "Task")) {
    tasks <- unlist(tasks, recursive = FALSE)
  }

  # Tune all models ---------------------------------------------------------

  if (learner$id != "classif.binomial") {
    learner_tuned <- map(tasks, ~ {

      # multicore mode does not work with dranke and mlrMBO
      parallelStop()
      # parallelStart(
      #   mode = "socket", level = "mlrMBO.feval", cpus = 30
      # )
      # parallelStartSocket(cpus = 30L)
      set.seed(12345)
      tuned <- tuneParams(learner,
        task = .x, resampling = resampling,
        par.set = param_set, control = tune_ctrl,
        show.info = TRUE, measure = list(brier)
      )
      # parallelStop()
      return(tuned)
    })
  } else {
    learner_tuned <- learner
  }
  # Train all models ---------------------------------------------------------

  if (learner$id != "classif.binomial") {
    learner_tuned %<>% imap(~ setHyperPars(learner,
      par.vals = learner_tuned[[.y]]$x
    ))
    fit <- map2(learner_tuned, tasks, ~ train(.x, .y))
  } else {
    fit <- map(tasks, ~ train(learner_tuned, .x))
  }

  # Create predictions ---------------------------------------------------

  fit <- map(fit, ~.x)

  # if (fit$learner.model == "xgboost") {
  #   fit <- fit[tasks[[1]]$learner.model$feature_names]
  # }

  predictions <- map(fit, ~ predict(.x, newdata = prediction_data))

  # this object contains the coordinates that we need to attach to the predictions
  prediction_grid <- as(prediction_grid, "SpatialPixelsDataFrame")
  prediction_grid <- st_as_sf(prediction_grid)
  coords <- as.data.frame(st_coordinates(prediction_grid))
  colnames(coords) <- c("x", "y")
  # we need to make sure that the rownames of `coords` mirror the ones from `df_basque `
  rownames(coords) <- rownames(prediction_grid)
  rm(prediction_grid)

  # # Visualize all predictors
  #

  rasters <- imap(predictions, ~ {

    # we join the predictions and coordinates based on the rownames of both objects
    pred_xy_xg <- left_join(rownames_to_column(.x$data),
      rownames_to_column(coords),
      by = "rowname"
    )

    pred_xy_xg <- SpatialPixelsDataFrame(
      points = pred_xy_xg[, c("x", "y")],
      data = as.data.frame(pred_xy_xg[, "prob.1"]),
      proj4string = CRS("+proj=utm +zone=30 +datum=WGS84 +units=m +no_defs")
    )
    names(pred_xy_xg) <- "probability"

    raster_xg <- projectRaster(raster(pred_xy_xg),
      crs = "+proj=longlat +ellps=WGS84 +datum=WGS84 +no_defs "
    )

    dir_create("data/prediction")
    dir_create("data/prediction/raster")

    if (desc_resampling == "spatial/spatial") {
      desc_resampling <- "sp_sp"
    } else if (desc_resampling == "spatial/no tuning") {
      desc_resampling <- "sp_non"
    } else if (desc_resampling == "spatial/non-spatial") {
      desc_resampling <- "sp_nsp"
    } else if (desc_resampling == "non-spatial/non-spatial") {
      desc_resampling <- "nsp_nsp"
    } else if (desc_resampling == "non-spatial/no tuning") {
      desc_resampling <- "nsp_non"
    }

    if (learner$id != "classif.binomial") {
      # write out raster
      writeRaster(raster_xg, glue("data/prediction/raster/prediction-{.x$task.desc$id}-{learner_tuned[[.y]]$id}-{desc_resampling}.tif"),
        overwrite = TRUE
      )
    } else {
      writeRaster(raster_xg, glue("data/prediction/raster/prediction-{.x$task.desc$id}-{learner_tuned$id}-{desc_resampling}.tif"),
        overwrite = TRUE
      )
    }
    return(raster_xg)
  })
  rasters <- set_names(rasters, map_chr(tasks, ~ .x$task.desc$id))
  return(rasters)
}

#' @title Create spatial maps from predicted data
#' @param prediction_raster List of predicted raster layers from
#'   [prediction_custom].
#' @param model_name Algorithm name
#' @param benchmark_object mlr benchmark object containing performance of all
#'   tasks that are present in `prediction_raster`
#' @param Resampling String with the resampling description that should appear
#'   on the map
create_prediction_map <- function(prediction_raster, model_name, benchmark_object,
                                  resampling) {
  if (resampling == "spatial/spatial") {
    resampling_file <- "sp_sp"
  } else if (resampling == "spatial/no tuning") {
    resampling_file <- "sp_non"
  } else if (resampling == "spatial/non-spatial") {
    resampling_file <- "sp_nsp"
  } else if (resampling == "non-spatial/non-spatial") {
    resampling_file <- "nsp_nsp"
  } else if (resampling == "non-spatial/no tuning") {
    resampling_file <- "nsp_non"
  }

  # account for missing armillaria object for xgboost
  if (model_name == "xgboost") {
    prediction_raster[[1]] <- NULL
  }

  out_maps <- imap(prediction_raster, ~ {

    # set info fields for debugging models to NA
    if (is.na(resampling)) {
      score <- NA
    } else {
      score <- getBMRAggrPerformances(benchmark_object, as.df = TRUE) %>%
        dplyr::filter(task.id == .y) %>%
        dplyr::select(brier.test.mean) %>%
        pull()
    }

    plot <- ggplot() +
      annotation_map_tile(zoomin = -1, type = "cartolight", progress = "none") +
      layer_spatial(.x, aes(fill = stat(band1))) +
      # scale_alpha_continuous(na.value = 0) +
      scale_fill_viridis_c(na.value = NA, name = "Probability of\n infection",
                           limits = c(0, 1)) +
      # spatial-aware automagic scale bar
      annotation_scale(location = "tl") +
      # spatial-aware automagic north arrow
      annotation_north_arrow(location = "br", which_north = "true") +
      theme_pubr(legend = "right") +
      theme(
        legend.key.size = unit(2, "line"),
        plot.margin = margin(1.5, 0, 1, 0)
      ) +
      labs(caption = glue(
        "Pathogen: {tools::toTitleCase(.y)}, Algorithm: {toupper(model_name)},",
        " Spatial resolution: 200 m
                          Performance: {round(score, 4)} (Brier), Resampling: {resampling}"
      ))

    return(plot)
  })
}
