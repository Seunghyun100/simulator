module OperationConfiguration

    abstract type operation end

    struct error
        dependOfHeat::Float64
        errorRate::Float64
    end

    struct singleQubitGate <:operation
        type::String # i.e., rotation, Crifford etc.
        name::String
        duration::Float64
    end

    struct multiQubitGate <:operation
        noOfQubits::Int64
        name::String
        qubits::Array{int,1}
        duration::Float64
    end

    struct measurement <:operation
        type::String
        duration::Float64
    end

    struct initilization <:operation
        duration::Float64
    end
end

module CircuitConfiguration
    import operationConfiguration

    struct qubit
        quantumState
        qubitState::String # whether could apply operation
        operations::Array{::operation,1}
    end

    struct circuit
        noOfQutbi::Int64
        qubits::Array{::qubit,1}
    end

    struct multiQubitGate
        operation
    end
end