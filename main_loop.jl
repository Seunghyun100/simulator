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
results = Dict()
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
        if ans == "QCCD-Grid-30"
            provider = QCCDSimulator
        elseif ans == "QCCD-Grid-20"
            provider = QCCDSimulator
        elseif ans == "QCCD-Grid-15"
            provider = QCCDSimulator
        elseif ans == "QCCD-Grid-10"
            provider = QCCDSimulator
        elseif ans == "QCCD-Comb-30"
            provider = QCCDSimulator
        elseif ans == "QCCD-Comb-20"
            provider = QCCDSimulator
        elseif ans == "QCCD-Comb-15"
            provider = QCCDSimulator
        elseif ans == "QCCD-Comb-10"
            provider = QCCDSimulator
        elseif ans =="Q-bus-30"
            provider = QBusSimulator
        elseif ans =="Q-bus-20"
            provider = QBusSimulator
        elseif ans =="Q-bus-15"
            provider = QBusSimulator
        elseif ans =="Q-bus-10"
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
    if architectureName == "Q-bus-30"||architectureName =="Q-bus-20"||architectureName =="Q-bus-15"||architectureName =="Q-bus-10"
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

    if architectureName == "Q-bus-30"||architectureName =="Q-bus-20"||architectureName =="Q-bus-15"||architectureName =="Q-bus-10"
        result = provider.run(circuit, configuration, shuttlingTypeIndex)
        if architectureName ∉ keys(results)
            results[architectureName] = Dict()
        end
        if "$shuttlingTypeIndex" ∉ keys(results[architectureName])
            results[architectureName]["$shuttlingTypeIndex"] = Dict()
        end
        results[architectureName]["$shuttlingTypeIndex"][circuitName] = result[1]
    else
        result = provider.run(circuit, configuration)
        if architectureName ∉ keys(results)
            results[architectureName] = Dict()
        end
        results[architectureName][circuitName] = result[1]
    end
end


# provider.printResult(result...)

experiments = []
algorithms = ["quantum-fourier-transformation-60", "bernstein-vazirani-60","qaoa-60","grover-6x6"]
# QCCDs = ["QCCD-Grid-30","QCCD-Grid-20","QCCD-Grid-15","QCCD-Grid-10","QCCD-Comb-30","QCCD-Comb-20","QCCD-Comb-15","QCCD-Comb-10"]
# QBUSs = ["Q-bus-30","Q-bus-20","Q-bus-15","Q-bus-10"]

# QCCDs = ["QCCD-Grid-30","QCCD-Comb-30"]
QBUSs = ["Q-bus-30","Q-bus-20","Q-bus-15","Q-bus-10"]
for algorithm in algorithms
    # for arch in QCCDs
    #     mainLoop(arch, algorithm)
    # end
    for arch in QBUSs
        for i in 1:4
            mainLoop(arch, algorithm, string(i))
        end
    end
end

# save the results
using JSON

output = JSON.json(results)

open("experiment_result.json","w") do f 
    JSON.write(f, output) 
end