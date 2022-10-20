module Scheduler
end

module CostCalculator
    import ..Scheduler
end

module ErrorCalculator
end

module QCCDSimulator
    import ..CostCalculator
    import ..ErrorCalculator
    include("../input/communication_protocol.jl")
    include("../configuration/operation_configuration.jl")

    CommunicationProtocol = QCCDShuttlingProtocol # architecture dependency

    function checkNeedCommunication(appliedQubits, architecture)
        if String ∈ typeof.(appliedQubits)
            return false
        end
        appliedCores = []
        for appliedQubit in appliedQubits
            for core in values(architecture.components["cores"])
                for qubitID in keys(core.qubits)
                    if qubitID == appliedQubit.id
                        push!(appliedCores, core)
                        break
                    end
                end
            end
        end
        for i in 1:length(appliedCores)-1
            if appliedCores[i].id !== appliedCores[i+1].id
                return true
            end
        end
        return false
    end

    function communicateInterCore()
    end

    function scheduling()
    end

    function checkEndOperation(qubit,refTime) # (Qubit, Float64)
        qubitTime = qubit.executionTime
        if refTime > qubitTime
            return true
        end
        return false
    end

    function checkEndOperation(appliedQubits::Vector,refTime)
        if String ∈ typeof.(appliedQubits)
            return false
        end
        firstOperations = []
        for qubit in appliedQubits
            push!(firstOperations, qubit.circuitQubit.operations[1])
        end
        for i in firstOperations
            if typeof(i) !== Main.CircuitBuilder.OperationConfiguration.MultiGate && typeof(i) !== Main.QCCDSimulator.QCCDShuttlingProtocol.CircuitBuilder.OperationConfiguration.MultiGate
                return false
            end
        end
        for i in 1:length(firstOperations)-1
            if firstOperations[i].id !== firstOperations[i+1].id
                return false
            end
        end
        qubitTimeList = []
        for qubit in appliedQubits
            qubitTime = qubit.executionTime
            append!(qubitTimeList, qubitTime)
        end
        qubitTime = maximum(qubitTimeList)

        if refTime > qubitTime
            for qubit in appliedQubits
                qubit.executionTime = qubitTime
            end
            return true
        end
        return false
    end


    function checkDoShuttlingNextComponent(Coordinates, shuttlingTable, id = nothing)
        index = 0
        if id === nothing
            for route in shuttlingTable
                for i in route[2]
                    if i == Coordinates
                        println("id is nothing, ")
                        return true
                    end
                end
            end
        end        

        for i in 1:length(shuttlingTable)
            if shuttlingTable[i][1] == id
                index = i
            end
        end
        @assert(index != 0,"index is 0, id is $(id)")
        for route in shuttlingTable[1:index-1]
            for i in route[2]
                if i == Coordinates
                    # println("dodod shuttling id: $(id), route: $(route)") # debug
                    return true
                end
            end
        end
        return false
    end

    function deleteShuttlingRoute(id, currentCoordinates, shuttlingTable, time = false)
        index = 0
        for i in 1:length(shuttlingTable)
            if shuttlingTable[i][1] == id
                index = i
            end
        end

        if shuttlingTable[index][2][1] == (0,0)
            popfirst!(shuttlingTable[index][2])
        end
        @assert(index!=0, "deleteShuttling error -> index is 0, id:$id, curr:$currentCoordinates")
        if time != false
            shuttlingTable[index][3] = time
        elseif currentCoordinates != popfirst!(shuttlingTable[index][2])
            @error("$currentCoordinates, $(shuttlingTable[index][2])")
        end
        if length(shuttlingTable[index][2]) == 0
            deleteat!(shuttlingTable, index)
        end
    end

    function deleteShuttlingRoutByTime(shuttlingTable, refTime)
        c = 0
        for i in 1:length(shuttlingTable)
            if shuttlingTable[i-c][3]-refTime<1 && shuttlingTable[i-c][3]!= false
                popfirst!(shuttlingTable[i-c][2])
                shuttlingTable[i-c][3] = false
                if length(shuttlingTable[i-c][2]) == 1 || length(shuttlingTable[i-c][2]) == 0
                    deleteat!(shuttlingTable, i-c)
                end
                c += 1
            end
        end
    end

    function checkPackedCore(targetCoreID, architecutre)
        for core in values(architecutre.components["cores"])
            if core.id == targetCoreID
                if core.capacity - 5 < length(core.qubits)
                    return true
                end
            end
        end
        return false
    end

    function emptyCore(targetCoreID, architecture, multiGateTable, shuttlingTable)

        targetCore = nothing
        for core in values(architecture.components["cores"])
            if core.id == targetCoreID
                targetCore = core
                break
            end
        end
        if targetCore == nothing
            @error("targetCore is nothing")
        end

        choose_core = []
        for i in 1:architecture.noOfCores
            core = architecture.components["cores"]["Core$i"]
            if core.isPreparedCommunication == false
                push!(choose_core, (length(core.qubits), core.id))
            end
        end
        if length(choose_core) != 0
            depotCoreID = findmin(choose_core)[1][2]
        else
            return 
        end 

        for qubit in values(targetCore.qubits)
            operations = qubit.circuitQubit.operations
            if OperationConfiguration.MultiGate ∉ operations && QCCDShuttlingProtocol.CommunicationConfiguration.Shuttling ∉ operations
                if !qubit.isShuttling
                    for i in shuttlingTable
                        if i[1] == qubit.id
                            return
                        end
                    end
                    tmp = CommunicationProtocol.buildCommunicationOperations2(qubit, targetCoreID, depotCoreID, architecture, multiGateTable, shuttlingTable)
                    if tmp == false
                        return
                    end
                    communicationOperations, shuttlingRoute = tmp
                    push!(shuttlingTable, [qubit.id, shuttlingRoute, false])
                    
                    for communicationOperation in reverse(communicationOperations)
                        pushfirst!(qubit.circuitQubit.operations, communicationOperation)
                    end

                    targetCore.doEmpty += 1
                    break
                end
            end
        end
    end

    function executeOperation(qubit, refTime, multiGateTable, architecture, shuttlingTable) # (Qubit, Float64, Dict, Architecture)
        operations = qubit.circuitQubit.operations

        for i in values(architecture.components["cores"])
            @assert(length(i.qubits)<=i.capacity, "core: $(i.id), qubits: $(length(i.qubits)), capacity: $(i.capacity)")
        end

        if length(operations) == 0
            return
        end
        operation = operations[1]
        operationType = typeof(operation)

        if operationType == Main.CircuitBuilder.OperationConfiguration.SingleGate || operationType == Main.CircuitBuilder.OperationConfiguration.Measure
            qubit.executionTime += operation.duration
            popfirst!(qubit.circuitQubit.operations)
            return
        elseif operationType == Main.CircuitBuilder.OperationConfiguration.MultiGate || operationType == Main.QCCDSimulator.QCCDShuttlingProtocol.CircuitBuilder.OperationConfiguration.MultiGate
            operationID = operation.id
            appliedQubits = deepcopy(multiGateTable[operationID]["appliedQubits"])
            # appliedQubits = multiGateTable[operationID]["appliedQubits"]

            qubits = Dict()
            targetPairs = []
            coreList = values(architecture.components["cores"])
            for core in coreList
                merge!(qubits, core.qubits)
            end

            for i in 1:length(appliedQubits)
                for k in values(qubits)
                    if k.circuitQubit.id == appliedQubits[i]
                        appliedQubits[i] = k
                    end
                    # @assert(k < length(qubits),"Not found qubit")
                end
            end
            if String ∈ typeof.(appliedQubits)
                return
            end

            for i in 1:length(appliedQubits)
                for core in coreList
                    for q in values(core.qubits)
                        if q.circuitQubit.id == appliedQubits[i].circuitQubit.id
                            push!(targetPairs, (core, q))
                        end
                    end
                end
            end

            if checkNeedCommunication(appliedQubits, architecture) && !multiGateTable[operationID]["isPreparedCommunication"]
                if !checkEndOperation(appliedQubits, refTime)
                    return
                end
                for i in 1:length(appliedQubits)
                    isShuttling = false
                    for q in values(targetPairs[i][1].qubits)
                        if q.isCommunicationQubit
                            isShuttling = q.isShuttling
                        end
                    end
                    # if architecture.isShuttling
                    #     dwellTime = refTime
                    #     appliedQubits[i].executionTime = dwellTime
                    #     return
                    # end
                    
                    i2 = i%2 + 1
                    op1 = targetPairs[i][2].circuitQubit.operations
                    op2 = targetPairs[i2][2].circuitQubit.operations
                    ids = []
                    ids2 = []
                    for k in op1
                        if typeof(k) == Main.CircuitBuilder.OperationConfiguration.MultiGate
                            push!(ids, k.id)
                        end
                    end
                    for k in op2
                        if typeof(k) == Main.CircuitBuilder.OperationConfiguration.MultiGate
                            push!(ids2, k.id)
                        end
                    end

                    in1 = findall(x->x==operationID, ids)[1]
                    in2 = findall(x->x==operationID, ids2)[1]

                    if in1 == 0 || in2 == 0
                        return
                    end

                    if in1 > in2
                        break
                    end

                    if checkEndOperation(appliedQubits[i], refTime) && !multiGateTable[operationID]["isPreparedCommunication"] && !isShuttling

                        if checkPackedCore(targetPairs[3-i][1].id, architecture)
                            qubit.executionTime = refTime
                            if targetPairs[3-i][1].doEmpty == 0 # architecture.components["cores"][targetCoreID].capacity/4
                                emptyCore(targetPairs[3-i][1].id, architecture, multiGateTable, shuttlingTable)
                                return
                            else
                                targetPairs[3-i][1].doEmpty = 0
                            end
                        end
                        tmp = CommunicationProtocol.buildCommunicationOperations(appliedQubits[i], operation, multiGateTable, architecture, shuttlingTable)
                        if tmp == false
                            qubit.executionTime = refTime
                            return
                        end
                        communicationOperations, shuttlingRoute = tmp
                        push!(shuttlingTable, [appliedQubits[i].id, shuttlingRoute, false])

                        for communicationOperation in reverse(communicationOperations)
                            pushfirst!(appliedQubits[i].circuitQubit.operations, communicationOperation)
                        end
                    else

                        if i == length(appliedQubits) && !multiGateTable[operationID]["isPreparedCommunication"]  && !isShuttling
                            # if architecture.isShuttling
                            #     dwellTime = refTime
                            #     appliedQubits[i].executionTime = dwellTime
                            #     return
                            # end
                            

                            if checkPackedCore(targetPairs[3-i][1].id, architecture)
                                qubit.executionTime = refTime
                                if targetPairs[3-i][1].doEmpty == 0 # architecture.components["cores"][targetCoreID].capacity/4
                                    emptyCore(targetPairs[3-i][1].id, architecture, multiGateTable, shuttlingTable)
                                    return
                                else
                                    targetPairs[3-i][1].doEmpty = 0
                                end
                            end

                            tmp = CommunicationProtocol.buildCommunicationOperations(appliedQubits[i], operation, multiGateTable, architecture, shuttlingTable)
                            if tmp == false
                                qubit.executionTime = refTime
                                return
                            end
                            communicationOperations, shuttlingRoute = tmp
                            push!(shuttlingTable, [appliedQubits[i].id, shuttlingRoute, false])

                            for communicationOperation in reverse(communicationOperations)
                                pushfirst!(appliedQubits[i].circuitQubit.operations, communicationOperation)
                            end
                        end
                    end

                end
                return
            else
                if checkEndOperation(appliedQubits, refTime)
                    if operation.name == "swap"
                        targetCore = targetPairs[1][1]
                        if targetCore.qubitsList[end] == targetPairs[2][2]
                            for i in 1:length(targetCore.qubitsList)
                                if targetCore.qubitsList[i].id == targetPairs[1][2].id
                                    targetCore.qubitsList[i] = targetCore.qubitsList[end]
                                    targetCore.qubitsList[end] = targetPairs[1][2]
                                    targetCore.qubitsList[i].isCommunicationQubit = false
                                    targetCore.qubitsList[end].isCommunicationQubit = true
                                    targetCore.qubitsList[i].executionTime += operation.duration
                                    targetCore.qubitsList[end].executionTime += operation.duration
                                    break
                                end
                            end
                        elseif targetCore.qubitsList[end] == targetPairs[1][2]
                            for i in 1:length(targetCore.qubitsList)
                                if targetCore.qubitsList[i].id == targetPairs[2][2].id
                                    targetCore.qubitsList[i] = targetCore.qubitsList[end]
                                    targetCore.qubitsList[end] = targetPairs[2][2]
                                    targetCore.qubitsList[i].isCommunicationQubit = false
                                    targetCore.qubitsList[end].isCommunicationQubit = true
                                    targetCore.qubitsList[i].executionTime += operation.duration
                                    targetCore.qubitsList[end].executionTime += operation.duration
                                    break
                                end
                            end
                        else
                            for i in 1:length(targetCore.qubitsList)
                                for k in 1:length(targetCore.qubitsList)
                                    if targetCore.qubitsList[i].id == targetPairs[1][2].id
                                        if targetCore.qubitsList[k].id == targetPairs[2][2].id
                                            targetCore.qubitsList[i] = targetCore.qubitsList[k]
                                            targetCore.qubitsList[k] = targetPairs[1][2]
                                            targetCore.qubitsList[i].executionTime += operation.duration
                                            targetCore.qubitsList[k].executionTime += operation.duration
                                            break
                                        end
                                    end
                                end
                            end
                        end
                    end
                    for i in appliedQubits
                        if typeof(i.circuitQubit.operations[1]) ==  Main.CommunicationConfiguration.Shuttling
                            return
                        end
                        
                        i.executionTime += operation.duration
                        popfirst!(i.circuitQubit.operations)
                    end
                    return
                else
                    return
                end
            end
           
            
            # TODO: scheduling()
        
        elseif operationType == Main.QCCDSimulator.QCCDShuttlingProtocol.CommunicationConfiguration.Shuttling

            # TODO: multi qubit shuttling
            # TODO: optimize to piplining
            currentCoordinates = operation.currentCoordinates
            nextCoordinates = operation.nextCoordinates
            currentComponent = architecture.topology[currentCoordinates[1], currentCoordinates[2]]
            nextComponent = architecture.topology[nextCoordinates[1], nextCoordinates[2]]
            currentComponentType = typeof(currentComponent)
            nextComponentType = typeof(nextComponent)
            targetCoreID = operation.targetCoreID
            startingCoreID = operation.startingCoreID
            targetCore = nothing
            startingCore = nothing

            for core in values(architecture.components["cores"])
                if core.id == targetCoreID
                    targetCore = core
                    break
                end
            end
            for core in values(architecture.components["cores"])
                if core.id == startingCoreID
                    startingCore = core
                    break
                end
            end

            # A architecture can do shuttling only one thing at once
            # if architecture.isShuttling && !qubit.isShuttling
            #     dwellTime = refTime
            #     qubit.executionTime = dwellTime
            #     return
            # end

            if operation.type == "split"
                if !checkDoShuttlingNextComponent(nextCoordinates, shuttlingTable, qubit.id) && !targetCore.isPreparedCommunication
                    qubit.executionTime += operation.duration
                    noOfQubits = length(currentComponent.qubits)
                    proportion = currentComponent.noOfPhonons/noOfQubits

                    # debug
                    if length(currentComponent.qubitsList) != 1
                        if qubit.id != currentComponent.qubitsList[end].id
                            println("qubit: $(qubit.
                            id) $(qubit.isCommunicationQubit), endqubit: $(currentComponent.qubitsList[end].id) $(currentComponent.qubitsList[end].isCommunicationQubit)")
                            println("qubit")
                            for op in qubit.circuitQubit.operations
                                if typeof(op) == Main.QCCDSimulator.QCCDShuttlingProtocol.CommunicationConfiguration.Shuttling
                                    print("$(op.type) ")
                                else 
                                    print("$(op.name) ")
                                end
                            end
                            println("\nend")
                            for op in currentComponent.qubitsList[end].circuitQubit.operations
                                if typeof(op) == Main.QCCDSimulator.QCCDShuttlingProtocol.CommunicationConfiguration.Shuttling
                                    print("$(op.type) ")
                                else 
                                    print("$(op.name) ")
                                end
                            end
                            println()
                            for  qqq in values(currentComponent.qubitsList)
                                if qqq.isCommunicationQubit
                                    println("qubit: $(qqq.id) $(qqq.isCommunicationQubit)")
                                end
                            end
                            @assert(false)
                        end
                        currentComponent.qubitsList[end-1].isCommunicationQubit = true
                        currentComponent.qubitsList = currentComponent.qubitsList[1:end-1]
                    else
                        currentComponent.qubitsList = []
                    end
                    
                    delete!(currentComponent.qubits, qubit.id)
                    currentComponent.noOfPhonons = (noOfQubits-1)*proportion + operation.heatingRate[1] # split
                    currentComponent.executionTime = qubit.executionTime
                    
                    """
                    old swap protocol
                    """
                    # qubitList = collect(keys(currentComponent.qubits))
                    # qubitPairList = []
                    # for i in qubitList
                    #     push!(qubitPairList, (parse(Int64, i[6:end]), i))
                    # end
                    # sort!(qubitPairList)
                    # if length(qubitPairList)>0
                    #     currentComponent.qubits[qubitPairList[end][2]].isCommunicationQubit = true
                    # end


                    nextComponent.isShuttling = true
                    # TODO
                    # nextComponent.direction # path
                    push!(nextComponent.qubits, qubit)
                    currentComponent.executionTime = qubit.executionTime

                    qubit.noOfPhonons = proportion + operation.heatingRate[2] # split

                    startingCore.isPreparedCommunication = false

                    popfirst!(qubit.circuitQubit.operations)
                    deleteShuttlingRoute(qubit.id, currentCoordinates, shuttlingTable, qubit.executionTime)

                    # println("$(qubit.executionTime) Split! from $(currentComponent.id), $(qubit.id)")

                else # TODO: dwell time
                    qubit.executionTime = nextComponent.executionTime
                    return
                end

            elseif operation.type == "merge"
                if !checkDoShuttlingNextComponent(nextCoordinates, shuttlingTable, qubit.id)
                    architecture.isShuttling =false
                    qubit.executionTime += operation.duration

                    currentComponent.isShuttling = false
                    currentComponent.qubits = []
                    currentComponent.executionTime = qubit.executionTime

                    for i in values(nextComponent.qubits)
                        if i.isCommunicationQubit
                            @assert(i.id == nextComponent.qubitsList[end].id, "commqubit: $(i.id), endqubit: $(nextComponent.qubitsList[end].id)")
                            i.isCommunicationQubit = false
                        end
                    end
                    nextComponent.qubits[qubit.id] = qubit
                    push!(nextComponent.qubitsList, qubit)
                    @assert(qubit.id == nextComponent.qubitsList[end].id, "qubit: $(qubit.id), endqubit: $(nextComponent.qubitsList[end].id)")
                    nextComponent.executionTime = qubit.executionTime
                    nextComponent.noOfPhonons += qubit.noOfPhonons + operation.heatingRate # merge

                    qubit.noOfPhonons = 0.0
                    qubit.isShuttling = false
                    architecture.noOfShuttling += 1
                    popfirst!(qubit.circuitQubit.operations)
                    deleteShuttlingRoute(qubit.id, currentCoordinates, shuttlingTable, qubit.executionTime)
                    # deleteShuttlingRoute(qubit.id, nextCoordinates, shuttlingTable, qubit.executionTime)

                    # println("$(qubit.executionTime) Merge! to $(nextComponent.id), $(qubit.id)")

                else # TODO: dwell time
                    # println("dwell, $(nextComponent.executionTime)")
                    qubit.executionTime = nextComponent.executionTime
                    return
                end

            elseif operation.type == "linearTransport"
                if currentComponentType == Main.ArchitectureConfiguration.Path
                    if !checkDoShuttlingNextComponent(nextCoordinates, shuttlingTable, qubit.id)
                        qubit.executionTime += currentComponent.length/(operation.speed)
                        qubit.noOfPhonons += operation.heatingRate

                        currentComponent.isShuttling = false
                        currentComponent.qubits = []
                        # currentComponent.direction = 
                        currentComponent.executionTime = qubit.executionTime

                        nextComponent.isShuttling = true
                        push!(nextComponent.qubits, qubit)
                        nextComponent.executionTime = qubit.executionTime

                        popfirst!(qubit.circuitQubit.operations)
                        deleteShuttlingRoute(qubit.id, currentCoordinates, shuttlingTable, qubit.executionTime)

                        # println("$refTime transport from $(currentComponent.id) to $(nextComponent.id), $(qubit.id)")


                    else # TODO: dwell time
                        qubit.executionTime = nextComponent.executionTime
                        return
                    end

                elseif currentComponentType == Main.ArchitectureConfiguration.Junction
                    if !checkDoShuttlingNextComponent(nextCoordinates, shuttlingTable, qubit.id)
                        qubit.executionTime += nextComponent.length/(operation.speed)
                        qubit.noOfPhonons += operation.heatingRate

                        currentComponent.isShuttling = false
                        currentComponent.qubits = []
                        # currentComponent.direction = 
                        currentComponent.executionTime = qubit.executionTime

                        nextComponent.isShuttling = true
                        push!(nextComponent.qubits, qubit)
                        nextComponent.executionTime = qubit.executionTime

                        popfirst!(qubit.circuitQubit.operations)
                        deleteShuttlingRoute(qubit.id, currentCoordinates, shuttlingTable, qubit.executionTime)

                        # println("$refTime transport from $(currentComponent.id) to $(nextComponent.id), $(qubit.id)")

                    else # TODO: dwell time
                        qubit.executionTime = nextComponent.executionTime
                        return
                    end
                end

            elseif operation.type == "junctionRotate"
                if !checkDoShuttlingNextComponent(nextCoordinates, shuttlingTable, qubit.id)
                    qubit.executionTime += operation.duration
                    qubit.noOfPhonons += operation.heatingRate

                    # currentComponent.isShuttling = false
                    # currentComponent.qubits = []
                    # currentComponent.executionTime = qubit.executionTime

                    nextComponent.isShuttling = true
                    # push!(nextComponent.qubits, qubit)
                    nextComponent.executionTime = qubit.executionTime

                    popfirst!(qubit.circuitQubit.operations)
                    # deleteShuttlingRoute(qubit.id, currentCoordinates, shuttlingTable)
                    # println("$refTime rotate at $(currentComponent.id), $(qubit.id)")

                else # TODO: dwell time
                    qubit.executionTime = nextComponent.executionTime
                    return
                end
            else
            end
        end
    end

    function executeCircuit(circuit, architecture)
        refTime = 0.1
        circuitQubits = circuit["circuit"].qubits
        multiGateTable = circuit["multiGateTable"]
        shuttlingTable = []
        
        qubits = Dict()
        for i in values(architecture.components["cores"])
            merge!(qubits, i.qubits)
        end

        while true
            for qubit in values(qubits)
                if checkEndOperation(qubit, refTime)
                    executeOperation(qubit, refTime, multiGateTable, architecture, shuttlingTable)
                    deleteShuttlingRoutByTime(shuttlingTable, refTime)
                end
            end

            # check ending
            remainderOperation = 0
            for i in circuitQubits
                remainderOperation += length(i.operations)
            end
            if remainderOperation == 0
                break
            end


            # TODO: remove the printing part

            # if refTime%1000 < 1
            #     println(refTime, remainderOperation)
            # end
            refTime += 1
        end
    end

    function evaluateResult(architecture)
        executionTimeList = []
        noOfPhonons = Dict()
        cores = architecture.components["cores"]
        qubits = Dict()
        for i in values(cores)
            merge!(qubits, i.qubits)
        end

        for i in values(qubits)
            time = i.executionTime
            append!(executionTimeList, time)
        end
        executionTime = maximum(executionTimeList)
        
        for i in cores
            noOfPhonons[i[1]] = i[2].noOfPhonons
        end
        
        result = Dict()
        result["executionTime"] = executionTime
        result["noOfPhonons"] = noOfPhonons
        return result
    end

    function run(circuit, configuration)
        architecture = configuration["architecture"]
        operationConfiguration = configuration["operation"]

        executeCircuit(circuit, architecture)
        result = evaluateResult(architecture)
        return (result, architecture)
    end

    function printResult(result,architecture)
        println("Execution time is $(result["executionTime"])")
        println("Number of shuttling is $(architecture.noOfShuttling)")
        println("Number of phonons per core are")
        for i in result["noOfPhonons"]
            println("$(i[1]): $(i[2])")
        end
    end

