module CircuitBuilder
    import ..OperationConfiguration

    operationConfigPath = ""
    operationConfiguration = OperationConfiguration.openConfigFile(operationConfigPath)

    multiGateTable = Dict{Int64, Vector{Qubit}}
    multiGateID = 1

    mutable struct CircuitQubit
        id::String
        operations::Vecotr{Operation}
        function CircuitQubit(id::String, operations::Vector{Operation}=Operation[])
            new(id, operations)
        end
    end

    mutable struct Circuit
        name::String
        qubits::Vector{CircuitQubit}
        function Circuit(noOfQubits::Int64, qubits::Vector{CircuitQubit})
            new(noOfQubits, qubits)
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
    function encodeOperation(composition::Vector)
        operationName = composition[1]
        appliedQubits = composition[2:length(composition)]
        operationMold = operationConfiguration[operationName]
        operation = deepcopy(operationMold)
        operation.id = multiGateID
        multiGateTable[multiGateID] = appliedQubits
        multiGateID +=1
        return operation
    end

    function composeCircuitQubit(qubits::Vector{CircuitQubit}, qubitComposition::Tuple)
        qubitID = qubitComposition[1]
        compositions = qubitComposition[2]
        operations = Operation[]
        for composition in compositions
            oepration = encodeOperation(composition)
            push!(operations, oepration)
        end
        for qubit in qubits
            if qubitID == qubit.id
                qubit.operations = operations
            end
        end
    end
    
    function buildCircuit(circuitConfig)
        circuitName = circuitConfig["name"]
        
        noOfQubits = circuitConfig["number_of_qubits"]

        qubits = CircuitQubit[]

        for qubitComposition in circuitConfig["qubits"]
            circuitQubit = CircuitQubit(qubitComposition[1])
            push!(qubits, circuitQubit)
        end
        for qubitComposition in circuitConfig["qubits"]
            composeCircuitQubit(qubits, qubitComposition)
        end
        
        circuit = Circuit(circuitName, qubits)
        return circuit
    end


    function openCircuitFile(filePath::String)
        if filePath === "" 
            currentPath = pwd()
            filePath = currentPath * "/input/circuit.json"
        end

        @assert(configJSON = JSON.parsefile(filePath),"PathError: There's not the file")

        circuits = Dict()
        for circuitConfig in values(configJSON)
            circuitName = circuitConfig["name"]
            circuitList[circuitName] = Dict(
                "circuit"=>buildCircuit(circuitConfig),
                "multiGateTable"=>multiGateTable
            )

        end
        return circuits    
    end

end