include("compiler/mapper.jl")
include("configuration/operation_configuration.jl")
include("configuration/architecture_configuration.jl")
include("configuration/communication_configuration.jl")
include("function/circuit_builder.jl")
include("function/simulator.jl")


"""
This part is setting to provider.
"""

sim = true
provider = nothing

# whether or not simulation

print("Do you simulate? (y/n)")
local ans = readline()
println()
if ans =="y"
    sim = true
elseif ans =="n"
    sim = false
else
    error("Pleas answer to y or n.")
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

# TODO: how set the configuration of circuit and hardware
operationConfigPath = ""
architectureConfigPath = ""
# communicationConfigPath = ""

operationConfiguration = OperationConfiguration.openConfigFile(operationConfigPath)
architectureConfigurationList = HardwareConfiguration.openConfigFile(architecutureConfigPath)
# communicationConfiguration = CommunicationConfiguration.openConfigFile(communicationConfigPath)

println("What is the architecture you simulate? \n (pleas answer the architecture name)")
for name in keys(architectureConfigurationList)
    println(name)
end
ans = readline()
println()

configuration = ("operation"=>operationConfiguration, "architecture"=>architectureConfigurationList[ans])


"""
This part is mapping to initial topology configuraiton to minimize the inter-core communication for input quantum circuit.
Only generating circuit by file is yet possible.
"""

circuitFilePath = ""

circuitList = CircuitBuilder.openCircuitFile(circuitFilePath)

println("What is the quantum circuit you simulate? \n (pleas answer the circuit name)")
for name in keys(circuitList)
    println(name)
end
ans = readline()
println()

circuit = circuitList[ans]

Mapper.mapping(circuit, configuration["architecture"]) # TODO: optimize the mapping algorithm

"""
This part is running the provider with scheduling.
"""
# provider.run(mappedCircuit) #TODO

result = Simulator.run(circuit, configuration)
Simulator.printResult(result)
