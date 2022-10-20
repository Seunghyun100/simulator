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
        isShuttling::Bool
        circuitQubit # ::CircuitBuilder.CircuitQubit
        # runningOperation::Vector{Operation}
        # communicationList::Vector{CommunicationOperation}
        # communicationTime::Float64
        # dwellTime::Float64
        noOfPhonons::Float64
        function Qubit(id::String, executionTime::Float64=0.0, isCommunicationQubit::Bool=false, isShuttling::Bool=false,
            circuitQubit = dumyCircuitQubit, noOfPhonons::Float64=0.0)
            new(id, executionTime, isCommunicationQubit, isShuttling, circuitQubit, noOfPhonons)
        end
    end

    mutable struct Core <: Component
        id::String
        capacity::Int64
        coordinates::Tuple{Int64,Int64}
        qubits::Dict #{String, Qubit}
        qubitsList::Vector # To check communication qubit
        noOfPhonons::Float64
        executionTime::Float64
        doEmpty::Int64
        isPreparedCommunication::Bool

        function Core(id::String, capacity::Int64, coordinates::Tuple{Int64, Int64}, qubits::Dict=Dict(), qubitsList::Vector = [], noOfPhonons::Float64=0.0, executionTime::Float64=0.0, doEmpty::Int64=0, isPreparedCommunication::Bool=false)
            new(id, capacity, coordinates, qubits, qubitsList,  noOfPhonons, executionTime, doEmpty, isPreparedCommunication)
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
        noOfCores::Int64
        totalTime::Float64
        isShuttling::Bool
        noOfShuttling::Int64
        function Architecture(name::String, components::Dict, topology::Matrix, noOfCores::Int64, totalTime::Float64 =0.0, isShuttling::Bool=false, noOfShuttling::Int64=0)
            new(name, components, topology, noOfCores, totalTime, isShuttling, noOfShuttling)
        end
    end


    """
    This part is about the configuration functions.
    """

    function generateQubit(id::String, executionTime::Float64=0.0, isCommunicationQubit::Bool=false)
        qubit = Qubit(id, executionTime, isCommunicationQubit)
        return qubit
    end

    function buildCore(id::String, capacity::Int64, coordinates::Tuple{Int64, Int64}, qubits::Dict=Dict(), qubitsList=[])
        @assert(length(qubits)<capacity,"#qubits per core do NOT exceed capacity of core.")
        core = Core(id, capacity, coordinates, qubits, qubitsList)
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
        noOfCores = architectureConfig["number_of_cores"]

        components = Dict()
        
        # build components
        qubitNo = 1
        components = Dict()
        qubitNos = Dict()
            
        coreList = []
        cores = componentsConfig["cores"]
        sortCoreList = sort(collect(keys(cores)))
        core10 = splice!(sortCoreList,findall(x->x=="Core10", sortCoreList))
        sortCoreList = vcat(sortCoreList, core10)
        for key in sortCoreList
            push!(coreList, cores[key])
        end
        for c in coreList
            if c["id"][1:4] !== "Core"
                continue
            end
            qubitNos[c["id"]] = []
            for _ in 1:c["number_of_qubits"]
                push!(qubitNos[c["id"]],qubitNo)
                qubitNo += 1
            end
        end


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
                    qubitsList = []
                    for i in 1:noOfQubits
                        if architectureName =="Q-bus"
                            qubitID = "Qubit"*string(qubitNos[coreID][i])
                            qubitDict[qubitID] = generateQubit(qubitID)
                            push!(qubitsList, qubitDict[qubitID])
                        elseif i == noOfQubits
                            qubitID = "Qubit"*string(qubitNos[coreID][i])
                            qubitDict[qubitID] = generateQubit(qubitID, 0.0, true)
                            push!(qubitsList, qubitDict[qubitID])
                        else
                            qubitID = "Qubit"*string(qubitNos[coreID][i])
                            qubitDict[qubitID] = generateQubit(qubitID)
                            push!(qubitsList, qubitDict[qubitID])
                        end
                    end

                    core = buildCore(coreID, coreCapacity, coreCoordinates, qubitDict, qubitsList)
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
        architecture = Architecture(architectureName, components, topology, noOfCores)
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
