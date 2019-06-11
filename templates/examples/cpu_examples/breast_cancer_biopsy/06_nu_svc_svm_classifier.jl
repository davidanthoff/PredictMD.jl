## %PREDICTMD_GENERATED_BY%

import PredictMD

### Begin project-specific settings

LOCATION_OF_PREDICTMD_GENERATED_EXAMPLE_FILES = homedir()

PROJECT_OUTPUT_DIRECTORY = joinpath(
    LOCATION_OF_PREDICTMD_GENERATED_EXAMPLE_FILES,
    "cpu_examples",
    "breast_cancer_biopsy",
    "output",
    )

# PREDICTMD IF INCLUDE TEST STATEMENTS
@debug("PROJECT_OUTPUT_DIRECTORY: ", PROJECT_OUTPUT_DIRECTORY,)
if PredictMD.is_travis_ci()
    PredictMD.cache_to_homedir!("Desktop", "breast_cancer_biopsy_example",)
end
# PREDICTMD ELSE
# PREDICTMD ENDIF INCLUDE TEST STATEMENTS

### End project-specific settings

### Begin nu-SVC code

# PREDICTMD IF INCLUDE TEST STATEMENTS
import PredictMDExtra
# PREDICTMD ELSE
import PredictMDFull
# PREDICTMD ENDIF INCLUDE TEST STATEMENTS

Kernel = LIBSVM.Kernel

Random.seed!(999)

trainingandtuning_features_df_filename = joinpath\(
    PROJECT_OUTPUT_DIRECTORY,
    "data",
    "trainingandtuning_features_df.csv",
    )
trainingandtuning_labels_df_filename = joinpath\(
    PROJECT_OUTPUT_DIRECTORY,
    "data",
    "trainingandtuning_labels_df.csv",
    )
testing_features_df_filename = joinpath\(
    PROJECT_OUTPUT_DIRECTORY,
    "data",
    "testing_features_df.csv",
    )
testing_labels_df_filename = joinpath\(
    PROJECT_OUTPUT_DIRECTORY,
    "data",
    "testing_labels_df.csv",
    )
training_features_df_filename = joinpath\(
    PROJECT_OUTPUT_DIRECTORY,
    "data",
    "training_features_df.csv",
    )
training_labels_df_filename = joinpath\(
    PROJECT_OUTPUT_DIRECTORY,
    "data",
    "training_labels_df.csv",
    )
tuning_features_df_filename = joinpath\(
    PROJECT_OUTPUT_DIRECTORY,
    "data",
    "tuning_features_df.csv",
    )
tuning_labels_df_filename = joinpath\(
    PROJECT_OUTPUT_DIRECTORY,
    "data",
    "tuning_labels_df.csv",
    )
trainingandtuning_features_df = DataFrames.DataFrame(
    FileIO.load(
        trainingandtuning_features_df_filename;
        type_detect_rows = 100,
        )
    )
trainingandtuning_labels_df = DataFrames.DataFrame(
    FileIO.load(
        trainingandtuning_labels_df_filename;
        type_detect_rows = 100,
        )
    )
testing_features_df = DataFrames.DataFrame(
    FileIO.load(
        testing_features_df_filename;
        type_detect_rows = 100,
        )
    )
testing_labels_df = DataFrames.DataFrame(
    FileIO.load(
        testing_labels_df_filename;
        type_detect_rows = 100,
        )
    )
training_features_df = DataFrames.DataFrame(
    FileIO.load(
        training_features_df_filename;
        type_detect_rows = 100,
        )
    )
training_labels_df = DataFrames.DataFrame(
    FileIO.load(
        training_labels_df_filename;
        type_detect_rows = 100,
        )
    )
tuning_features_df = DataFrames.DataFrame(
    FileIO.load(
        tuning_features_df_filename;
        type_detect_rows = 100,
        )
    )
tuning_labels_df = DataFrames.DataFrame(
    FileIO.load(
        tuning_labels_df_filename;
        type_detect_rows = 100,
        )
    )

smoted_training_features_df_filename = joinpath\(
    PROJECT_OUTPUT_DIRECTORY,
    "data",
    "smoted_training_features_df.csv",
    )
smoted_training_labels_df_filename = joinpath\(
    PROJECT_OUTPUT_DIRECTORY,
    "data",
    "smoted_training_labels_df.csv",
    )
smoted_training_features_df = DataFrames.DataFrame(
    FileIO.load(
        smoted_training_features_df_filename;
        type_detect_rows = 100,
        )
    )
smoted_training_labels_df = DataFrames.DataFrame(
    FileIO.load(
        smoted_training_labels_df_filename;
        type_detect_rows = 100,
        )
    )

categorical_feature_names_filename = joinpath(
    PROJECT_OUTPUT_DIRECTORY,
    "data",
    "categorical_feature_names.jld2",
    )
continuous_feature_names_filename = joinpath(
    PROJECT_OUTPUT_DIRECTORY,
    "data",
    "continuous_feature_names.jld2",
    )
categorical_feature_names = FileIO.load(
    categorical_feature_names_filename,
    "categorical_feature_names",
    )
