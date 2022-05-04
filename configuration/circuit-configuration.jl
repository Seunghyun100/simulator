module CircuitConfiguration

abstract type Error end
abstract type Circuit end

abstract type Operation <: Circuit end
abstract type CircuitQubit <: Circuit end

abstract type Gate <: Operation end
abstract type Initialization <: Operation end
abstract type Measure <: Operation end

struct error <: Error
    dependOnHeat::Float64
    errorRate::Float64
end

struct singleGate <: Gate
    name::String
    duration::Float64
    error::error
    qubit::CircuitQubit
end

struct multiGate <: Gate
    name::String
    duration::Float64
    error::error
    noOfQubits::Int64
    qubits::Array{CircuitQubit}
end

struct initilization <: Initialization
    duration::Float64
    qubit::CircuitQubit
    error::error
end

struct measure <: Measure
    name::String
    duration::Float64
    qubit::CircuitQubit
    error::error
end

struct circuitQubit <: CircuitQubit
    id::Int64
    operations::Array{Operation}
end

struct circuit <: Circuit
    noOfQubits::Int64
    qubits::Array{CircuitQubit}
end
end