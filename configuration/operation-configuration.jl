module OperationConfiguration
    import JSON

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
        qubits::Array
        fidelity::Fidelity
        function MultiGate(name::String="None", duration::Float64=0.0, 
            noOfQubits::Int64=2, qubits::Array=[], fidelity::Fidelity=Fidelity())
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

    function configure(configType::String, operation::String, specification::Array{Array{Any,1},1})::Tuple
        config = nothing
        ex = "$operation = $configType("
        for i in specification
            ex = ex * i[2]*','
        end
        ex = ex * ')'
        config = eval(ex)
        return (configType, config)
    end

    function openConfigFile(filePath::String = nothing)::Dict
        if filePath === nothing 
            currentPath = pwd()
            filePath = currentPath * "/input/operation_configuraiton.json"
        end

        configuraiton = nothing 

        configJSON = JSON.parsefile(filePath)
        configTypes = keys(configJSON)

        for configType in configTypes
            for operation in configJSON[configType]
                specification = configType[oepration]
                config = configure(configType, operation, specification)
                configuraiton[config[1]] = config[2]
            end
        end
        return configuration
    end
end