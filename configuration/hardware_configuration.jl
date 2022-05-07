module HardwareConfiguration
    import ..OperationConfiguration
    import ..CircuitGenerator

    # Abstract type of hardware
    # abstract type Circuit end
    # abstract type Operation <: Circuit end

    # Abstract type of communication
    abstract type CommunicationChannel end
    
    abstract type CommunicationOperation end
    abstract type Shuttling <:CommunicationOperation end

    """
    This part is about the configuration for Hardware.
    """

    mutable struct ActualQubit
        id::String
        operationTime::Float64
        communicationTime::Float64
        intraConnectivity::Array{ActualQubit} # TODO
        runningOperations::Array{Union{Operation,CommunicationOperation},1} # running oepration list
        circuitQubit::CircuitGenerator.CircuitQubit
        isCommunicationQubit::Bool
        fidelity::Float64
        function ActualQubit(id::String, operationTime::Float64=0.0, communicationTime::Float64=0.0,
            intraConnectivity::Array{ActualQubit}=[],runningOperations::Array{Union{Operation,CommunicationOperation},1}=[], 
            circuitQubit::CircuitQubit = nothing, isCommunicationQubit::Bool=false, fidelity::Float64=1.0)
            new(id,operationTime,communicationTime,intraConnectivity, runningOperations,circuitQubit,isCommunicationQubit,fidelity)
        end
    end

    mutable struct Core
        id::String
        capacity::Int64
        noOfQubits::Int64
        qubits::Array{ActualQubit}
        noOfPhonons::Float64
        interConnectivity::Array{Core} # TODO
        function Core(id::String, capacity::Int64,  noOfQubits::Int64=0, qubits::Array{ActualQubit}=[],
            noOfPhonons::Float64=0.0,interConnectivity::Array{Core}=[])
            new(id, capacity, noOfQubits, qubits, noOfPhonons, interConnectivity)
        end
    end

    mutable struct Hardware
        name::String
        noOfCores::Int64
        noOfTotalQubits::Int64
        totalTime::Float64
        cores::Array{Core}

        function Hardware(name::String, noOfCores::Int64=0, noOfTotalQubits::Int64=0, totalTime::Float64=0.0, cores::Array{Core}=[])
            new(name, noOfCores, noOfTotalQubits, totalTime, cores)
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
        id::String
        length::Float64 # length of shuttling path to calculate shuttling duration
        isOccupied::Bool
        function Path(id::String, length::Float64, isOccupide::Bool=false)
            new(id, length, isOccupide)
        end
    end

    mutable struct Junction <: CommunicationChannel
        id::String
        connection::Dict{String, Tuple{Tuple{String,String}, Vararg{Tuple{String, String}}}}
        """ 
        e.g., "connection": {
                        "x": (("junction1","path1"),("junction3","path2")),
                        "y": (("core2","e_core2"),)}
        """
        isOccupied::Bool
        function Junction(id::String, connection::Dict{String, Tuple{Tuple{String,String}, Vararg{Tuple{String, String}}}}, 
            isOccupied::Bool=false)
            new(id, connection, isOccupied)
        end
    end

    # mutable struct Entrance <: CommunicationChannel
    #     id::String
    #     length::Float64
    #     connectedJunction::Junction
    #     connectedCore::Core
    #     isOccupied::Bool
    #     function Entrance(id::String, length::Float64, connectedJunction::Junction, connectedCore::Core, isOccupied::Bool=false)
    #         new(id, length, connectedJunction, connectedCore, isOccupied)
    #     end
    # end


    """
    This part is about the configuraiton functions.
    """
    function buildCore(hardware::Hardware, name::String, capacity::Int64, noOfQubits::Int64=0)
        @assert(noOfQubits>capacity,"#qubits per core do NOT exceed capacity of core.")
        core = Core(name, capacity, noOfQubits)
        return core
    end
    
    function buildHardware(hardwareConfig::Dict)
        name::String = hardwareConfig["name"]
        coresConfig::Dict = hardwareConfig["cores"]
        noOfCores::Int64 = length(coresConfig)
        noOftotalQubits::Int64 = 0

        hardware = Hardware(name, noOfCores)
        idOfQubit = 1

        for coreConfig in values(coresConfig)
            core = buildCore(coreConfig["name"], coreConfig["capacity"], coreConfig["number_of_qubits"])
            for i in 1:noOfQubitsPerCore
                qubit = ActualQubit("qubit$idOfQubit")
                push!(core.qubits,qubit)
                idOfQubit += 1
            end
            push!(hardware.cores,core)
            noOftotalQubits += coreConfig["number_of_qubits"]
        end
        hardware.noOfTotalQubits = noOftotalQubits
        return hardware
    end
    

    function buildCommunicationSystem(hardware::Hardware, topology::Dict)
        junctions = keys(topology)
        for junction in junctions
        end
    end

    function generateCommunicationQubit()
    end

    # function addCore(hardware::Hardware, idOfCore::String, capacity::Int64, noOfQubits::Int64)
    #     core = Core(idOfCore::String, capacity::Int64, noOfQubits::Int64)
    #     push!(hardware.cores,core)
    #     return hardware
    # end

    # function configure(configType::String, operation::String, specification::Array{Array{Any,1},1})::Tuple
    #     config = nothing
    #     ex = "$operation = $configType("
    #     for i in specification
    #         ex = ex * i[2]*','
    #     end
    #     ex = ex * ')'
    #     config = eval(ex)
    #     return (configType, config)
    # end

    function openConfigFile(filePath::String = "")::Dict
        if filePath === "" 
            currentPath = pwd()
            filePath = currentPath * "/input/hardware_configuraiton.json"
        end

        configJSON = JSON.parsefile(filePath) 
        # configTypes = ["hardware", "topology"]

        hardware = buildHardware(configJSON["hardware"])
        communicationSystem = buildCommunicationSystem(hardware, configJSON["topology"])

        configuration = Dict("hardware"=>hardware, "communicationSystem" => communicationSystem)
        return configuration    
    end
end
