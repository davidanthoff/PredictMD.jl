ENV["PREDICTMD_IS_RUNTESTS"] = "true"

import PredictMDExtra

include(joinpath(".", "import-predictmd.jl"))

include(joinpath(".", "define-test-groups.jl"))

include(joinpath(".", "define-test-blocks.jl"))

include(joinpath(".", "get-test-group.jl"))

include(joinpath(".", "set-predictmd-test-plots.jl"))

include(joinpath(".", "set-predictmd-open-plots-during-tests.jl"))

include(joinpath(".", "all-testsets.jl"))

ENV["PREDICTMD_IS_RUNTESTS"] = "false"

