module QCCDShuttlingProtocol
    include("../configuration/communication_configuration.jl")
    include("../function/circuit_builder.jl")

    const pathRow = CommunicationConfiguration.communicationConfiguration["protocol"]["pathRow"]

    """
    Only Two-qubit gate is avilable yet.
    """

    function checkTarget(multiGateID::Int64, multiGateTable::Dict, architecture)
        appliedQubits = multiGateTable[multiGateID]["appliedQubits"]
        cores = values(architecture.components["cores"])
        targets = [] # Tuple(Core, Qubit)
        for appliedQubit in appliedQubits
            for core in cores
                qubits = values(core.qubits)
                for qubit in qubits
                    if qubit.circuitQubit.id == appliedQubit
                        push!(targets, (core, qubit))
                    end
                end
            end   
        end
        return  targets
    end

    function checkCommunicationQubit(appliedQubit, targets, multiGateTable)
        for target in targets
            targetCore = target[1]
            targetQubit = target[2]
            if appliedQubit == targetQubit
                if targetQubit.isCommunicationQubit == false
                    for qubit in values(targetCore.qubits)
                        if qubit.isCommunicationQubit
                            composition = [length(multiGateTable)+1, "swap", targetQubit.circuitQubit.id, qubit.circuitQubit.id]
                            swap = CircuitBuilder.encodeOperation(composition, multiGateTable)
                            pushfirst!(qubit.circuitQubit.operations, swap)
                            qubit.isCommunicationQubit = false
                            targetQubit.isCommunicationQubit = true
                            return swap
                        end
                    end
                else
                    return
                end
            end
        end
    end

    function drawShuttlingRoute(startingCore, targetCore, pathRow::Int64) # (Core, Core, Int64)
        startingCoordinates = startingCore.coordinates
        targetCoordinates = targetCore.coordinates
        route = [(0,0), startingCoordinates] # vector of coordinates for route

        if startingCoordinates[2] ==targetCoordinates[2] # same column
            if startingCoordinates[1]<targetCoordinates[1]
                # move to down
                for i in 1:abs(startingCoordinates[1]-targetCoordinates[1])
                    push!(route, (route[end][1]+1,route[end][2])) 
                end
            else
                # move to up
                for i in 1:abs(startingCoordinates[1]-targetCoordinates[1])
                    push!(route, (route[end][1]-1,route[end][2])) 
                end
            end
        else
            # move to path row for horizontal transport
            if startingCoordinates[1] == pathRow
            elseif startingCoordinates[1]<pathRow # move to down
                for i in 1:abs(startingCoordinates[1]-pathRow)
                    push!(route, (route[end][1]+1,route[end][2]))
                end
            else # move to up
                for i in 1:abs(startingCoordinates[1]-pathRow)
                    push!(route, (route[end][1]-1,route[end][2]))
                end
            end

            # move to target column for vertical transport
            if startingCoordinates[2]<targetCoordinates[2]
                # move to right
                for i in 1:abs(startingCoordinates[2]-targetCoordinates[2])
                    push!(route, (route[end][1],route[end][2]+1))
                end
            else
                # move to left
                for i in 1:abs(startingCoordinates[2]-targetCoordinates[2])
                    push!(route, (route[end][1],route[end][2]-1))
                end
            end

            # move to target core
            if pathRow == targetCoordinates[1]
            elseif pathRow < targetCoordinates[1] # move to down
                for i in 1:abs(pathRow-targetCoordinates[1])
                    push!(route, (route[end][1]+1,route[end][2]))
                end
            else # move to up
                for i in 1:abs(pathRow-targetCoordinates[1])
                    push!(route, (route[end][1]-1,route[end][2]))
                end
            end
        end
        return route
    end

    function checkShuttlingType(preCoordinates::Tuple{Int64, Int64}, currentCoordinates::Tuple{Int64, Int64}, nextCoordinates::Tuple{Int64, Int64}, architecture)
        currentComponentType = typeof(architecture.topology[currentCoordinates[1], currentCoordinates[2]])
        nextComponentType = typeof(architecture.topology[nextCoordinates[1], nextCoordinates[2]])

        shttulingList = []
        if currentComponentType == Main.ArchitectureConfiguration.Core && nextComponentType == Main.ArchitectureConfiguration.Path
            shuttlingPair = ("split", ((currentCoordinates),(nextCoordinates)))
            push!(shttulingList, shuttlingPair)
        elseif currentComponentType == Main.ArchitectureConfiguration.Path
            if nextComponentType == Main.ArchitectureConfiguration.Junction
                shuttlingPair = ("linearTransport", ((currentCoordinates),(nextCoordinates)))
                push!(shttulingList, shuttlingPair)
            elseif nextComponentType == Main.ArchitectureConfiguration.Core
                shuttlingPair = ("merge", ((currentCoordinates),(nextCoordinates)))
                push!(shttulingList, shuttlingPair)
            end
        elseif currentComponentType == Main.ArchitectureConfiguration.Junction && nextComponentType == Main.ArchitectureConfiguration.Path
            if preCoordinates[1] !== nextCoordinates[1] && preCoordinates[2] !== nextCoordinates[2] && preCoordinates !==(0,0)
                shuttlingPair = ("junctionRotate", ((currentCoordinates),(currentCoordinates)))
                push!(shttulingList, shuttlingPair)
            end
            shuttlingPair = ("linearTransport", ((currentCoordinates),(nextCoordinates)))
            push!(shttulingList, shuttlingPair)
        end
        return shttulingList
    end

    function buildCommunicationOperations(appliedQubit, operation, multiGateTable::Dict, architecture)
        communicationOperationList = []

        operationID = operation.id
        targets = checkTarget(operationID, multiGateTable::Dict, architecture)
        startingCore = targets[1][1]
        targetCore = targets[2][1]
        
        if startingCore.id == targetCore.id
            error("Not necessary communication!")
        elseif multiGateTable[operationID]["isPreparedCommunication"] 
            error("Already communication is prepared!")
        end
        
        # checkCommunicationQubit(targets, multiGateTable)
        swap = checkCommunicationQubit(appliedQubit, targets, multiGateTable)
        if swap !== nothing
            push!(communicationOperationList, swap)
        end

        shuttlingRoute = drawShuttlingRoute(startingCore, targetCore, pathRow) # Tuple{Int64, Int64}[]

        shuttlingList = []
        for i in 2:length(shuttlingRoute)-1
            shuttlingList = vcat(shuttlingList,checkShuttlingType(shuttlingRoute[i-1], shuttlingRoute[i], shuttlingRoute[i+1], architecture))
        end

        # TODO: build communication operation
        for shuttlingPair in shuttlingList
            operation = CommunicationConfiguration.generateCommunicationOperation(shuttlingPair[1], shuttlingPair[2][1], shuttlingPair[2][2])
            push!(communicationOperationList,operation)
        end

        multiGateTable[operationID]["isPreparedCommunication"] = true
        return communicationOperationList
    end

end