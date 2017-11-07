using MLBase
using NamedArrays
using ScikitLearn

@sk_import metrics: accuracy_score
@sk_import metrics: auc
@sk_import metrics: average_precision_score
@sk_import metrics: brier_score_loss
@sk_import metrics: f1_score
@sk_import metrics: precision_recall_curve
@sk_import metrics: precision_score
@sk_import metrics: recall_score
@sk_import metrics: roc_auc_score
@sk_import metrics: roc_curve

struct ModelPerformance <: AbstractModelPerformance
    blobs::T where T <: Associative
end

function ModelPerformance(model::AbstractModel)
    error("Not yet implemented for this model type.")
end

function ModelPerformance(model::AbstractSingleLabelBinaryClassifier)
    blobs = Dict{Symbol, Any}()

    ytrue_training = model.blobs[:true_labels_training]
    blobs[:num_training] = size(ytrue_training,1)
    ypredlabel_training = model.blobs[:predicted_labels_training]
    ypredproba_training = model.blobs[:predicted_proba_training]
    blobs[:accuracy_training] = accuracy_score(
        ytrue_training,
        ypredlabel_training,
        )
    blobs[:auroc_training] = roc_auc_score(
        ytrue_training,
        ypredproba_training,
        )

    ytrue_validation = model.blobs[:true_labels_validation]
    blobs[:num_validation] = size(ytrue_validation,1)
    ypredlabel_validation = model.blobs[:predicted_labels_validation]
    ypredproba_validation = model.blobs[:predicted_proba_validation]
    blobs[:accuracy_validation] = accuracy_score(
        ytrue_validation,
        ypredlabel_validation,
        )
    blobs[:auroc_validation] = roc_auc_score(
        ytrue_validation,
        ypredproba_validation,
        )

    ytrue_testing = model.blobs[:true_labels_testing]
    blobs[:num_testing] = size(ytrue_testing,1)
    ypredlabel_testing = model.blobs[:predicted_labels_testing]
    ypredproba_testing = model.blobs[:predicted_proba_testing]
    blobs[:accuracy_testing] = accuracy_score(
        ytrue_testing,
        ypredlabel_testing,
        )
    blobs[:auroc_testing] = roc_auc_score(
        ytrue_testing,
        ypredproba_testing,
        )

    return ModelPerformance(blobs)
end

function Base.show(io::IO, mp::ModelPerformance)
    summary_table = generate_summary_table(mp)
    println(io, "Summary: ")
    println(io, "=======")
    println(io, summary_table)
end

function generate_summary_table(mp::ModelPerformance)
    unnamed_array = [
        mp.blobs[:accuracy_training] mp.blobs[:auroc_training];
        mp.blobs[:accuracy_validation] mp.blobs[:auroc_validation];
        mp.blobs[:accuracy_testing] mp.blobs[:auroc_testing];
        ]
    summary_table = NamedArray(unnamed_array)
    setnames!(
        summary_table,
        [
            "Training (n=$(mp.blobs[:num_training]))",
            "Validation (n=$(mp.blobs[:num_validation]))",
            "Testing (n=$(mp.blobs[:num_testing]))",
            ],
        1,
        )
    setnames!(
        summary_table,
        [
            "Accuracy",
            "AUROC",
            ],
        2,
        )
    return summary_table
end
