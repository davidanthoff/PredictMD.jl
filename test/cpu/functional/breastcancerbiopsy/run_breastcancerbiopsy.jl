logisticclassifier_filename = ENV["logisticclassifier_filename"]
rfclassifier_filename = ENV["rfclassifier_filename"]
csvc_svmclassifier_filename = ENV["csvc_svmclassifier_filename"]
nusvc_svmclassifier_filename = ENV["nusvc_svmclassifier_filename"]
knetmlp_filename = ENV["knetmlp_filename"]

##############################################################################
##############################################################################
### Section 1: Setup #########################################################
##############################################################################
##############################################################################

# import required packages
import PredictMD
import DataFrames
import Knet
import LIBSVM
import RDatasets
import StatsBase

# set the seed of the global random number generator
# this makes the results reproducible
srand(999)

##############################################################################
##############################################################################
### Section 2: Prepare data ##################################################
##############################################################################
##############################################################################

# Import breast cancer biopsy data
df = RDatasets.dataset("MASS", "biopsy")

# Remove rows with missing data
DataFrames.dropmissing!(df)

# Shuffle rows
PredictMD.shuffle_rows!(df)

# Define features
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

if get(ENV, "LOADTRAINEDMODELSFROMFILE", "") == "true"
else
    feature_contrasts = PredictMD.generate_feature_contrasts(df, featurenames)
end

# Define labels
labelname = :Class
negativeclass = "benign"
positiveclass = "malignant"
labellevels = [negativeclass, positiveclass]

# Put features and labels in separate dataframes
features_df = df[featurenames]
labels_df = df[[labelname]]

# Split the data into training (50%), validation (25%), and testing (25%)
trainingandvalidation_features_df,
    trainingandvalidation_labels_df,
    testing_features_df,
    testing_labels_df = PredictMD.split_data(
        features_df,
        labels_df,
        0.75, # 75% training+validation, 25% testing
        )
training_features_df,
    training_labels_df,
    validation_features_df,
    validation_labels_df = PredictMD.split_data(
        trainingandvalidation_features_df,
        trainingandvalidation_labels_df,
        2/3, # 2/3 of 75% = 50% training, 1/3 of 75% = 25% validation
        )

##############################################################################
##############################################################################
### Section 3: Apply the SMOTE algorithm to the training set #################
##############################################################################
##############################################################################

# Examine prevalence of each class in training set
# DataFrames.describe(training_labels_df[labelname])
StatsBase.countmap(training_labels_df[labelname])

# We see that malignant is minority class and benign is majority class.
# The ratio of malignant:benign is somewhere between 1:2.5 and 1:3 (depending
# on random seed). We would like that ratio to be 1:1. We will use SMOTE
# to generate synthetic minority class samples. We will also undersample the
# minority class. The result will be a balanced training set.
majorityclass = "benign"
minorityclass = "malignant"

smoted_training_features_df, smoted_training_labels_df = PredictMD.smote(
    training_features_df,
    training_labels_df,
    featurenames,
    labelname;
    majorityclass = majorityclass,
    minorityclass = minorityclass,
    pct_over = 100, # how much to oversample the minority class
    minority_to_majority_ratio = 1.0, # desired minority:majority ratio
    k = 5,
    )

# Examine prevalence of each class in smoted training set
# DataFrames.describe(smoted_training_labels_df[labelname])
StatsBase.countmap(smoted_training_labels_df[labelname])

# Now we have a ratio of malignant:benign that is 1:1.

##############################################################################
##############################################################################
### Section 4: Set up and train models #######################################
##############################################################################
##############################################################################

##############################################################################
## Logistic "regression" classifier ##########################################
##############################################################################

if get(ENV, "LOADTRAINEDMODELSFROMFILE", "") == "true"
    logisticclassifier = PredictMD.load_model(logisticclassifier_filename)
else
    # Set up logistic classifier model
    logisticclassifier = PredictMD.singlelabelbinaryclassdataframelogisticclassifier(
        featurenames,
        labelname,
        labellevels;
        package = :GLMjl,
        intercept = true, # optional, defaults to true
        interactions = 1, # optional, defaults to 1
        name = "Logistic regression", # optional
        )
end

if get(ENV, "LOADTRAINEDMODELSFROMFILE", "") == "true"
else
    # Train logistic classifier model on smoted training set
    PredictMD.fit!(
        logisticclassifier,
        smoted_training_features_df,
        smoted_training_labels_df,
        )
end

