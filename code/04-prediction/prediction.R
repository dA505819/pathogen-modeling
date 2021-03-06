args_pred = tibble(task = rlang::syms(c("tasks_pred_no_ph",
                                        "tasks_pred_no_ph",
                                        "tasks_pred_no_ph",
                                        "tasks_pred_no_ph",
                                        "tasks_pred_no_ph",

                                        "diplodia_task_dummy_prediction_no_temp",
                                        "diplodia_task_dummy_prediction_no_precip",
                                        "diplodia_task_dummy_prediction_no_hail",
                                        "diplodia_task_dummy_prediction_no_ph",
                                        "diplodia_task_dummy_prediction_no_soil",
                                        "diplodia_task_dummy_prediction_no_lithology",
                                        "diplodia_task_dummy_prediction_no_slope",
                                        "diplodia_task_dummy_prediction_no_pisr",

                                        "diplodia_task_dummy_prediction_no_ph",
                                        "fusarium_task_dummy_prediction_no_ph",
                                        "armillaria_task_dummy_no_ph",
                                        "heterobasidion_task_dummy_no_ph",
                                        "tasks_pred_no_ph")),
                   learner = c("lrn_rf",
                               "lrn_svm",
                               "lrn_xgboost",
                               "lrn_kknn",
                               "lrn_glm",

                               "lrn_rf", # debugging tasks
                               "lrn_rf", # debugging tasks
                               "lrn_rf", # debugging tasks
                               "lrn_rf", # debugging tasks
                               "lrn_rf", # debugging tasks
                               "lrn_rf", # debugging tasks
                               "lrn_rf", # debugging tasks
                               "lrn_rf", # debugging tasks

                               "lrn_gam_diplodia_pred_no_ph",
                               "lrn_gam_fusarium_pred_no_ph",
                               "lrn_gam_armillaria_pred_no_ph",
                               "lrn_gam_heterobasidion_pred_no_ph",
                               "lrn_brt"),
                   resampling = rlang::syms(rep("spcv_inner_fiveF", 18)),
                   param_set = rlang::syms(c("ps_rf",
                                             "ps_svm",
                                             "ps_xgboost",
                                             "ps_kknn",
                                             "NULL",

                                             "ps_rf", # debugging tasks
                                             "ps_rf", # debugging tasks
                                             "ps_rf", # debugging tasks
                                             "ps_rf", # debugging tasks
                                             "ps_rf", # debugging tasks
                                             "ps_rf", # debugging tasks
                                             "ps_rf", # debugging tasks
                                             "ps_rf", # debugging tasks

                                             "ps_gam_diplodia_fusarium_pred",
                                             "ps_gam_diplodia_fusarium_pred",
                                             "ps_gam_armillaria_heterobasidion",
                                             "ps_gam_armillaria_heterobasidion",
                                             "ps_brt")),
                   tune_ctrl = rlang::syms(c("tune_ctrl_rf_100",
                                             "tune_ctrl_svm_100",
                                             "tune_ctrl_xgboost_100",
                                             "tune_ctrl_kknn_100",
                                             "NULL",

                                             "tune_ctrl_rf_100", # debugging tasks
                                             "tune_ctrl_rf_100", # debugging tasks
                                             "tune_ctrl_rf_100", # debugging tasks
                                             "tune_ctrl_rf_100", # debugging tasks
                                             "tune_ctrl_rf_100", # debugging tasks
                                             "tune_ctrl_rf_100", # debugging tasks
                                             "tune_ctrl_rf_100", # debugging tasks
                                             "tune_ctrl_rf_100", # debugging tasks

                                             "tune_ctrl_gam_100_diplodia_fusarium_pred",
                                             "tune_ctrl_gam_100_diplodia_fusarium_pred",
                                             "tune_ctrl_gam_100_armillaria_heterobasidion",
                                             "tune_ctrl_gam_100_armillaria_heterobasidion",
                                             "tune_ctrl_brt_100")),
                   prediction_data = c(rep(rlang::syms("pred_data_no_ph"), 5),

                                       rlang::syms("pred_data_no_temp"),
                                       rlang::syms("pred_data_no_precip"),
                                       rlang::syms("pred_data_no_hail"),
                                       rlang::syms("pred_data_no_ph"),
                                       rlang::syms("pred_data_no_soil"),
                                       rlang::syms("pred_data_no_lithology"),
                                       rlang::syms("pred_data_no_slope"),
                                       rlang::syms("pred_data_no_pisr"),

                                       rep(rlang::syms("pred_data_no_ph"), 5)),
                   prediction_grid = rep(rlang::syms("temperature_mean"), 18),
                   desc_resampling = c("spatial/spatial",
                                       "spatial/spatial",
                                       "spatial/spatial",
                                       "spatial/spatial",
                                       "spatial/no tuning",

                                       "spatial/spatial", # debugging tasks
                                       "spatial/spatial", # debugging tasks
                                       "spatial/spatial", # debugging tasks
                                       "spatial/spatial", # debugging tasks
                                       "spatial/spatial", # debugging tasks
                                       "spatial/spatial", # debugging tasks
                                       "spatial/spatial", # debugging tasks
                                       "spatial/spatial", # debugging tasks

                                       "spatial/spatial",
                                       "spatial/spatial",
                                       "spatial/spatial",
                                       "spatial/spatial",
                                       "spatial/spatial")
)
args_pred$id = suppressWarnings(paste0("prediction_", str_split(args_pred$learner, "_", simplify = TRUE)[, 2]))
args_pred$learner = rlang::syms(args_pred$learner)

