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
        function Fidelity(errorRate::Float64=0.0, dependOnHeat::Float64=0.0)
            @assert(0.0<=errorRate<=1.0,"Out of range of the error rate that between 0.0 to 1.0")
            new(errorRate,dependOnHeat)
        end
    end

    struct SingleGate <: Gate
        name::String
        duration::Float64
        fidelity::Fidelity
        function SingleGate(name::String="None", duration::Float64=0.0, fidelity::Fidelity=Fidelity())
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
        noOfQubits::Int64
        qubits::Array{CircuitQubit}
        fidelity::Fidelity
        function MultiGate(name::String="None", duration::Float64=0.0, 
            noOfQubits::Int64=2, qubits::Array{CircuitQubit}=[], fidelity::Fidelity=Fidelity())
            @assert(name=="None", "You must name the multi gate.")
            if duration ==0.0
                @info "The duration of operation is 0"
            end
            @info "It it $noOfQubits-qubits gate."
            new(name,duration, noOfQubits, qubits, fidelity)
        end
    end

    struct Initialization <: Operation
        duration::Float64
        fidelity::Fidelity
        function Initialization(duration::Float64=0.0, fidelity::Fidelity=Fidelity())
            if duration ==0.0
                @info "The duration of operation is 0"
            end
            new(duration, fidelity)
        end
    end

    struct Measure <: Operation
        name::String
        duration::Float64
        fidelity::Fidelity
        function Measure(name::String="common", duration::Float64=0.0, fidelity::Fidelity=Fidelity())
            if name == "common"
                @info "The measure type is common."
            end
            if duration ==0.0
                @info "The duration of operation is 0"
            end
            new(name, duration, fidelity)
        end
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
