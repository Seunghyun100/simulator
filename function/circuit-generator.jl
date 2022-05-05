module CircuitGenerator
    using ..OperationConfiguration
    
    mutable struct CircuitQubit
        id::Int64
        operations::Array{Operation}
        function CircuitQubit(id::Int64, operations::Array{Operation}=[])
            new(id, oeprations)
        end
    end

    mutable struct Circuit
        noOfQubits::Int64
        qubits::Array{CircuitQubit}
        function Circuit(noOfQubits::Int64, qubits::Array{CircuitQubit})
            new(noOfQubits, qubits)
        end
    end

    function openCircuitFile(filePath::String)
    end

    function incodeCircuit()

    end
end