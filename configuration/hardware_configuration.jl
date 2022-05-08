module HardwareConfiguration
    import ..OperationConfiguration
    import ..CircuitGenerator

    abstract type Component end

    # abstract type CommunicationChannel end
    # abstract type CommunicationOperation end
    # abstract type Shuttling <:CommunicationOperation end

    struct Direction
        direction::String
        function Direction(direction::String = "Stop")
            new(direction)
        end
    end

    stop = Direction("stop")
    up = Direction("up")
    right = Direction("right")
    down = Direction("down")
    left = Direction("left")
    
    dumyCircuitQubit = CircuitQubit()
    # dumyQubit = Qubit()

    mutable struct Qubit <:Component
        id::String
        circuitQubit::CircuitQubit
        executionTime::Float64
        runningOperation::Vector{Operation}
        isCommunicationQubit::Bool
        communicationList::Vector{CommunicationOperation}
        communicationTime::Float64
        dwellTime::Float64
        noOfPhonons::Float64
        function Qubit(id::String, circuitQubit::CircuitQubit = dumyCircuitQubit, executionTime::Float64=0.0, runningOperation::Vector{Operation}=Operation[],
            isCommunicationQubit::Bool=false, communicationList::Vector{CommunicationOperation}=CommunicationOperation[], communicationTime::Float64=0.0, 
            dwellTime::Float64=0.0, noOfPhonons::Float64=0.0)
            new(id, circuitQubit, executionTime, runningOperation, isCommunicationQubit, communicationList, communicationTime, dwellTime, noOfPhonons)
        end
    end

    mutable struct Core <: Component
        id::String
        capacity::Int64
        coordinates::Tuple{Int64,Int64}
        qubits::Dict{String, Qubit}
        noOfPhonons::Float64
        function Core(id::String, capacity::Int64, coordinates::Tuple{Int64, Int64}, qubits::Dict{String, Qubit}, noOfPhonons::Float64=0.0)
            new(id, capacity, coordinates, qubits, noOfPhonons)
        end
    end

    mutable struct Junction <: Component
        id::String
        coordination::Tuple{Int64,Int64}
        isShuttling::Bool
        qubits::Vector{Qubit}
        function Junction(id::String, coordination::Tuple{Int64, Int64}, isShuttling::Bool=false, qubits::Vector{Qubit}=Qubit[])
            new(id, coordination, isShuttling, qubits)
        end
    end

    mutable struct Path <: Component
        id::String
        length::Float64
        coordinates::Tuple{Int64,Int64}
        isShuttling::Bool
        direction::Direction
        qubits::Vector{Qubit}
        function Path(id::String, length::Float64, coordinates::Tuple{Int64, Int64}, isShuttling::Bool=false, 
            direction::Diraction=stop, qubits::Vector{Qubit}=Qubit[])
            new(id, length, coordinates, isShuttling, direction, qubits)
        end
    end

    mutable struct Architecture
        name::String
        components::Dict{String,Vector{Component}} # e.g., core, junction, path, qubit
        topology::Matrix{Component} # It is mapping components as coordinates
        totalTime::Float64
        function Architecture(name::String, components::Dict{String,Vector{Component}}, topology::Matrix{Component}, totalTime::Float64 =0.0)
            new(name, components, topology, totalTime)
        end
    end














    
    """
    This part is about the configuraiton functions.
    """
    function buildCore(name::String, capacity::Int64, noOfQubits::Int64=0)
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
                push!(hardware.qubits,qubit)
                idOfQubit += 1
            end
            push!(hardware.cores,core)
            noOftotalQubits += coreConfig["number_of_qubits"]
        end
        hardware.noOfTotalQubits = noOftotalQubits
        return hardware
    end
    
    function buildConnectionPair(destination::String, pathLength::Float64)
        # TODO
        Path
        return(core::Core, path::Path)
    end

    function buildCommunicationSystem(topology::Dict)
        noOfJunctions = topology["number_of_junctions"]::Int64
        noOfPaths = topology["number_of_paths"]::Int64
        directions = topology["directions"]::Array{String,1}
        junctionsConfig = topology["junctions"]::Dict
        pathLength = topology["length_of_path"]::Float64
        junctions = []::Array
        for junctionConfig in junctionsConfig
            connectionConfig = junctionConfg["connection"]
            connection = Dict()
            for direction in directions
                connectionPairList = []
                for coreName in connectionConfig[direction]
                    connectionPair = buildConnectionPair(coreName,pathLength)
                    push!(connectionPairList, connectionPair)
                end
                connection[direction] = connectionPairList
            end
            push!(junctions, Junction(junctionConfig["name"], connection))
        end
        return junctions
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
        push!(hardware.junctions, buildCommunicationSystem(configJSON["topology"]))

        configuration = Dict("hardware"=>hardware, "communicationSystem" => communicationSystem)
        return configuration    
    end
end