args_pred[6, "id"] = "prediction_debugging_diplodia_no_temp"
args_pred[7, "id"] = "prediction_debugging_diplodia_no_precip"
args_pred[8, "id"] = "prediction_debugging_diplodia_no_hail"
args_pred[9, "id"] = "prediction_debugging_diplodia_no_ph"
args_pred[10, "id"] = "prediction_debugging_diplodia_no_soil"
args_pred[11, "id"] = "prediction_debugging_diplodia_no_lithology"
args_pred[12, "id"] = "prediction_debugging_diplodia_no_slope"
args_pred[13, "id"] = "prediction_debugging_diplodia_no_pisr"

args_pred[14, "id"] = "prediction_gam_diplodia_no_ph"
args_pred[15, "id"] = "prediction_gam_fusarium_no_ph"
args_pred[16, "id"] = "prediction_gam_armillaria_no_ph"
args_pred[17, "id"] = "prediction_gam_heterobasidion_no_ph"

prediction_prob_plan = map_plan(args_pred, prediction_custom, trace = FALSE)


# prediction maps ---------------------------------------------------------

args_pred = tibble(prediction_raster = c("prediction_glm",

                                         "prediction_gam_diplodia_no_ph",
                                         "prediction_gam_fusarium_no_ph",
                                         "prediction_gam_armillaria_no_ph",
                                         "prediction_gam_heterobasidion_no_ph",

                                         "prediction_svm",

                                         "prediction_rf",

                                         "prediction_kknn",

                                         "prediction_xgboost",

                                         "prediction_brt",

                                         "prediction_debugging_diplodia_no_temp",
                                         "prediction_debugging_diplodia_no_precip",
                                         "prediction_debugging_diplodia_no_hail",
                                         "prediction_debugging_diplodia_no_ph",
                                         "prediction_debugging_diplodia_no_soil",
                                         "prediction_debugging_diplodia_no_lithology",
                                         "prediction_debugging_diplodia_no_slope",
                                         "prediction_debugging_diplodia_no_pisr"
),
model_name = c("glm",

               "gam",
               "gam",
               "gam",
               "gam",

               "svm",

               "rf",

               "kknn",

               "xgboost",

               "brt",

               "rf",
               "rf",
               "rf",
               "rf",
               "rf",
               "rf",
               "rf",
               "rf"
),
benchmark_object = c("bm_sp_non_glm",

                     "bm_sp_sp_diplodia_gam",
                     "bm_sp_sp_fusarium_gam",
                     "bm_sp_sp_armillaria_gam",
                     "bm_sp_sp_heterobasidion_gam",

                     "no_extract_bm_sp_sp_svm",
                     "no_extract_bm_sp_sp_rf",
                     "no_extract_bm_sp_sp_kknn",
                     "no_extract_bm_sp_sp_xgboost",
                     "no_extract_bm_sp_sp_brt",

                     "no_extract_bm_sp_sp_brt", # debugging
                     "no_extract_bm_sp_sp_brt", # debugging
                     "no_extract_bm_sp_sp_brt", # debugging
                     "no_extract_bm_sp_sp_brt", # debugging
                     "no_extract_bm_sp_sp_brt", # debugging
                     "no_extract_bm_sp_sp_brt", # debugging
                     "no_extract_bm_sp_sp_brt", # debugging
                     "no_extract_bm_sp_sp_brt" # debugging
),
resampling = c(# glm
  "spatial/no tuning",

  # gam
  "spatial/spatial",
  "spatial/spatial",
  "spatial/spatial",
  "spatial/spatial",

  "spatial/spatial",
  "spatial/spatial",
  "spatial/spatial",
  "spatial/spatial",
  "spatial/spatial",

  "NA", # debugging
  "NA", # debugging
  "NA", # debugging
  "NA", # debugging
  "NA", # debugging
  "NA", # debugging
  "NA", # debugging
  "NA") # debugging
)

args_pred$id = suppressWarnings(paste0("maps_", gsub("prediction_", "", args_pred$prediction_raster)))
args_pred$prediction_raster = rlang::syms(args_pred$prediction_raster)
args_pred$benchmark_object = rlang::syms(args_pred$benchmark_object)

prediction_maps_plan = map_plan(args_pred, create_prediction_map, trace = FALSE)

rm(list=ls(pattern="args_pred"))