# View coefficients, p values, etc. for underlying logistic regression
PredictMD.get_underlying(logisticclassifier)

# Plot classifier histogram for logistic classifier on smoted training set
logistic_hist_training = PredictMD.plotsinglelabelbinaryclassifierhistogram(
    logisticclassifier,
    smoted_training_features_df,
    smoted_training_labels_df,
    labelname,
    labellevels,
    )
PredictMD.open_plot(logistic_hist_training)

# Plot classifier histogram for logistic classifier on testing set
logistic_hist_testing = PredictMD.plotsinglelabelbinaryclassifierhistogram(
    logisticclassifier,
    testing_features_df,
    testing_labels_df,
    labelname,
    labellevels,
    )
PredictMD.open_plot(logistic_hist_testing)

# Evaluate performance of logistic classifier on smoted training set
PredictMD.singlelabelbinaryclassificationmetrics(
    logisticclassifier,
    testing_features_df,
    testing_labels_df,
    labelname,
    positiveclass;
    sensitivity = 0.95,
    )

# Evaluate performance of logistic classifier on testing set
PredictMD.singlelabelbinaryclassificationmetrics(
    logisticclassifier,
    testing_features_df,
    testing_labels_df,
    labelname,
    positiveclass;
    sensitivity = 0.95,
    )

logistic_calibration_curve = PredictMD.plot_probability_calibration_curve(
    logisticclassifier,
    smoted_training_features_df,
    smoted_training_labels_df,
    labelname,
    positiveclass;
    window = 0.2,
    )
PredictMD.open_plot(logistic_calibration_curve)

PredictMD.probability_calibration_metrics(
    logisticclassifier,
    testing_features_df,
    testing_labels_df,
    labelname,
    positiveclass;
    window = 0.1,
    )

logistic_cutoffs, logistic_risk_group_prevalences = PredictMD.risk_score_cutoff_values(
    logisticclassifier,
    testing_features_df,
    testing_labels_df,
    labelname,
    positiveclass;
    average_function = mean,
    )
println(
    string(
        "Low risk: 0 to $(logistic_cutoffs[1]).",
        " Medium risk: $(logistic_cutoffs[1]) to $(logistic_cutoffs[2]).",
        " High risk: $(logistic_cutoffs[2]) to 1.",
        )
    )
showall(logistic_risk_group_prevalences)
logistic_cutoffs, logistic_risk_group_prevalences = PredictMD.risk_score_cutoff_values(
    logisticclassifier,
    testing_features_df,
    testing_labels_df,
    labelname,
    positiveclass;
    average_function = median,
    )
println(
    string(
        "Low risk: 0 to $(logistic_cutoffs[1]).",
        " Medium risk: $(logistic_cutoffs[1]) to $(logistic_cutoffs[2]).",
        " High risk: $(logistic_cutoffs[2]) to 1.",
        )
    )
showall(logistic_risk_group_prevalences)

##############################################################################
## Random forest classifier ##################################################
##############################################################################

if get(ENV, "LOADTRAINEDMODELSFROMFILE", "") == "true"
    rfclassifier = PredictMD.load_model(rfclassifier_filename)
else
    # Set up random forest classifier model
    rfclassifier = PredictMD.singlelabelmulticlassdataframerandomforestclassifier(
        featurenames,
        labelname,
        labellevels;
        nsubfeatures = 4, # number of subfeatures; defaults to 2
        ntrees = 200, # number of trees; defaults to 10
        package = :DecisionTreejl,
        name = "Random forest", # optional
        feature_contrasts = feature_contrasts,
        )
end

if get(ENV, "LOADTRAINEDMODELSFROMFILE", "") == "true"
else
    # Train random forest classifier model on smoted training set
    PredictMD.fit!(
        rfclassifier,
        smoted_training_features_df,
        smoted_training_labels_df,
        )
end

# Plot classifier histogram for random forest classifier on smoted training set
rfclassifier_hist_training = PredictMD.plotsinglelabelbinaryclassifierhistogram(
    rfclassifier,
    smoted_training_features_df,
    smoted_training_labels_df,
    labelname,
    labellevels,
    )
PredictMD.open_plot(rfclassifier_hist_training)

# Plot classifier histogram for random forest classifier on testing set
rfclassifier_hist_testing = PredictMD.plotsinglelabelbinaryclassifierhistogram(
    rfclassifier,
    testing_features_df,
    testing_labels_df,
    labelname,
    labellevels,
    )
PredictMD.open_plot(rfclassifier_hist_testing)

