module Simulator
end

Base.include("/compiler/mapping.jl")
Base.include("/compiler/schduling.jl")

sim::Bool # TODO: whether or not using a simulator
provider = nothing

configuration::Tuple{} # TODO: how set the configuration of circuit and hardware

if sim
    import Simulator
    provider = nothing # TODO: set the simulator
else
    provider = nothing # TODO: set the actual hardware
end

provider.run()
