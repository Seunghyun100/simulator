module QCCDShuttlingProtocol
    include("../configuration/communication_configuration.jl")
    include("../function/circuit_builder.jl")

    const pathRow = CommunicationConfiguration.communicationConfiguration["protocol"]["pathRow"]

    """
    Only Two-qubit gate is avilable yet.
    """

    function checkTarget(multiGateID::Int64, multiGateTable::Dict, architecture, appliedQubitID)
        appliedQubits = multiGateTable[multiGateID]["appliedQubits"]
        
        cores = values(architecture.components["cores"])
        targets = [] # Tuple(Core, Qubit)
        for appliedQubit in appliedQubits
            for core in cores
                qubits = values(core.qubits)
                for qubit in qubits
                    if qubit.circuitQubit.id == appliedQubit
                        if qubit.circuitQubit.id == appliedQubitID
                            pushfirst!(targets, (core, qubit))
                        else
                            push!(targets, (core, qubit))
                        end
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
        
        """
        Symmetric configuration
        """
        # for i in reverse(route[2:end-1])
        #     push!(route, i)
        # end

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
        targets = checkTarget(operationID, multiGateTable::Dict, architecture, appliedQubit.circuitQubit.id)
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
        appliedQubit.isShuttling = true
        architecture.isShuttling = true
        return communicationOperationList, shuttlingRoute
    end

end

"""For now, communication simmulation of Q-bus is used to short-cut by layered-shuttling"""
module QBusShuttlingProtocol

    function buildGateTeleportationOperations()
    end


    """Not used"""
    function checkTarget(multiGateID::Int64, multiGateTable::Dict, architecture, appliedQubitID)
        appliedQubits = multiGateTable[multiGateID]["appliedQubits"]
        cores = values(architecture.components["cores"])
        targets = [] # Tuple(Core, Qubit)
        for appliedQubit in appliedQubits
            for core in cores
                qubits = values(core.qubits)
                for qubit in qubits
                    if qubit.circuitQubit.id == appliedQubit
                        if qubit.circuitQubit.id == appliedQubitID
                            pushfirst!(targets, (core, qubit))
                        else
                            push!(targets, (core, qubit))
                        end
                    end
                end
            end   
        end
        push!(targets,(architecture.components["cores"]["BusDetector"],"dummy"))
        return  targets
    end

    function checkNeedCommunication()
    end

    function operateMiddleGateInCore()
    end

    function inputShuttling()
    end

    function outputShuttling()
    end

    function pipelining()
    end

    function detectBusQubit()
    end

    function operateAfterGate()
    end

    ## may be COMPLETE
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

            # move to target column for vertical transport
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
            
            # move to path row for horizontal transport
            if startingCoordinates[2]<targetCoordinates[2]
                # move to right
                for i in 1:abs(startingCoordinates[2]-targetCoordinates[2])
                    push!(route, (route[end][1],route[end][2]+1))
                end
            else
                # move to left
                # for i in 1:abs(startingCoordinates[2]-targetCoordinates[2])
                #     push!(route, (route[end][1],route[end][2]-1))
                # end
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
    
    ## may be COMPLETE
    # Choosing shuttling opertor
    function checkShuttlingType(preCoordinates::Tuple{Int64, Int64}, currentCoordinates::Tuple{Int64, Int64}, nextCoordinates::Tuple{Int64, Int64}, architecture)
        currentComponentType = typeof(architecture.topology[currentCoordinates[1], currentCoordinates[2]])
        nextComponentType = typeof(architecture.topology[nextCoordinates[1], nextCoordinates[2]])

        shttulingList = []
        if currentComponentType == Main.ArchitectureConfiguration.Core && nextComponentType == Main.ArchitectureConfiguration.Path
            shuttlingPair = ("unbalancedSplit", ((currentCoordinates),(nextCoordinates)))
            push!(shttulingList, shuttlingPair)
        elseif currentComponentType == Main.ArchitectureConfiguration.Path
            if nextComponentType == Main.ArchitectureConfiguration.Junction
                shuttlingPair = ("linearTransport", ((currentCoordinates),(nextCoordinates)))
                push!(shttulingList, shuttlingPair)
            elseif nextComponentType == Main.ArchitectureConfiguration.Core
                shuttlingPair = ("mergeToDetect", ((currentCoordinates),(nextCoordinates)))
                push!(shttulingList, shuttlingPair)
            end
        elseif currentComponentType == Main.ArchitectureConfiguration.Junction && nextComponentType == Main.ArchitectureConfiguration.Path
            if preCoordinates[1] !== nextCoordinates[1] && preCoordinates[2] !== nextCoordinates[2] && preCoordinates !==(0,0)
                shuttlingPair = ("fastRotate", ((currentCoordinates),(currentCoordinates)))
                push!(shttulingList, shuttlingPair)
            end
            shuttlingPair = ("linearTransport", ((currentCoordinates),(nextCoordinates)))
            push!(shttulingList, shuttlingPair)
        end
        return shttulingList
    end

    # TODO: renovate to fit Q-bus
    function buildCommunicationOperations(appliedQubit, operation, multiGateTable::Dict, architecture)
        
        operationID = operation.id
        targets = checkTarget(operationID, multiGateTable::Dict, architecture, appliedQubit.circuitQubit.id) # (core1, core2, Detector)

        startCore1 = targets[1][1]
        startCore2 = targets[2][1]
        DetectorCore = targets[3][1]
        
        if startCore1.id == startCore2.id
            error("Not necessary communication!")
        elseif multiGateTable[operationID]["isPreparedCommunication"] 
            error("Already communication is prepared!")
        end

        shuttlingRoute1 = drawShuttlingRoute(startCore1, DetectorCore, pathRow) # Tuple{Int64, Int64}[]
        shuttlingRoute2 = drawShuttlingRoute(startCore2, DetectorCore, pathRow) # Tuple{Int64, Int64}[]

        shuttlingList1 = []
        shuttlingList2 = []
        for i in 2:length(shuttlingRoute1)-1
            shuttlingList1 = vcat(shuttlingList1,checkShuttlingType(shuttlingRoute1[i-1], shuttlingRoute1[i], shuttlingRoute1[i+1], architecture))
        end
        for i in 2:length(shuttlingRoute2)-1
            shuttlingList2 = vcat(shuttlingList2,checkShuttlingType(shuttlingRoute2[i-1], shuttlingRoute2[i], shuttlingRoute2[i+1], architecture))
        end

        # TODO: build communication operation
        communicationOperationList1 = []
        for shuttlingPair in shuttlingList1
            operation = CommunicationConfiguration.generateCommunicationOperation(shuttlingPair[1], shuttlingPair[2][1], shuttlingPair[2][2])
            push!(communicationOperationList1,operation)
        end

        communicationOperationList2 = []
        for shuttlingPair in shuttlingList2
            operation = CommunicationConfiguration.generateCommunicationOperation(shuttlingPair[1], shuttlingPair[2][1], shuttlingPair[2][2])
            push!(communicationOperationList2,operation)
        end

        ### TODO
        multiGateTable[operationID]["isPreparedCommunication"] = true
        appliedQubit.isShuttling = true
        architecture.isShuttling = true
        return (communicationOperationList1, communicationOperationList2)
    end
end