# Evaluate performance of random forest classifier on smoted training set
PredictMD.singlelabelbinaryclassificationmetrics(
    rfclassifier,
    smoted_training_features_df,
    smoted_training_labels_df,
    labelname,
    positiveclass;
    sensitivity = 0.95,
    )

# Evaluate performance of random forest on testing set
PredictMD.singlelabelbinaryclassificationmetrics(
    rfclassifier,
    testing_features_df,
    testing_labels_df,
    labelname,
    positiveclass;
    sensitivity = 0.95,
    )

rf_calibration_curve = PredictMD.plot_probability_calibration_curve(
    rfclassifier,
    testing_features_df,
    testing_labels_df,
    labelname,
    positiveclass;
    window = 0.1,
    )
PredictMD.open_plot(rf_calibration_curve)

##############################################################################
## Support vector machine (C support vector classifier) ######################
##############################################################################

if get(ENV, "LOADTRAINEDMODELSFROMFILE", "") == "true"
    csvc_svmclassifier = PredictMD.load_model(csvc_svmclassifier_filename)
else
    # Set up C-SVC model
    csvc_svmclassifier = PredictMD.singlelabelmulticlassdataframesvmclassifier(
        featurenames,
        labelname,
        labellevels;
        package = :LIBSVMjl,
        svmtype = LIBSVM.SVC,
        name = "SVM (C-SVC)",
        verbose = false,
        feature_contrasts = feature_contrasts,
        )
end

if get(ENV, "LOADTRAINEDMODELSFROMFILE", "") == "true"
else
    # Train C-SVC model on smoted training set
    PredictMD.fit!(
        csvc_svmclassifier,
        smoted_training_features_df,
        smoted_training_labels_df,
        )
end

# Plot classifier histogram for C-SVC on smoted training set
csvc_svmclassifier_hist_training = PredictMD.plotsinglelabelbinaryclassifierhistogram(
    csvc_svmclassifier,
    smoted_training_features_df,
    smoted_training_labels_df,
    labelname,
    labellevels,
    )
PredictMD.open_plot(csvc_svmclassifier_hist_training)

# Plot classifier histogram for C-SVC on testing set
csvc_svmclassifier_hist_testing = PredictMD.plotsinglelabelbinaryclassifierhistogram(
    csvc_svmclassifier,
    testing_features_df,
    testing_labels_df,
    labelname,
    labellevels,
    )
PredictMD.open_plot(csvc_svmclassifier_hist_testing)

# Evaluate performance of C-SVC on smoted training set
PredictMD.singlelabelbinaryclassificationmetrics(
    csvc_svmclassifier,
    smoted_training_features_df,
    smoted_training_labels_df,
    labelname,
    positiveclass;
    sensitivity = 0.95,
    )

# Evaluate performance of C-SVC on testing set
PredictMD.singlelabelbinaryclassificationmetrics(
    csvc_svmclassifier,
    testing_features_df,
    testing_labels_df,
    labelname,
    positiveclass;
    sensitivity = 0.95,
    )

##############################################################################
## Support vector machine (nu support vector classifier) #####################
##############################################################################

if get(ENV, "LOADTRAINEDMODELSFROMFILE", "") == "true"
    nusvc_svmclassifier = PredictMD.load_model(nusvc_svmclassifier_filename)
else
    # Set up nu-SVC model
    nusvc_svmclassifier = PredictMD.singlelabelmulticlassdataframesvmclassifier(
        featurenames,
        labelname,
        labellevels;
        package = :LIBSVMjl,
        svmtype = LIBSVM.NuSVC,
        name = "SVM (nu-SVC)",
        verbose = false,
        feature_contrasts = feature_contrasts,
        )
end

if get(ENV, "LOADTRAINEDMODELSFROMFILE", "") == "true"
else
    # Train nu-SVC model on smoted training set
    PredictMD.fit!(
        nusvc_svmclassifier,
        smoted_training_features_df,
        smoted_training_labels_df,
        )
end

# Plot classifier histogram for nu-SVC on smoted training set
nusvc_svmclassifier_hist_training = PredictMD.plotsinglelabelbinaryclassifierhistogram(
    nusvc_svmclassifier,
    smoted_training_features_df,
    smoted_training_labels_df,
    labelname,
    labellevels,
    )
PredictMD.open_plot(nusvc_svmclassifier_hist_training)