end

# TODO: renovate to fit Q-bus
module QBusSimulator
    import ..CostCalculator
    import ..ErrorCalculator
    include("../input/communication_protocol.jl")
    CommunicationProtocol = QBusShuttlingProtocol # architecture dependency

    function checkNeedCommunication(appliedQubits, architecture)
        if String ∈ typeof.(appliedQubits)
            return false
        end
        appliedCores = []
        for appliedQubit in appliedQubits
            for core in values(architecture.components["cores"])
                for qubitID in keys(core.qubits)
                    if qubitID == appliedQubit.id
                        push!(appliedCores, core)
                        break
                    end
                end
            end
        end
        for i in 1:length(appliedCores)-1
            if appliedCores[i].id !== appliedCores[i+1].id
                return true
            end
        end
        return false
    end

    function checkEndOperation(qubit,refTime) # (Qubit, Float64)
        qubitTime = qubit.executionTime
        if refTime > qubitTime
            return true
        end
        return false
    end

    function checkEndOperation(appliedQubits::Vector,refTime)
        if String ∈ typeof.(appliedQubits)
            return false
        end
        firstOperations = []
        for qubit in appliedQubits
            push!(firstOperations, qubit.circuitQubit.operations[1])
        end
        for i in firstOperations
            if typeof(i) !== Main.CircuitBuilder.OperationConfiguration.MultiGate 
                # && typeof(i) !== Main.QBusSimulator.QBusShuttlingProtocol.CircuitBuilder.OperationConfiguration.MultiGate
                return false
            end
        end
        for i in 1:length(firstOperations)-1
            if firstOperations[i].id !== firstOperations[i+1].id
                return false
            end
        end
        qubitTimeList = []
        for qubit in appliedQubits
            qubitTime = qubit.executionTime
            append!(qubitTimeList, qubitTime)
        end
        qubitTime = maximum(qubitTimeList)

        if refTime > qubitTime
            for qubit in appliedQubits
                qubit.executionTime = qubitTime
            end
            return true
        end
        return false
    end

    # TODO Q-bus
    function executeShuttlingByLayer(architecture, shuttlingDict, shuttlingDuration, refTime)
        cores = architecture.components["cores"]
        appliedQubits = []
        countingCores = Dict()
        for i in keys(cores)
            countingCores[i] = 0
        end

        for targetPairs in values(shuttlingDict)
            for  targetPair in targetPairs
                countingCores[targetPair[1].id] += 1
                push!(appliedQubits,targetPair[2])
            end
        end


        for core in values(cores)
            noOfQubits = length(core.qubits) + countingCores[core.id]
            proportion = (core.noOfPhonons+ countingCores[core.id]*2.38)/noOfQubits
            if countingCores[core.id] !== 0
                core.noOfPhonons = (noOfQubits-countingCores[core.id])*proportion + 1.1 # split
            end
        end

        for qubit in appliedQubits
            qubit.executionTime = refTime + shuttlingDuration
            popfirst!(qubit.circuitQubit.operations)
        end
        
        shuttlingCounting = length(appliedQubits)/2
        return shuttlingCounting
    end
    
    function executeOperation(qubit, refTime, multiGateTable, architecture, shuttlingDict, operationIndex) # (Qubit, Float64, Dict, Architecture)
        operations = qubit.circuitQubit.operations
        if length(operations) == 0
            return
        end
        operation = operations[operationIndex]
        operationType = typeof(operation)

        if operationType == Main.CircuitBuilder.OperationConfiguration.SingleGate || operationType == Main.CircuitBuilder.OperationConfiguration.Measure
            #  || operationType == Main.CircuitBuilder.OperationConfiguration.Measure
            qubit.executionTime += operation.duration
            popfirst!(qubit.circuitQubit.operations)
            return
        elseif operationType == Main.CircuitBuilder.OperationConfiguration.MultiGate
            #  || operationType == Main.Simulator.QBusShuttlingProtocol.CircuitBuilder.OperationConfiguration.MultiGate
            operationID = operation.id
            appliedQubits = deepcopy(multiGateTable[operationID]["appliedQubits"])

            qubits = Dict()
            targetPairs = []
            coreList = values(architecture.components["cores"])
            for core in coreList
                merge!(qubits, core.qubits)
            end

            for i in 1:length(appliedQubits)
                for k in values(qubits)
                    if k.circuitQubit.id == appliedQubits[i]
                        appliedQubits[i] = k
                    end
                    # @assert(k < length(qubits),"Not found qubit")
                end
            end
            if String ∈ typeof.(appliedQubits)
                return
            end
            for i in 1:length(appliedQubits)
                for core in coreList
                    for q in values(core.qubits)
                        if q.circuitQubit.id == appliedQubits[i].circuitQubit.id
                            push!(targetPairs, (core, appliedQubits[i]))
                        end
                    end
                end
            end

            # To determine the parallelism of 2-qubit gates
            # isControlledQubit = false
            # if appliedQubits[1] == qubit
            #     isControlledQubit = true
            # end

            # TODO Q-Bus
            if checkNeedCommunication(appliedQubits, architecture)

                if !checkEndOperation(appliedQubits, refTime) || haskey(shuttlingDict, operationID)
                    return
                end
                for i in 1:length(appliedQubits)
                    # communicationOperation = CommunicationProtocol.buildGateTeleportationOperations()
                    communicationOperation =  "ShuttlingOperation"
                    popfirst!(appliedQubits[i].circuitQubit.operations)
                    pushfirst!(appliedQubits[i].circuitQubit.operations, communicationOperation)
                end
                shuttlingDict[operationID] = targetPairs
                return
            else
                if checkEndOperation(appliedQubits, refTime)
                    for i in appliedQubits
                        if typeof(i.circuitQubit.operations[1]) ==  Main.QCCDSimulator.QCCDShuttlingProtocol.CommunicationConfiguration.Shuttling
                            return
                        end
                        i.executionTime += operation.duration
                        popfirst!(i.circuitQubit.operations)
                    end
                    return
                else
                    return
                end
            end
        end
    end

    function executeCircuit(circuit, architecture, shuttlingType)
        shuttlingDurations = Dict([
            ("Slow Junction Rotation & Normal Detection", 705 + round((length(architecture.components["cores"])-2)*100/78,digits=1)),
            ("Slow Junction Rotation & SNSD", 536 + round((length(architecture.components["cores"])-2)*100/78, digits=1)),
            ("Fast Junction Rotation & Normal Detection", 385 + round((length(architecture.components["cores"])-2)*100/78, digits=1)),
            ("Fast Junction Rotation & SNSD", 216 + round((length(architecture.components["cores"])-2)*100/78, digits=1))
        ])

        shuttlingDuration = shuttlingDurations[shuttlingType]
        shuttlingDict = Dict()
        shuttlingCounting = 0

        refTime = 0.1
        circuitQubits = circuit["circuit"].qubits
        multiGateTable = circuit["multiGateTable"]

        qubits = Dict()
        for i in values(architecture.components["cores"])
            merge!(qubits, i.qubits)
        end

        while true
            # TODO Shuttling by layer
            if refTime % shuttlingDuration < 1.0
                shuttlingCounting += executeShuttlingByLayer(architecture, shuttlingDict, shuttlingDuration, refTime) ## TODO
                shuttlingDict = Dict()
            end
            for qubitID in keys(qubits)
                if checkEndOperation(qubits[qubitID], refTime)
                    executeOperation(qubits[qubitID], refTime, multiGateTable, architecture, shuttlingDict, 1)
                end
                if length(qubits[qubitID].circuitQubit.operations) == 0
                    delete!(qubits,qubitID)
                end
            end
            
            # check ending
            remainderOperation = 0
            for i in circuitQubits
                remainderOperation += length(i.operations)
            end
            if remainderOperation == 0
                break
            end

            # if refTime%5 < 1
            #     println(refTime)
            # end
            # if refTime%100 < 1
            #     println(refTime, remainderOperation)
            # end
            refTime += 1
        end
        return shuttlingCounting
    end

    function evaluateResult(architecture)
        executionTimeList = []
        noOfPhonons = Dict()
        cores = architecture.components["cores"]
        qubits = Dict()
        for i in values(cores)
            merge!(qubits, i.qubits)
        end

        for i in values(qubits)
            time = i.executionTime
            append!(executionTimeList, time)
        end
        executionTime = maximum(executionTimeList)
        
        for i in cores
            noOfPhonons[i[1]] = i[2].noOfPhonons
        end
        
        result = Dict()
        result["executionTime"] = executionTime
        result["noOfPhonons"] = noOfPhonons
        return result
    end

    function run(circuit, configuration, typeIndex)
        architecture = configuration["architecture"]
        operationConfiguration = configuration["operation"]

        # println()
        # println("What is the shuttling type? \n (answer the number)")

        shuttlingTypes = Dict([
            ("1", "Slow Junction Rotation & Normal Detection"),
            ("2", "Slow Junction Rotation & SNSD"),
            ("3", "Fast Junction Rotation & Normal Detection"),
            ("4", "Fast Junction Rotation & SNSD")])

        # for i in 1:4
        #     shuttlingType = shuttlingTypes["$i"]
        #     println("$i. $shuttlingType")
        # end
        # println()
        # ans = readline()
        # shuttlingType = shuttlingTypes[ans]

        shuttlingType = shuttlingTypes[typeIndex]
        shuttlingCounting = executeCircuit(circuit, architecture, shuttlingType)
        result = evaluateResult(architecture)
        result["shuttlingCounting"] = shuttlingCounting
        return (result, architecture)
    end

    function printResult(result,architecture)
        println("Execution time is $(result["executionTime"])")
        if architecture.name == "Q-bus"
            println("Number of shuttling is $(result["shuttlingCounting"])")
        else
            println("Number of shuttling is $(architecture.noOfShuttling)")
        end
        println("Number of phonons per core are")
        for i in result["noOfPhonons"]
            println("$(i[1]): $(i[2])")
        end

        # save the results
        # output = JSON.json(result)
        
        # open("$name.json","w") do f 
        #     JSON.write(f, output) 
        # end
    end

end