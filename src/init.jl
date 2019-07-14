import Requires

function __init__()::Nothing
    Requires.@require MLJ="add582a8-e3ab-11e8-2d5e-e98b27df1bc7" begin
        Requires.@require MLJBase="a7f614a8-145f-11e9-1d2a-a57a1082229d" begin
            Requires.@require MLJModels="d491faf4-2d78-11e9-2867-c94bc002c0b7" begin
                include("toplevel/conditionally-loaded/mlj/mlj.jl")
                @info("PredictMD: the following backends are now available: MLJ, MLJBase, MLJModels")
            end
        end
    end

    print_welcome_message()
    return nothing
end