# Plot classifier histogram for nu-SVC on testing set
nusvc_svmclassifier_hist_testing = PredictMD.plotsinglelabelbinaryclassifierhistogram(
    nusvc_svmclassifier,
    testing_features_df,
    testing_labels_df,
    labelname,
    labellevels,
    )
PredictMD.open_plot(nusvc_svmclassifier_hist_testing)

# Evaluate performance of nu-SVC on smoted training set
PredictMD.singlelabelbinaryclassificationmetrics(
    nusvc_svmclassifier,
    smoted_training_features_df,
    smoted_training_labels_df,
    labelname,
    positiveclass;
    sensitivity = 0.95,
    )

# Evaluate performance of SVM on testing set
PredictMD.singlelabelbinaryclassificationmetrics(
    nusvc_svmclassifier,
    testing_features_df,
    testing_labels_df,
    labelname,
    positiveclass;
    sensitivity = 0.95,
    )

##############################################################################
## Multilayer perceptron (i.e. fully connected feedforward neural network) ###
##############################################################################

# Define predict function
function knetmlp_predict(
        w, # don't put a type annotation on this
        x0::AbstractArray;
        probabilities::Bool = true,
        )
    # x0 = input layer
    # x1 = first hidden layer
    x1 = Knet.relu.( w[1]*x0 .+ w[2] ) # w[1] = weights, w[2] = biases
    # x2 = second hidden layer
    x2 = Knet.relu.( w[3]*x1 .+ w[4] ) # w[3] = weights, w[4] = biases
    # x3 = output layer
    x3 = w[5]*x2 .+ w[6] # w[5] = weights, w[6] = biases
    unnormalizedlogprobs = x3
    if probabilities
        normalizedlogprobs = Knet.logp(unnormalizedlogprobs, 1)
        normalizedprobs = exp.(normalizedlogprobs)
        return normalizedprobs
    else
        return unnormalizedlogprobs
    end
end

# Define loss function
function knetmlp_loss(
        predict::Function,
        modelweights, # don't put a type annotation on this
        x::AbstractArray,
        ytrue::AbstractArray;
        L1::Real = Cfloat(0),
        L2::Real = Cfloat(0),
        )
    loss = Knet.nll(
        predict(
            modelweights,
            x;
            probabilities = false,
            ),
        ytrue,
        1, # d = 1 means that instances are in columns
        )
    if L1 != 0
        loss += L1 * sum(sum(abs, w_i) for w_i in modelweights[1:2:end])
    end
    if L2 != 0
        loss += L2 * sum(sum(abs2, w_i) for w_i in modelweights[1:2:end])
    end
    return loss
end

if get(ENV, "LOADTRAINEDMODELSFROMFILE", "") == "true"
    knetmlpclassifier = PredictMD.load_model(knetmlp_filename)
else
    # Randomly initialize model weights
    knetmlp_modelweights = Any[
        # input layer has dimension contrasts.num_array_columns
        #
        # first hidden layer (64 neurons):
        Cfloat.(
            0.1f0*randn(Cfloat,64,feature_contrasts.num_array_columns) # weights
            ),
        Cfloat.(
            zeros(Cfloat,64,1) # biases
            ),
        #
        # second hidden layer (32 neurons):
        Cfloat.(
            0.1f0*randn(Cfloat,32,64) # weights
            ),
        Cfloat.(
            zeros(Cfloat,32,1) # biases
            ),
        #
        # output layer (number of neurons == number of classes):
        Cfloat.(
            0.1f0*randn(Cfloat,2,32) # weights
            ),
        Cfloat.(
            zeros(Cfloat,2,1) # biases
            ),
        ]
    # Define loss hyperparameters
    knetmlp_losshyperparameters = Dict()
    knetmlp_losshyperparameters[:L1] = Cfloat(0.0)
    knetmlp_losshyperparameters[:L2] = Cfloat(0.0)
    # Select optimization algorithm
    knetmlp_optimizationalgorithm = :Momentum
    # Set optimization hyperparameters
    knetmlp_optimizerhyperparameters = Dict()
    # Set the minibatch size
    knetmlp_minibatchsize = 48
    # Set the max number of epochs. After training, look at the learning curve. If
    # it looks like the model has not yet converged, raise maxepochs. If it looks
    # like the loss has hit a plateau and you are worried about overfitting, lower
    # maxepochs.
    knetmlp_maxepochs = 1_000
    # Set up multilayer perceptron model
    knetmlpclassifier = PredictMD.singlelabelmulticlassdataframeknetclassifier(
        featurenames,
        labelname,
        labellevels;
        package = :Knetjl,
        name = "Knet MLP",
        predict = knetmlp_predict,
        loss = knetmlp_loss,
        losshyperparameters = knetmlp_losshyperparameters,
        optimizationalgorithm = knetmlp_optimizationalgorithm,
        optimizerhyperparameters = knetmlp_optimizerhyperparameters,
        minibatchsize = knetmlp_minibatchsize,
        modelweights = knetmlp_modelweights,
        printlosseverynepochs = 100, # if 0, will not print at all
        maxepochs = knetmlp_maxepochs,
        feature_contrasts = feature_contrasts,
        )
