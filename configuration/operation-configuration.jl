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
    qubits::Array
    duration::Float64
end

struct measurement <:operation
    type::String
    duration::Float64
end

struct initilization <:operation
    duration::Float64
end
