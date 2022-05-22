module ArchitectureConfiguration
    import JSON
    import ..OperationConfiguration
    include("../function/circuit_builder.jl")

    abstract type Component end

    # abstract type CommunicationChannel end
    # abstract type CommunicationOperation end
    # abstract type Shuttling <:CommunicationOperation end

    struct Direction
        direction::String
        function Direction(direction::String = "stop")
            new(direction)
        end
    end

    stop = Direction("stop")
    up = Direction("up")
    right = Direction("right")
    down = Direction("down")
    left = Direction("left")
    
    dumyCircuitQubit = CircuitBuilder.CircuitQubit()
    # dumyQubit = Qubit()

    mutable struct Qubit <:Component
        id::String
        executionTime::Float64
        isCommunicationQubit::Bool
        circuitQubit # ::CircuitBuilder.CircuitQubit
        # runningOperation::Vector{Operation}
        # communicationList::Vector{CommunicationOperation}
        # communicationTime::Float64
        # dwellTime::Float64
        noOfPhonons::Float64
        function Qubit(id::String, executionTime::Float64=0.0, isCommunicationQubit::Bool=false,
            circuitQubit = dumyCircuitQubit, noOfPhonons::Float64=0.0)
            new(id, executionTime, isCommunicationQubit, circuitQubit, noOfPhonons)
        end
    end

    mutable struct Core <: Component
        id::String
        capacity::Int64
        coordinates::Tuple{Int64,Int64}
        qubits::Dict #{String, Qubit}
        noOfPhonons::Float64
        executionTime::Float64
        function Core(id::String, capacity::Int64, coordinates::Tuple{Int64, Int64}, qubits::Dict=Dict(), noOfPhonons::Float64=0.0, executionTime::Float64=0.0)
            new(id, capacity, coordinates, qubits, noOfPhonons, executionTime)
        end
    end

    mutable struct Junction <: Component
        id::String
        coordination::Tuple{Int64,Int64}
        isShuttling::Bool
        qubits::Vector{Qubit}
        executionTime::Float64
        function Junction(id::String, coordination::Tuple{Int64, Int64}, isShuttling::Bool=false, qubits::Vector{Qubit}=Qubit[], executionTime::Float64=0.0)
            new(id, coordination, isShuttling, qubits, executionTime)
        end
    end

    struct Block <: Component
    end

    mutable struct Path <: Component
        id::String
        length::Float64
        coordinates::Tuple{Int64,Int64}
        isShuttling::Bool
        direction::Direction
        qubits::Vector{Qubit}
        executionTime::Float64
        function Path(id::String, length::Float64, coordinates::Tuple{Int64, Int64}, isShuttling::Bool=false, 
            direction::Direction=stop, qubits::Vector{Qubit}=Qubit[], executionTime::Float64=0.0)
            new(id, length, coordinates, isShuttling, direction, qubits, executionTime)
        end
    end

    mutable struct Architecture
        name::String
        components::Dict # e.g., core, junction, path, qubit
        topology::Matrix # It is mapping components as coordinates
        totalTime::Float64
        function Architecture(name::String, components::Dict, topology::Matrix, totalTime::Float64 =0.0)
            new(name, components, topology, totalTime)
        end
    end


    """
    This part is about the configuration functions.
    """

    function generateQubit(id::String, executionTime::Float64=0.0, isCommunicationQubit::Bool=false)
        qubit = Qubit(id, executionTime, isCommunicationQubit)
        return qubit
    end

    function buildCore(id::String, capacity::Int64, coordinates::Tuple{Int64, Int64}, qubits::Dict=Dict())
        @assert(length(qubits)<capacity,"#qubits per core do NOT exceed capacity of core.")
        core = Core(id, capacity, coordinates, qubits)
        return core
    end

    function buildJunction(id::String, coordinates::Tuple{Int64, Int64})
        junction = Junction(id, coordinates)
        return junction
    end
    
    function buildBlock()
        return Block()
    end

    function buildPath(id::String, length::Float64, coordinates::Tuple{Int64, Int64})
        path = Path(id, length, coordinates)
        return path
    end

    function buildArchitecture(architectureConfig)
        # build the Component list
        architectureName = architectureConfig["name"]
        componentsConfig = architectureConfig["components"]

        components = Dict()
        
        # build components
        qubitNo = 1
        components = Dict()

        for componentConfigPair in componentsConfig
            componentType = componentConfigPair[1]
            componentConfigList = componentConfigPair[2]
            componentList = Dict()

            # Build the core list 
            if componentType =="cores"
                for componentConfigPair in componentConfigList
                    componentName = componentConfigPair[1]
                    componentConfig = componentConfigPair[2]

                    coreID = componentConfig["id"]
                    coreCapacity = componentConfig["capacity"]
                    coreCoordinates = Tuple(componentConfig["coordinates"])
                    noOfQubits = componentConfig["number_of_qubits"]

                    qubitDict = Dict()
                    for i in 1:noOfQubits
                        if i == noOfQubits
                            qubitID = "Qubit"*string(qubitNo)
                            qubitDict[qubitID] = generateQubit(qubitID, 0.0, true)
                            qubitNo += 1
                        else
                            qubitID = "Qubit"*string(qubitNo)
                            qubitDict[qubitID] = generateQubit(qubitID)
                            qubitNo += 1
                        end
                    end

                    core = buildCore(coreID, coreCapacity, coreCoordinates, qubitDict)
                    componentList[coreID] = core
                end
                components["cores"] = componentList

            # Build the junction list 
            elseif componentType =="junctions"
                for componentConfigPair in componentConfigList
                    componentName = componentConfigPair[1]
                    componentConfig = componentConfigPair[2]

                    junctionID = componentConfig["id"]
                    junctionCoordinates = Tuple(componentConfig["coordinates"])

                    junction = buildJunction(junctionID, junctionCoordinates)
                    componentList[junctionID] = junction
                end
                components["junctions"] = componentList

            # Build the path list 
            elseif componentType =="paths"
                for componentConfigPair in componentConfigList
                    componentName = componentConfigPair[1]
                    componentConfig = componentConfigPair[2]

                    pathID = componentConfig["id"]
                    pathLength = componentConfig["length"]
                    pathCoordinates = Tuple(componentConfig["coordinates"])

                    path = buildPath(pathID, pathLength, pathCoordinates)
                    componentList[pathID] = path
                end
                components["paths"] = componentList
            end
        end

        # Build the topology configuration.

        topologyConfig = architectureConfig["topology"]
        topologySize = topologyConfig["size"]

        # Initialize the topology map.
        topology = Array{Component}(undef, topologySize[1], topologySize[2])
        block = Block()
        for i in 1:topologySize[1]
            for k in 1:topologySize[2]
                topology[i, k] = block
            end
        end

        topologyMapConfig = topologyConfig["map"]

        for i in 1: topologySize[1]
            for k in 1:topologySize[2]
                componentID = topologyMapConfig[i][k]
                if componentID == "Block"
                    continue
                end
                if componentID ∈ keys(components["cores"])
                    topology[i, k] = components["cores"][componentID]
                elseif componentID ∈ keys(components["junctions"])
                    topology[i, k] = components["junctions"][componentID]
                elseif componentID ∈ keys(components["paths"])
                    topology[i, k] = components["paths"][componentID]
                end
            end
        end

        # Build the architecture
        architecture = Architecture(architectureName, components, topology)
        return architecture
    end    

    # TODO
    function generateCommunicationQubit()
    end

    function openConfigFile(filePath::String = "")::Dict
        if filePath === "" 
            currentPath = pwd()
            filePath = currentPath * "/input/architecture_configuration.json"
        end

        configJSON = JSON.parsefile(filePath) 

        architectureList = Dict()
        for architectureConfigPair in configJSON
            architectureName = architectureConfigPair[1]
            architectureConfig = architectureConfigPair[2]
            architectureList[architectureName] = buildArchitecture(architectureConfig)
        end
        return architectureList    
    end
end
