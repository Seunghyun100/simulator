include("compiler/mapper.jl")
include("configuration/circuit-configuration.jl")
include("configuration/hardware-configuration.jl")
include("function/circuit-generator.jl")

"""
This part is setting to provider.
"""

sim = true
provider = nothing

# whether or not simulation
while true
    print("Do you simulate? (y/n)")
    local ans = readline()
    println()
    if ans =="y"
        global sim = true
        return
    elseif ans =="n"
        global sim = false
        return
    end
end

if sim
    include("function/simulator.jl")
    provider = Simulator
else
    provider = nothing # TODO: set the actual hardware
    error("The execution on real hardware isn't yet built")
end

"""
This part is setting to configuration.
Only configuration by file is yet possible.
"""
circuitConfigPath = ""
hardwareConfigPath = ""
communicationConfigPath = ""

CircuitConfiguration.openConfigFile(circuitConfigPath)

configuration = nothing # TODO: how set the configuration of circuit and hardware


# provider.run()