end

if get(ENV, "LOADTRAINEDMODELSFROMFILE", "") == "true"
else
    # Train multilayer perceptron model on training set
    PredictMD.fit!(
        knetmlpclassifier,
        smoted_training_features_df,
        smoted_training_labels_df,
        validation_features_df,
        validation_labels_df,
        )
end

# Plot learning curve: loss vs. epoch
knet_learningcurve_lossvsepoch = PredictMD.plotlearningcurve(
    knetmlpclassifier,
    :loss_vs_epoch;
    )
PredictMD.open_plot(knet_learningcurve_lossvsepoch)

# Plot learning curve: loss vs. epoch, skip the first 10 epochs
knet_learningcurve_lossvsepoch_skip10epochs = PredictMD.plotlearningcurve(
    knetmlpclassifier,
    :loss_vs_epoch;
    startat = 10,
    endat = :end,
    )
PredictMD.open_plot(knet_learningcurve_lossvsepoch_skip10epochs)

# Plot learning curve: loss vs. iteration
knet_learningcurve_lossvsiteration = PredictMD.plotlearningcurve(
    knetmlpclassifier,
    :loss_vs_iteration;
    window = 50,
    sampleevery = 10,
    )
PredictMD.open_plot(knet_learningcurve_lossvsiteration)

# Plot learning curve: loss vs. iteration, skip the first 100 iterations
knet_learningcurve_lossvsiteration_skip100iterations = PredictMD.plotlearningcurve(
    knetmlpclassifier,
    :loss_vs_iteration;
    window = 50,
    sampleevery = 10,
    startat = 100,
    endat = :end,
    )
PredictMD.open_plot(knet_learningcurve_lossvsiteration_skip100iterations)

# Plot classifier histogram for multilayer perceptron on smoted training set
knetmlpclassifier_hist_training = PredictMD.plotsinglelabelbinaryclassifierhistogram(
    knetmlpclassifier,
    smoted_training_features_df,
    smoted_training_labels_df,
    labelname,
    labellevels,
    )
PredictMD.open_plot(knetmlpclassifier_hist_training)

# Plot classifier histogram for multilayer perceptron on testing set
knetmlpclassifier_hist_testing = PredictMD.plotsinglelabelbinaryclassifierhistogram(
    knetmlpclassifier,
    testing_features_df,
    testing_labels_df,
    labelname,
    labellevels,
    )
PredictMD.open_plot(knetmlpclassifier_hist_testing)

# Evaluate performance of multilayer perceptron on smoted training set
PredictMD.singlelabelbinaryclassificationmetrics(
    knetmlpclassifier,
    smoted_training_features_df,
    smoted_training_labels_df,
    labelname,
    positiveclass;
    sensitivity = 0.95,
    )

# Evaluate performance of multilayer perceptron on testing set
PredictMD.singlelabelbinaryclassificationmetrics(
    knetmlpclassifier,
    testing_features_df,
    testing_labels_df,
    labelname,
    positiveclass;
    sensitivity = 0.95,
    )

##############################################################################
##############################################################################
## Section 5: Compare performance of all models ##############################
##############################################################################
##############################################################################

all_models = PredictMD.Fittable[
    logisticclassifier,
    rfclassifier,
    csvc_svmclassifier,
    nusvc_svmclassifier,
    knetmlpclassifier,
    ]

# Compare performance of all models on smoted training set
showall(PredictMD.singlelabelbinaryclassificationmetrics(
    all_models,
    training_features_df,
    training_labels_df,
    labelname,
    positiveclass;
    sensitivity = 0.95,
    ))
showall(PredictMD.singlelabelbinaryclassificationmetrics(
    all_models,
    training_features_df,
    training_labels_df,
    labelname,
    positiveclass;
    specificity = 0.95,
    ))
showall(PredictMD.singlelabelbinaryclassificationmetrics(
    all_models,
    training_features_df,
    training_labels_df,
    labelname,
    positiveclass;
    maximize = :f1score,
    ))
