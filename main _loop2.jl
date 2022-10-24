

using JSON


"""
This part is setting to provider.
"""

# sim = true
# provider = nothing

# # whether or not simulation

# # print("Do you simulate? (y/n)\n")
# # ans = readline()
# # println("y")
# ans = "y"
# # println(ans)
# if ans =="y"
#     sim = true
# elseif ans =="n"
#     sim = false
# else
#     error("Pleas answer to y or n.")
# end

# if sim
#     include("function/simulator.jl")
# else
#     provider = nothing # TODO: set the actual hardware
#     error("The execution on real hardware isn't yet built")
# end

for cir in ["bv"]
    resultsSet = Dict()
    for i in 2:3
        cirName = "$cir$i"
        resultsSet[cirName] = Dict()
        for arch in ["bus", "comb", "single-core"]
            if arch != "single-core"
                archName = "$arch$i"
            else
                archName = arch
            end

            println("######################")
            println("Circuit: $cirName")
            include("function/circuit_builder.jl")
            circuitFilePath = ""
            circuitList = CircuitBuilder.openCircuitFile(circuitFilePath)
            circuit = circuitList[cirName]

            QbusCheck = false     
            println()   
            println("architecture: $archName")

            """
            This part is setting to configuration.
            Only configuration by file is yet possible.
            """

            include("compiler/mapper.jl")
            include("configuration/operation_configuration.jl")
            include("configuration/architecture_configuration.jl")
            include("configuration/communication_configuration.jl")
            include("function/simulator.jl")


            # TODO: how set the configuration of circuit and hardware
            operationConfigPath = ""
            architectureConfigPath = ""
            # communicationConfigPath = ""

            operationConfiguration = OperationConfiguration.openConfigFile(operationConfigPath)
            architectureConfigurationList = ArchitectureConfiguration.openConfigFile(architectureConfigPath)
            # communicationConfiguration = CommunicationConfiguration.openConfigFile(communicationConfigPath)

            configuration = Dict("operation"=>operationConfiguration, "architecture"=>architectureConfigurationList[archName])
            if archName[1:1] == "c"
                provider = QCCDSimulator
            else
                provider = QBusSimulator
                QbusCheck = true
            end
            """
            This part is mapping to initial topology configuration to minimize the inter-core communication for input quantum circuit.
            Only generating circuit by file is yet possible.
            """


            Mapper = NonOptimizedMapper
            Mapper.mapping(circuit, configuration["architecture"])



            """
            This part is running the provider with scheduling.
            """
            # provider.run(mappedCircuit) #TODO
            if QbusCheck
                output = provider.run(circuit, configuration, "4")
            else
                output = provider.run(circuit, configuration)
            end
            resultsSet[cirName][archName] = output[1]
            println(resultsSet)
            provider.printResult(output...)
        end
    end

    # save the results to json file
    
    output = JSON.json(resultsSet)
    open("result_$cir.json","w") do f 
        JSON.write(f, output) 
    end
end 