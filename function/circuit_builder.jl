module CircuitBuilder
    import JSON
    include("../configuration/operation_configuration.jl")

    operationConfigPath = ""
    operationConfiguration = OperationConfiguration.openConfigFile(operationConfigPath)


    mutable struct CircuitQubit
        id::String
        operations::Vector
        function CircuitQubit(id::String="dummy", operations::Vector=[])
            new(id, operations)
        end
    end

    mutable struct Circuit
        name::String
        qubits::Vector{CircuitQubit}
        function Circuit(name::String, qubits::Vector{CircuitQubit})
            new(name, qubits)
        end
    end

    
    """
    This part is about the method to build circuits.
    """

    # Single-Gate, Initialization, Measurement
    function encodeOperation(composition::String)
        return operationConfiguration[composition]
    end

    # Multi-Gate
    function encodeOperation(composition::Vector, multiGateTable)
        multiGateID = composition[1]
        operationName = composition[2]
        appliedQubits = composition[3:length(composition)]
        operationMold = operationConfiguration[operationName]
        operation = deepcopy(operationMold)
        operation.id = multiGateID
        multiGateTable[multiGateID] = Dict()
        multiGateTable[multiGateID]["appliedQubits"] = appliedQubits
        multiGateTable[multiGateID]["isPreparedCommunication"] = false

        return operation
    end

    function composeCircuitQubit(qubits::Vector{CircuitQubit}, qubitComposition, multiGateTable) # (Vector, Pair)
        qubitID = qubitComposition[1]
        compositions = qubitComposition[2]
        operations = []
        noOperations1 = 0
        noOperations2 = 0

        for composition in compositions
            if typeof(composition) == Vector{Any}
                oepration = encodeOperation(composition, multiGateTable)
                noOperations2 += 0.5
            else
                oepration = encodeOperation(composition)
                noOperations1 += 1
            end
            push!(operations, oepration)
        end
        for qubit in qubits
            if qubitID == qubit.id
                qubit.operations = operations
            end
        end
        return [noOperations1, noOperations2]
    end
    
    function buildCircuit(circuitConfig, multiGateTable)
        circuitName = circuitConfig["name"]
        
        noOfQubits = circuitConfig["number_of_qubits"]

        qubits = CircuitQubit[]
        totalNoOperation = [0,0]

        qubitConfigList = []
        qubitConfigs = circuitConfig["qubits"]

        keyList = collect(keys(qubitConfigs))
        keyPairList = []
        for i in keyList
            push!(keyPairList, (parse(Int64, i[2:end]), i))
        end
        for keyPair in sort(keyPairList)
            push!(qubitConfigList, (keyPair[2], qubitConfigs[keyPair[2]]))
        end


        for qubitConfigPair in qubitConfigList
            circuitQubit = CircuitQubit(qubitConfigPair[1])
            push!(qubits, circuitQubit)
        end
        for qubitComposition in qubitConfigList
            totalNoOperation += composeCircuitQubit(qubits, qubitComposition, multiGateTable)
        end
        
        circuit = Circuit(circuitName, qubits)
        
        # check for performance calculation
        println("$circuitName: No.Operations $totalNoOperation , No.Qubits $(length(qubits))")
        
        return (circuit, multiGateTable)
    end


    function openCircuitFile(filePath::String)
        if filePath === "" 
            currentPath = pwd()
            filePath = currentPath * "/input/circuit.json"
        end
        configJSON = JSON.parsefile(filePath)

        # @assert(configJSON !== nothing,"PathError: There's not the file")

        

        circuits = Dict()
        for circuitConfig in values(configJSON)
            multiGateTable = Dict()
            circuitName = circuitConfig["name"]
            circuitPair = buildCircuit(circuitConfig, multiGateTable)
            circuits[circuitName] = Dict(
                "circuit"=> circuitPair[1],
                "multiGateTable"=> circuitPair[2]
            )

        end
        return circuits    
    end

end