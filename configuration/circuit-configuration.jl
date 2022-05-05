module CircuitConfiguration

    abstract type Operation end
    abstract type Gate <: Operation end

    mutable struct CircuitQubit
        id::Int64
        operations::Array{Operation}
    end

    mutable struct Circuit
        noOfQubits::Int64
        qubits::Array{CircuitQubit}
    end

    """
    This part is about operations.
    """

    struct Fidelity
        errorRate::Float64
        dependOnHeat::Float64 # TODO
        function fidelity(errorRate::Float64=0.0, dependOnHeat::Float64=0.0)
            @assert(0.0<=errorRate<=1.0,"Out of range of the error rate that between 0.0 to 1.0")
            new(errorRate,dependOnHeat)
        end
    end

    struct SingleGate <: Gate
        name::String
        duration::Float64
        fidelity::Fidelity
        function singleGate(name::String="None", duration::Float64=0.0, fidelity::Fidelity=fidelity())
            @assert(name=="None", "You must name the single gate.")
            if duration ==0.0
                @info "The duration of operation is 0"
            end
            new(name, duration, fidelity)
        end
    end

    struct MultiGate <: Gate
        name::String
        duration::Float64
        fidelity::Fidelity
        noOfQubits::Int64
        qubits::Array{CircuitQubit}
    end

    struct Initilization <: Operation
        duration::Float64
        fidelity::Fidelity
    end

    struct Measure <: Operation
        name::String
        duration::Float64
        fidelity::Fidelity
    end

    function configure(configType::String, specification::Tuple{Vararg{Tuple{String, Any}}})::Tuple
        config = nothing
        ex = "$configType("
        for i in specification
            ex = ex * i[2]*','
        end
        ex = ex * ')'
        config = eval(ex)
        return (configType, config)
    end

    function openConfigFile(filePath::String)::Dict
        configuration = Dict()
        
        # TODO: parsing the configuration file
        while true
            configType = nothing
            specification = nothing
            config = configure(configType, specification)
            configuration[config[1]] = config[2]
        end

        return configuration
    end
end
