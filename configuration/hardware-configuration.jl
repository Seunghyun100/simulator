module HardwareConfiguration
    import ..OperationConfiguration
    import ..CircuitGenerator

    # Abstract type of hardware
    abstract type Circuit end
    abstract type Operation <: Circuit end

    # Abstract type of communication
    abstract type Communication end
    abstract type CommunicationChannel <: Communication end
    abstract type CommunicationOperation <: Communication end
    abstract type Shuttling <:CommunicationOperation end

    """
    This part is about the configuration for Hardware.
    """

    mutable struct ActualQubit
        id::Int64
        operationTime::Float64
        communicationTime::Float64
        intraConnectivity::Array{ActualQubit} # TODO
        runningOperations::Array # running oepration list
        circuitQubit::CircuitGenerator.CircuitQubit
        isCommunicationQubit::Bool
        fidelity::Float64
        function ActualQubit(id::Int64, operationTime::Float64=0.0, communicationTime::Float64=0.0,
            intraConnectivity::Array{ActualQubit}=[],runningOperations::Array=[], circuitQubit::CircuitQubit = nothing, 
            isCommunicationQubit::Bool=false, fidelity::Float64=1.0)
            new(id,operationTime,communicationTime,intraConnectivity, runningOperations,circuitQubit,isCommunicationQubit,fidelity)
        end
    end

    mutable struct Core
        id::Int64
        capacity::Int64
        noOfQubits::Int64
        qubits::Array{ActualQubit}
        noOfPhonons::Float64
        interConnectivity::Array{Core} # TODO
        function Core(id::Int64, capacity::Int64,  noOfQubits::Int64=0, qubits::Array{ActualQubit}=[],
            noOfPhonons::Float64=0.0,interConnectivity::Array{Core}=[])
            new(id, capacity, noOfQubits, qubits, noOfPhonons, interConnectivity)
        end
    end

    mutable struct Hardware
        noOfCores::Int64
        cores::Array{Core}
        totalTime::Float64
        function Hardware(noOfCores::Int64, cores::Array{Core}=[], totalTime::Float64=0.0)
            new(noOfCores, totalTime, cores)
    end


    """
    This part is about the configuration for communication.
    """

    mutable struct CommunicationQubit <:Communication
        interConnectivity::Array{Core}
        actualQubit::ActualQubit
        communicationTime::Float64
        noOfPhonons::Float64
        dwellTime::Float64
        inChannel::CommunicationChannel
        isCommunicating::Bool
        function CommunicationQubit(interConnectivity::Array{Core}, actualQubit::ActualQubit,communicationTime::FLoat64=0.0,
            noOfPhonons::Float64=0.0, dwellTime::Float64=0.0, inChannel::CommunicationChannel=nothing, isCommunicating::Bool=false)
            new(interConnectivity, actualQubit,communicationTime, noOfPhonons,dwellTime,inChannel, isCommunicating)
        end
    end

    mutable struct Path <: CommunicationChannel
        id::Int64
        connectedChannel::Tuple{CommunicationChannel, CommunicationChannel}
        length::Float64 # length of shuttling path to calculate shuttling duration
        isOccupied::Bool
        function Path(id::Int64, connectedChannel::Tuple{CommunicationChannel, CommunicationChannel}, length::Float64, isOccupide::Bool=false)
            new(id, connectedChannel, length, isOccupide)
        end
    end

    mutable struct Junction <: CommunicationChannel
        id::Int64
        connectedChannel::Tuple{Vararg{Path}}
        noOfPath::Int64
        isOccupied::Bool
        function Junction(id::Int64, connectedChannel::Tuple{Vararg{Path}}, noOfPath::Int64=length(connectedChannel), isOccupied::Bool=false)
            new(id, connectedChannel, noOfPath, isOccupied)
        end
    end

    mutable struct Edge <: CommunicationChannel
        id::Int64
        connectedChannel::Path
        connectedCore::Core
        isOccupied::Bool
        function Edge(id::Int64, connectedChannel::Path, connectedCore::Core, isOccupied::Bool=false)
            new(id, connectedChannel, connectedCore, isOccupied)
        end
    end

    struct LinearTransport <: Shuttling
        speed::Float64 # To calculate shuttling time of path
        heatingRate::Float64
        function LinearTransport(speed::Float64, heatingRate::Float64=0.0)
            @assert(speend>0.0, "Speed must be larger than 0.")
            new(speed, heatingRate)
        end
    end

    struct JunctionRotate <: Shuttling
        duration::Float64
        heatingRate::Float64
        toPath::Path
        function JunctionRotate(duration::Float64, heatingRate::Float64=0.0, toPath::Path=nothing)
            @assert(duraiton>0.0, "Duration must be larger than 0.")
            new(duration, heatingRate, toPath)
        end
    end

    struct Split <: Shuttling
        duration::Float64
        heatingRate::Tuple{Float64, Float64} # (Core, CommQubit)
        function Split(duration::Float64, heatingRate::Tuple{Float64, Float64}=(0.0, 0.0))
            @assert(duraiton>0.0, "Duration must be larger than 0.")
            new(duration, heatingRate)
        end
    end

    struct Merge <: Shuttling
        duration::Float64
        heatingRate::Float64
        function Merge(duration::Float64, heatingRate::Float64=0.0)
            @assert(duraiton>0.0, "Duration must be larger than 0.")
            new(duration, heatingRate)
    end


    """
    This part is about the configuraiton functions.
    """
 
    function buildHardware(noOfCores::Int64, noOfQubitsPerCore::Int64, capacity::Int64=noOfQubitsPerCore)
        @assert(noOfQubitsPerCore>capacity,"#qubits per core do NOT exceed capacity of core.")
        totalQubits = noOfCores*noOfQubitsPerCore
        hardware = Hardware(noOfCores)
        idOfQubit = 1
        for idOfCore in 1:noOfCores
            core = Core(idOfCore, capacity,noOfQubitsPerCore)
            for i in 1:noOfQubitsPerCore
                qubit = ActualQubit(idOfQubit)
                push!(core.qubits,qubit)
                idOfQubit += 1
            end
            push(hardware.cores,core)
        end
        return hardware
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

    function buildCommunicationChannel()
    end

    function openConfigFile(filePath::String = "")::Dict
        if filePath === "" 
            currentPath = pwd()
            filePath = currentPath * "/input/hardware_configuraiton.json"
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
