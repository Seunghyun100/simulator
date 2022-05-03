struct qubit
    state
    operations::Array
end

struct circuit
    noOfQutbi::Int64
    qubits::Array{::qubit}
end

struct multiQubitGate
    operation