module HardwareConfiguration
    using ..OperationConfiguration
    using ..CircuitGenerator

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
        intraConnectivity::Array{ActualQubit}
        runningOperations::Array # running oepration list
        circuitQubit::CircuitQubit
        isCommunicationQubit::Bool
        error::Float64
        function ActualQubit(id::Int64, operationTime::Float64=0.0, communicationTime::Float64=0.0,
            intraConnectivity::Array{ActualQubit}=[],runningOperation::Array=[], circuitQubit::)
        end
    end

    mutable struct Core
        id::Int64
        capacity::Int64
        noOfQubits::Int64
        qubits::Array{ActualQubit}
        noOfPhonons::Float64
        interConnectivity::Array{Core}
    end

    struct Hardware
        noOfCores::Int64
        totalTime::Float64
        cores::Array{Core}
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
    end

    mutable struct Path <: CommunicationChannel
        id::Int64
        isOccupide::Bool
        length::Float64 # length of shuttling path to calculate shuttling duration
        connectedChannel::Tuple{CommunicationChannel, CommunicationChannel}
    end

    mutable struct Junction <: CommunicationChannel
        id::Int64
        isOccupide::Bool
        noOfPath::Int64
        connectedChannel::Tuple{Path}
    end

    mutable struct Edge <: CommunicationChannel
        id::Int64
        isOccupide::Bool
        connectedChannel::Path
        connectedCore::Core
    end

    struct LinearTransport <: Shuttling
        speed::Float64 # To calculate shuttling time of path
        heatingRate::Float64
    end

    struct JunctionRotate <: Shuttling
        duration::Float64
        heatingRate::Float64
        toPath::Path
    end

    struct Split <: Shuttling
        duration::Float64
        heatingRate::Tuple{Float64} # (Core, CommQubit)
    end

    struct Merge <: Shuttling
        duration::Float64
        heatingRate::Float64
    end


    """
    This part is about the configuraiton functions.
    """
 
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
