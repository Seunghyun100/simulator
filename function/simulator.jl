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

    function executeOperation(qubit, refTime, multiGateTable, architecture) # (Qubit, Float64, Dict, Architecture)
        operations = qubit.circuitQubit.operations
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
                    if architecture.isShuttling
                        dwellTime = refTime
                        appliedQubits[i].executionTime = dwellTime
                        return
                    end

                    """
                    optimized from
                    """

                    if checkEndOperation(appliedQubits[i], refTime) && !multiGateTable[operationID]["isPreparedCommunication"] && !isShuttling
                        communicationOperations = CommunicationProtocol.buildCommunicationOperations(appliedQubits[i], operation, multiGateTable, architecture)
                        # push!(communicationOperations, popfirst!(appliedQubits[i].circuitQubit.operations))
                        # for s in reverse(communicationOperations[2:end-1])
                        #     push!(communicationOperations, s)
                        # end
                        for communicationOperation in reverse(communicationOperations)
                            pushfirst!(appliedQubits[i].circuitQubit.operations, communicationOperation)
                        end
                    else

                    """
                    optimized to
                    """

                        if i == length(appliedQubits) && !multiGateTable[operationID]["isPreparedCommunication"]  && !isShuttling
                            if architecture.isShuttling
                                dwellTime = refTime
                                appliedQubits[i].executionTime = dwellTime
                                return
                            end

                    # """
                    # optimized from
                    # """

                    # appliedCore1 = nothing
                    # appliedCore2 = nothing
                    # for core in coreList
                    #     if appliedQubits[2].id ∈ keys(core.qubits)
                    #         appliedCore1 = core
                    #         break
                    #     end
                    # end
                    # for core in coreList
                    #     if appliedQubits[1].id ∈ keys(core.qubits)
                    #         appliedCore2 = core
                    #         break
                    #     end
                    # end

                    # if qubit.id == "Qubit60"
                    #     print(qubit.id)
                    # end
                    # if qubit == appliedQubits[2]
                    #     mold = deepcopy(appliedQubits[2].circuitQubit.operations)
                    #     count = 1
                    #     for op in 1:length(appliedQubits[2].circuitQubit.operations)-2
                    #         ck = false
                    #         for qq in values(appliedCore1.qubits)
                    #             if qq.circuitQubit.id == multiGateTable[mold[op].id]["appliedQubits"][1]
                    #                 ck = true
                    #                 count +=1
                    #             end
                    #         end
                    #         if !ck
                    #             mes = pop!(appliedQubits[2].circuitQubit.operations)
                    #             hgate = pop!(appliedQubits[2].circuitQubit.operations)

                    #             push!(appliedQubits[2].circuitQubit.operations, mold[op])
                    #             push!(appliedQubits[2].circuitQubit.operations, hgate)
                    #             push!(appliedQubits[2].circuitQubit.operations, mes)

                    #             deleteat!(appliedQubits[2].circuitQubit.operations, count)
                    #         end
                    #     end
                    # end

                    
                    # # if appliedCore1 !== appliedCore2
                    # #     push!(appliedQubits[i].circuitQubit.operations, popfirst!(appliedQubits[i].circuitQubit.operations))
                    # # end
                    # for qb in values(appliedCore1.qubits)
                    #     if qb.id == appliedQubits[2].id
                    #         continue
                    #     else
                    #         if Main.CircuitBuilder.OperationConfiguration.MultiGate ∈ typeof.(qb.circuitQubit.operations)
                    #             return
                    #         end
                    #     end
                    # end

                    # """
                    # optimized to
                    # """

                    # For optimizing to bernstein-vazirani, change the 'i' to '2'
                    
                            communicationOperations = CommunicationProtocol.buildCommunicationOperations(appliedQubits[i], operation, multiGateTable, architecture)
                            # push!(communicationOperations, popfirst!(appliedQubits[i].circuitQubit.operations))
                            # for s in reverse(communicationOperations[2:end-1])
                            #     push!(communicationOperations, s)
                            # end
                            for communicationOperation in reverse(communicationOperations)
                                pushfirst!(appliedQubits[i].circuitQubit.operations, communicationOperation)
                            end
                        end

                    """
                    optimized from
                    """

                    end
                    
                    """
                    optimized to
                    """

                end
                return
            else
                if checkEndOperation(appliedQubits, refTime)
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
            currentCooordinates = operation.currentCoordinates
            nextCoordinates = operation.nextCoordinates
            currentComponent = architecture.topology[currentCooordinates[1], currentCooordinates[2]]
            nextComponent = architecture.topology[nextCoordinates[1], nextCoordinates[2]]
            currentComponentType = typeof(currentComponent)
            nextComponentType = typeof(nextComponent)

            # A architecture can do shuttling only one thing at once
            if architecture.isShuttling && !qubit.isShuttling
                dwellTime = refTime
                qubit.executionTime = dwellTime
                return
            end

            if operation.type == "split"
                if nextComponent.executionTime < refTime
                    qubit.executionTime += operation.duration
                    noOfQubits = length(currentComponent.qubits)
                    proportion = currentComponent.noOfPhonons/noOfQubits

                    delete!(currentComponent.qubits, qubit.id)
                    currentComponent.noOfPhonons = (noOfQubits-1)*proportion + operation.heatingRate[1] # split
                    currentComponent.executionTime = qubit.executionTime
                    
                    qubitList = collect(keys(currentComponent.qubits))
                    qubitPairList = []
                    for i in qubitList
                        push!(qubitPairList, (parse(Int64, i[6:end]), i))
                    end
                    sort!(qubitPairList)
                    if length(qubitPairList)>0
                        currentComponent.qubits[qubitPairList[end][2]].isCommunicationQubit = true
                    end

                    nextComponent.isShuttling = true
                    # TODO
                    # nextComponent.direction # path
                    push!(nextComponent.qubits, qubit)
                    currentComponent.executionTime = qubit.executionTime

                    qubit.noOfPhonons = proportion + operation.heatingRate[2] # split

                    popfirst!(qubit.circuitQubit.operations)
                    # println("$refTime Split! from $(currentComponent.id), $(qubit.id)")
                else # TODO: dwell time
                end

            elseif operation.type == "merge"
                architecture.isShuttling =false
                if nextComponent.executionTime < refTime
                    qubit.executionTime += operation.duration

                    currentComponent.isShuttling = false
                    currentComponent.qubits = []
                    currentComponent.executionTime = qubit.executionTime

                    for i in values(nextComponent.qubits)
                        if i.isCommunicationQubit
                            i.isCommunicationQubit = false
                        end
                    end
                    nextComponent.qubits[qubit.id] = qubit
                    nextComponent.executionTime = qubit.executionTime
                    nextComponent.noOfPhonons += qubit.noOfPhonons + operation.heatingRate # merge

                    qubit.noOfPhonons = 0.0
                    qubit.isShuttling = false
                    architecture.noOfShuttling += 1
                    popfirst!(qubit.circuitQubit.operations)
                    # println("$refTime Merge! to $(nextComponent.id), $(qubit.id)")

                else # TODO: dwell time
                end

            elseif operation.type == "linearTransport"
                if currentComponentType == Main.ArchitectureConfiguration.Path
                    if nextComponent.executionTime < refTime
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
                        # println("$refTime transport from $(currentComponent.id) to $(nextComponent.id), $(qubit.id)")


                    else # TODO: dwell time
                    end

                elseif currentComponentType == Main.ArchitectureConfiguration.Junction
                    if nextComponent.executionTime < refTime
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
                        # println("$refTime transport from $(currentComponent.id) to $(nextComponent.id), $(qubit.id)")

                    else # TODO: dwell time
                    end
                end

            elseif operation.type == "junctionRotate"
                if nextComponent.executionTime < refTime
                    qubit.executionTime += operation.duration
                    qubit.noOfPhonons += operation.heatingRate

                    # currentComponent.isShuttling = false
                    # currentComponent.qubits = []
                    # currentComponent.executionTime = qubit.executionTime

                    nextComponent.isShuttling = true
                    # push!(nextComponent.qubits, qubit)
                    nextComponent.executionTime = qubit.executionTime

                    popfirst!(qubit.circuitQubit.operations)
                    # println("$refTime rotate at $(currentComponent.id), $(qubit.id)")

                else # TODO: dwell time
                end
            else
            end
        end
    end

    function executeCircuit(circuit, architecture)
        refTime = 0.1
        circuitQubits = circuit["circuit"].qubits
        multiGateTable = circuit["multiGateTable"]

        qubits = Dict()
        for i in values(architecture.components["cores"])
            merge!(qubits, i.qubits)
        end

        while true
            for qubit in values(qubits)
                if checkEndOperation(qubit, refTime)
                    executeOperation(qubit, refTime, multiGateTable, architecture)
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
            if refTime%100 < 1
                println(refTime, remainderOperation)
            end
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
        output = JSON.json(result)
        
        open("$name.json","w") do f 
            JSON.write(f, output) 
        end
    end

end