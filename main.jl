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

print("Do you simulate? (y/n)\n")
# ans = readline()
println("y")
ans = "y"
# println(ans)
if ans =="y"
    sim = true
elseif ans =="n"
    sim = false
else
    error("Pleas answer to y or n.")
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
architectureConfigurationList = ArchitectureConfiguration.openConfigFile(architectureConfigPath)
# communicationConfiguration = CommunicationConfiguration.openConfigFile(communicationConfigPath)

println()
println("What is the architecture you simulate? \n (pleas answer the architecture name)")
# for name in keys(architectureConfigurationList)
#     println(name)
# end
println()
ans = readline()
println()

configuration = Dict("operation"=>operationConfiguration, "architecture"=>architectureConfigurationList[ans])


if sim
    include("function/simulator.jl")
    if ans[1:1] == "b"
        provider = QBusSimulator
        println("QBusSimulator")
    else
        provider = QCCDSimulator
    end
else
    provider = nothing # TODO: set the actual hardware
    error("The execution on real hardware isn't yet built")
end

"""
This part is mapping to initial topology configuration to minimize the inter-core communication for input quantum circuit.
Only generating circuit by file is yet possible.
"""

circuitFilePath = ""

circuitList = CircuitBuilder.openCircuitFile(circuitFilePath)

println()
println("What is the quantum circuit you simulate? \n (pleas answer the circuit name)")
# for name in keys(circuitList)
#     println(name)
# end
println()
ans = readline()
println()

circuit = circuitList[ans]

 # TODO: optimize the mapping algorithm채ㅡㅠ
Mapper = NonOptimizedMapper
Mapper.mapping(circuit, configuration["architecture"])

"""
This part is running the provider with scheduling.
"""
# provider.run(mappedCircuit) #TODO

# result = provider.run(circuit, configuration, "4")
result = provider.run(circuit, configuration)

provider.printResult(result...)