continuous_feature_names = FileIO.load(
    continuous_feature_names_filename,
    "continuous_feature_names",
    )
feature_names = vcat(categorical_feature_names, continuous_feature_names)

single_label_name = :Class
negative_class = "benign"
positive_class = "malignant"
single_label_levels = [negative_class, positive_class]

categorical_label_names = Symbol[single_label_name]
continuous_label_names = Symbol[]
label_names = vcat(categorical_label_names, continuous_label_names)

feature_contrasts = PredictMD.generate_feature_contrasts(
    smoted_training_features_df,
    feature_names,
    )

nu_svc_svm_classifier =
    PredictMD.single_labelmulticlassdataframesvmclassifier(
        feature_names,
        single_label_name,
        single_label_levels;
        package = :LIBSVM,
        svmtype = LIBSVM.NuSVC,
        name = "SVM (nu-SVC)",
        verbose = false,
        feature_contrasts = feature_contrasts,
        )

PredictMD.fit!(
    nu_svc_svm_classifier,
    smoted_training_features_df,
    smoted_training_labels_df,
    )

nu_svc_svm_classifier_hist_training =
    PredictMD.plotsinglelabelbinaryclassifierhistogram(
        nu_svc_svm_classifier,
        smoted_training_features_df,
        smoted_training_labels_df,
        single_label_name,
        single_label_levels,
        );

# PREDICTMD IF INCLUDE TEST STATEMENTS
filename = string(
    tempname(),
    "_",
    "nu_svc_svm_classifier_hist_training",
    ".pdf",
    )
rm(filename; force = true, recursive = true,)
@debug("Attempting to test that the file does not exist...", filename,)
Test.@test(!isfile(filename))
@debug("The file does not exist.", filename, isfile(filename),)
PredictMD.save_plot(filename, nu_svc_svm_classifier_hist_training)
if PredictMD.is_force_test_plots()
    @debug("Attempting to test that the file exists...", filename,)
    Test.@test(isfile(filename))
    @debug("The file does exist.", filename, isfile(filename),)
end
# PREDICTMD ELSE
# PREDICTMD ENDIF INCLUDE TEST STATEMENTS

display(nu_svc_svm_classifier_hist_training)
PredictMD.save_plot(
    joinpath(
        PROJECT_OUTPUT_DIRECTORY,
        "plots",
        "nu_svc_svm_classifier_hist_training.pdf",
        ),
    nu_svc_svm_classifier_hist_training,
    )

nu_svc_svm_classifier_hist_testing =
    PredictMD.plotsinglelabelbinaryclassifierhistogram(
        nu_svc_svm_classifier,
        testing_features_df,
        testing_labels_df,
        single_label_name,
        single_label_levels,
        );

# PREDICTMD IF INCLUDE TEST STATEMENTS
filename = string(
    tempname(),
    "_",
    "nu_svc_svm_classifier_hist_testing",
    ".pdf",
    )
rm(filename; force = true, recursive = true,)
@debug("Attempting to test that the file does not exist...", filename,)
Test.@test(!isfile(filename))
@debug("The file does not exist.", filename, isfile(filename),)
PredictMD.save_plot(filename, nu_svc_svm_classifier_hist_testing)
if PredictMD.is_force_test_plots()
    @debug("Attempting to test that the file exists...", filename,)
    Test.@test(isfile(filename))
    @debug("The file does exist.", filename, isfile(filename),)
end
# PREDICTMD ELSE
# PREDICTMD ENDIF INCLUDE TEST STATEMENTS

display(nu_svc_svm_classifier_hist_testing)
PredictMD.save_plot(
    joinpath(
        PROJECT_OUTPUT_DIRECTORY,
        "plots",
        "nu_svc_svm_classifier_hist_testing.pdf",
        ),
    nu_svc_svm_classifier_hist_testing,
    )

show(
    PredictMD.singlelabelbinaryclassificationmetrics(
        nu_svc_svm_classifier,
        smoted_training_features_df,
        smoted_training_labels_df,
        single_label_name,
        positive_class;
        sensitivity = 0.95,
        );
    allrows = true,
    allcols = true,
    splitcols = false,
    )

show(
    PredictMD.singlelabelbinaryclassificationmetrics(
        nu_svc_svm_classifier,
        testing_features_df,
        testing_labels_df,
        single_label_name,
        positive_class;
        sensitivity = 0.95,
        );
    allrows = true,
    allcols = true,
    splitcols = false,
    )

nu_svc_svm_classifier_filename = joinpath(
    PROJECT_OUTPUT_DIRECTORY,
    "nu_svc_svm_classifier.jld2",
    )

PredictMD.save_model(
    nu_svc_svm_classifier_filename,
    nu_svc_svm_classifier,
    )

### End nu-SVC code

# PREDICTMD IF INCLUDE TEST STATEMENTS
if PredictMD.is_travis_ci()
    PredictMD.homedir_to_cache!("Desktop", "breast_cancer_biopsy_example",)
end
# PREDICTMD ELSE
# PREDICTMD ENDIF INCLUDE TEST STATEMENTS
