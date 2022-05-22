module OperationConfiguration
    import JSON
    export Operation

    abstract type Operation end
    abstract type Gate <: Operation end

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
            @assert(name!=="None", "You must name the single gate.")
            if duration ==0.0
                @info "The duration of operation is 0"
            end
            new(name, duration, fidelity)
        end
    end

    mutable struct MultiGate <: Gate
        name::String
        duration::Float64
        noOfQubits::Int64
        fidelity::Fidelity
        id::Int64
        function MultiGate(name::String="None", duration::Float64=0.0, 
            noOfQubits::Int64=2, fidelity::Fidelity=Fidelity(), id::Int64=0)
            @assert(name!=="None", "You must name the multi gate.")
            if duration ==0.0
                @info "The duration of operation is 0"
            end
            # @info "It is $noOfQubits-qubits gate."
            new(name,duration, noOfQubits, fidelity, id)
        end
    end

    struct Initialize <: Operation
        duration::Float64
        fidelity::Fidelity
        function Initialize(duration::Float64=0.0, fidelity::Fidelity=Fidelity())
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

    
    """
    This part is about the configuration functions.
    """
    function configure(configType::String, operation::String, specification::Vector{Any})::Tuple
        config = nothing
        ex = "$operation = $configType("
        for i in specification
            if i[1] == "name"
                ex = ex *'"'* i[2]*'"'*','
            else
                ex = ex * i[2]*','
            end
        end
        ex = ex * ')'
        ex = Meta.parse(ex)
        config = eval(ex)
        return (operation, config)
    end

    function openConfigFile(filePath::String = "")::Dict
        if filePath === "" 
            currentPath = pwd()
            filePath = currentPath * "/input/operation_configuration.json"
        end

        configuration = Dict() 

        configJSON = JSON.parsefile(filePath)
        configTypes = keys(configJSON)

        for configType in configTypes
            for operation in configJSON[configType]
                specification = operation[2]
                config = configure(configType, operation[1], specification)
                configuration[config[1]] = config[2]
            end
        end
        return configuration
    end

end
