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
results = Dict([("Q-bus",Dict([(1,Dict()),(2,Dict()),(3,Dict()),(4,Dict())])),("QCCD-Comb",Dict()),("QCCD-Grid",Dict())])
# whether or not simulation

# print("Do you simulate? (y/n)\n")
# ans = readline()
# # println(ans)
# if ans =="y"
#     sim = true
# elseif ans =="n"
#     sim = false
# else
#     error("Pleas answer to y or n.")
# end


"""
This part is setting to configuration.
Only configuration by file is yet possible.
"""
function mainLoop(architectureName, circuitName, shuttlingTypeIndex = 4)
    # TODO: how set the configuration of circuit and hardware
    operationConfigPath = ""
    architectureConfigPath = ""
    # communicationConfigPath = ""

    operationConfiguration = OperationConfiguration.openConfigFile(operationConfigPath)
    architectureConfigurationList = ArchitectureConfiguration.openConfigFile(architectureConfigPath)
    # communicationConfiguration = CommunicationConfiguration.openConfigFile(communicationConfigPath)

    println()
    println("What is the architecture you simulate? \n (pleas answer the architecture name)")
    for name in keys(architectureConfigurationList)
        println(name)
    end
    println()
    # ans = readline() # architecture name
    ans = architectureName
    println(ans)
    println()

    configuration = Dict("operation"=>operationConfiguration, "architecture"=>architectureConfigurationList[ans])


    if sim
        include("function/simulator.jl")
        if ans == "QCCD-Grid"
            provider = QCCDSimulator
        elseif ans == "QCCD-Comb"
            provider = QCCDSimulator
        elseif ans =="Q-bus"
            provider = QBusSimulator
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
    for name in keys(circuitList)
        println(name)
    end
    println()
    # ans = readline() # circuit name
    ans = circuitName
    println(ans)
    println()

    circuit = circuitList[ans]

    """
    If architecture is Q-bus, Choose the shuttling and detection types
    """
    if architectureName == "Q-bus"
        println()
        println("What is the shuttling type? \n (answer the number)")

        shuttlingTypes = Dict([
            ("1", "Slow Junction Rotation & Normal Detection"),
            ("2", "Slow Junction Rotation & SNSD"),
            ("3", "Fast Junction Rotation & Normal Detection"),
            ("4", "Fast Junction Rotation & SNSD")])

        for i in 1:4
            shuttlingType = shuttlingTypes["$i"]
            println("$i. $shuttlingType")
        end
        println()
        # ans = readline() # shuttling types
        ans = shuttlingTypeIndex
        println(ans)
    end

    # TODO: optimize the mapping algorithm
    Mapper = NonOptimizedMapper
    Mapper.mapping(circuit, configuration["architecture"])

    """
    This part is running the provider with scheduling.
    """
    # provider.run(mappedCircuit) #TODO

    if architectureName == "Q-bus"
        result = provider.run(circuit, configuration, shuttlingTypeIndex)
        results[architectureName][shuttlingType] = result
    else
        result = provider.run(circuit, configuration)
        results[architectureName] = result
    end
end


# provider.printResult(result...)

experiments = [("Q-bus","example")]

# save the results
output = JSON.json(result)

open("$name.json","w") do f 
    JSON.write(f, output) 