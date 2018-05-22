srand(999)

import CSV
import DataFrames
import LIBSVM
import PredictMD

trainingandvalidation_features_df_filename =
    ENV["trainingandvalidation_features_df_filename"]
trainingandvalidation_labels_df_filename =
    ENV["trainingandvalidation_labels_df_filename"]
testing_features_df_filename =
    ENV["testing_features_df_filename"]
testing_labels_df_filename =
    ENV["testing_labels_df_filename"]
training_features_df_filename =
    ENV["training_features_df_filename"]
training_labels_df_filename =
    ENV["training_labels_df_filename"]
validation_features_df_filename =
    ENV["validation_features_df_filename"]
validation_labels_df_filename =
    ENV["validation_labels_df_filename"]
trainingandvalidation_features_df = CSV.read(
    trainingandvalidation_features_df_filename,
    DataFrames.DataFrame,
    )
trainingandvalidation_labels_df = CSV.read(
    trainingandvalidation_labels_df_filename,
    DataFrames.DataFrame,
    )
testing_features_df = CSV.read(
    testing_features_df_filename,
    DataFrames.DataFrame,
    )
testing_labels_df = CSV.read(
    testing_labels_df_filename,
    DataFrames.DataFrame,
    )
training_features_df = CSV.read(
    training_features_df_filename,
    DataFrames.DataFrame,
    )
training_features_df = CSV.read(
    training_features_df_filename,
    DataFrames.DataFrame,
    )
validation_features_df = CSV.read(
    validation_features_df_filename,
    DataFrames.DataFrame,
    )
validation_labels_df = CSV.read(
    validation_labels_df_filename,
    DataFrames.DataFrame,
    )

smoted_training_features_df_filename =
    ENV["smoted_training_features_df_filename"]
smoted_training_labels_df_filename =
    ENV["smoted_training_labels_df_filename"]
smoted_training_features_df = CSV.read(
    smoted_training_features_df_filename,
    DataFrames.DataFrame,
    )
smoted_training_labels_df = CSV.read(
    smoted_training_labels_df_filename,
    DataFrames.DataFrame,
    )

categoricalfeaturenames = Symbol[]
continuousfeaturenames = Symbol[
    :V1,
    :V2,
    :V3,
    :V4,
    :V5,
    :V6,
    :V7,
    :V8,
    :V9,
    ]
featurenames = vcat(categoricalfeaturenames, continuousfeaturenames)

singlelabelname = :Class
negativeclass = "benign"
positiveclass = "malignant"
singlelabellevels = [negativeclass, positiveclass]
ENV["c_svc_svm_classifier_filename"] = string(
    tempname(),
    "c_svc_svm_classifier.jld2",
    )
c_svc_svm_classifier_filename = ENV["c_svc_svm_classifier_filename"]

feature_contrasts = PredictMD.generate_feature_contrasts(
    smoted_training_features_df,
    featurenames,
    )

c_svc_svm_classifier = PredictMD.singlelabelmulticlassdataframesvmclassifier(
    featurenames,
    singlelabelname,
    singlelabellevels;
    package = :LIBSVMjl,
    svmtype = LIBSVM.SVC,
    name = "SVM (C-SVC)",
    verbose = false,
    feature_contrasts = feature_contrasts,
    )

PredictMD.fit!(
    c_svc_svm_classifier,
    smoted_training_features_df,
    smoted_training_labels_df,
    )

c_svc_svm_classifier_hist_training = PredictMD.plotsinglelabelbinaryclassifierhistogram(
    c_svc_svm_classifier,
    smoted_training_features_df,
    smoted_training_labels_df,
    singlelabelname,
    singlelabellevels,
    )
PredictMD.open_plot(c_svc_svm_classifier_hist_training)

c_svc_svm_classifier_hist_testing = PredictMD.plotsinglelabelbinaryclassifierhistogram(
    c_svc_svm_classifier,
    testing_features_df,
    testing_labels_df,
    singlelabelname,
    singlelabellevels,
    )
PredictMD.open_plot(c_svc_svm_classifier_hist_testing)

PredictMD.singlelabelbinaryclassificationmetrics(
    c_svc_svm_classifier,
    smoted_training_features_df,
    smoted_training_labels_df,
    singlelabelname,
    positiveclass;
    sensitivity = 0.95,
    )

PredictMD.singlelabelbinaryclassificationmetrics(
    c_svc_svm_classifier,
    testing_features_df,
    testing_labels_df,
    singlelabelname,
    positiveclass;
    sensitivity = 0.95,
    )

PredictMD.save_model(c_svc_svm_classifier_filename, c_svc_svm_classifier)
