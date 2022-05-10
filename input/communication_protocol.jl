module QCCDShuttlingProtocol

    """
    Only Two-qubit gate is avilable yet.
    """
    
    function isCommunicationQubit(qubits...)

    end

    function checkTarget(multiGateID::Int64, multiGateTable::Dict, architecture)
        appliedQubits = multiGateTable[multiGateID]
        cores = values(architecture.components["cores"])
        targets = [] # Tuple(Core, Qubit)
        for appliedQubit in appliedQubits
            for core in cores
                qubits = values(core.qubits)
                for qubit in qubits
                    if qubit.circuitQubit == appliedQubit
                        push!(targets, (core, qubit))
                    end
                end
            end   
        end
        return  targets
    end

    function drawShuttlingRoute(startingCore::Core, targetCore::Core, pathRow::Int64)
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
            elseif startingCoordinates[1]<pathRow
                # move to down
                for i in 1:abs(startingCoordinates[1]-pathRow)
                    push!(route, (route[end][1]+1,route[end][2]))
                end
            else
                # move to up
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
            elseif pathRow < targetCoordinates[1]
                push!(route, ("down", abs(pathRow-targetCoordinates[1])))
            else
                push!(route, ("up", abs(pathRow-targetCoordinates[1])))
            end
        end
        return route
    end

    function checkShuttlingType(preCoordinates::Tuple{Int64, Int64}, currentCoordinates::Tuple{Int64, Int64}, nextCoordinates::Tuple{Int64, Int64}, architecture)
        currentComponentType = typeof(architecture.topology[currentCoordinates[1], currentCoordinates[2]])
        nextComponentType = typeof(architecture.topology[nextCoordinates[1], nextCoordinates[2]])

        shuttlingTypes = []
        if currentComponentType == Core & nextComponentType == Path
            push!(shuttlingTypes, "linearTransport")
        elseif currentComponentType == Path
            if nextComponentType == Junction
                push!(shuttlingTypes, "junctionRotate")
            elseif nextComponentType == Core
                push!(shuttlingTypes,"merge")
        elseif currentComponentType == Junction & nextComponentType == Path
            if preCoordinates[1] != nextCoordinates[1] & preCoordinates[2] != nextCoordinates[2] & preCoordinates !=(0,0)
                push!(shuttlingTypes, "junctionRotate")
            end
            push!(shuttlingTypes, "linearTransport")
        end
        return shuttlingTypes
    end

    function executeShuttling(multiGateID::Int64, multiGateTable::Dict, architecture::Architecture, communications::Dict)
        shuttlingList = []
        targets = checkTarget(multiGateID::Int64, multiGateTable::Dict, architecture)
        
        if targets[1][1] == targets[2][1]
            return
        end
        
        ## TODO
        for target in targets
            if target[2].isCommunicationQubit == false
                for qubit in target[1].qubits
                    if qubit.isCommunicationQubit    
                        communicationQubit = 
            end
        end
        
        pathRow = communications["protocol"]["pathRow"]
        shuttlingRoute = drawShuttlingRoute(startingCore, targetCore, pathRow) # Tuple{Int64, Int64}[]
        for i in 2:length(shuttlingRoute)-1
            append!(shuttlingList,checkShuttlingType(i-1, i, i+1, architecture))
        end
        return shuttlingList
    end

end