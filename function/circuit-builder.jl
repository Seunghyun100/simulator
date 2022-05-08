module CircuitBuilder
    using ..OperationConfiguration

    mutable struct CircuitQubit
        id::Int64
        operations::Vecotr{Operation}
        function CircuitQubit(id::Int64, operations::Vector{Operation}=Operation[])
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
    # TODO: Include oepration configuration
    # Single-Gate
    function incodeOperation(operationConfig::String)
    end

    # Multi-Gate
    function incodeOperation(operationConfig::Vector)
    end

    function geneateCircuitQubit(qubitComposition::Tuple)
        qubitID = qubitComposition[1]
        operationsConfig = qubitComposition[2]
        operations = Operation[]
        for operationConfig in operationsConfig
            oepration = incodeOperation(operationConfig)
            push!(operations, oepration)
        end
        circuitQubit = CircuitQubit(qubitID, operations)
        return circuitQubit
    end
    
    function buildCircuit(circuitConfig)
        circuitName = circuitConfig["name"]
        
        noOfQubits = circuitConfig["number_of_qubits"]
        qubits = CircuitQubit[]
        for qubitComposition in circuitConfig["qubits"]
            circuitQubit = generateCircuitQubit(qubitComposition)
            push!(qubits, circuitQubit)
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
            circuitList[circuitName] = buildCircuit(circuitConfig)
        end
        return circuits    
    end

end