showall(PredictMD.singlelabelbinaryclassificationmetrics(
    all_models,
    training_features_df,
    training_labels_df,
    labelname,
    positiveclass;
    maximize = :cohen_kappa,
    ))

# Compare performance of all models on testing set
showall(PredictMD.singlelabelbinaryclassificationmetrics(
    all_models,
    testing_features_df,
    testing_labels_df,
    labelname,
    positiveclass;
    sensitivity = 0.95,
    ))
showall(PredictMD.singlelabelbinaryclassificationmetrics(
    all_models,
    testing_features_df,
    testing_labels_df,
    labelname,
    positiveclass;
    specificity = 0.95,
    ))
showall(PredictMD.singlelabelbinaryclassificationmetrics(
    all_models,
    testing_features_df,
    testing_labels_df,
    labelname,
    positiveclass;
    maximize = :f1score,
    ))
showall(PredictMD.singlelabelbinaryclassificationmetrics(
    all_models,
    testing_features_df,
    testing_labels_df,
    labelname,
    positiveclass;
    maximize = :cohen_kappa,
    ))

# Plot receiver operating characteristic curves for all models on testing set.
rocplottesting = PredictMD.plotroccurves(
    all_models,
    testing_features_df,
    testing_labels_df,
    labelname,
    positiveclass,
    )
PredictMD.open_plot(rocplottesting)

# Plot precision-recall curves for all models on testing set.
prplottesting = PredictMD.plotprcurves(
    all_models,
    testing_features_df,
    testing_labels_df,
    labelname,
    positiveclass,
    )
PredictMD.open_plot(prplottesting)

##############################################################################
##############################################################################
### Section 6: Save trained models to file (if desired) #######################
##############################################################################
##############################################################################

if get(ENV, "SAVETRAINEDMODELSTOFILE", "") == "true"
    PredictMD.save_model(logisticclassifier_filename, logisticclassifier)
    PredictMD.save_model(rfclassifier_filename, rfclassifier)
    PredictMD.save_model(csvc_svmclassifier_filename, csvc_svmclassifier)
    PredictMD.save_model(nusvc_svmclassifier_filename, nusvc_svmclassifier)
    PredictMD.save_model(knetmlp_filename, knetmlpclassifier)
end

##############################################################################
##############################################################################
## Appendix A: Directly access the output of classification models ###########
##############################################################################
##############################################################################

# We can use the PredictMD.predict_proba() function to get the probabilities output
# by each of the classification models.

# Get probabilities from each model for smoted training set
PredictMD.predict_proba(logisticclassifier,smoted_training_features_df,)
PredictMD.predict_proba(rfclassifier,smoted_training_features_df,)
PredictMD.predict_proba(csvc_svmclassifier,smoted_training_features_df,)
PredictMD.predict_proba(nusvc_svmclassifier,smoted_training_features_df,)
PredictMD.predict_proba(knetmlpclassifier,smoted_training_features_df,)

# Get probabilities from each model for testing set
PredictMD.predict_proba(logisticclassifier,testing_features_df,)
PredictMD.predict_proba(rfclassifier,testing_features_df,)
PredictMD.predict_proba(csvc_svmclassifier,testing_features_df,)
PredictMD.predict_proba(nusvc_svmclassifier,testing_features_df,)
PredictMD.predict_proba(knetmlpclassifier,testing_features_df,)

# If we want to get predicted classes instead of probabilities, we can use the
# PredictMD.predict() function to get the class predictions output by each of the
# classification models. For each sample, PredictMD.predict() will select the class
# with the highest probability. In the case of binary classification, this is
# equivalent to using a threshold of 0.5.

# Get class predictions from each model for smoted training set
PredictMD.predict(logisticclassifier,smoted_training_features_df,)
PredictMD.predict(rfclassifier,smoted_training_features_df,)
PredictMD.predict(csvc_svmclassifier,smoted_training_features_df,)
PredictMD.predict(nusvc_svmclassifier,smoted_training_features_df,)
PredictMD.predict(knetmlpclassifier,smoted_training_features_df,)

# Get class predictions from each model for testing set
PredictMD.predict(logisticclassifier,testing_features_df,)
PredictMD.predict(rfclassifier,testing_features_df,)
PredictMD.predict(csvc_svmclassifier,testing_features_df,)
PredictMD.predict(nusvc_svmclassifier,testing_features_df,)
PredictMD.predict(knetmlpclassifier,testing_features_df,)
