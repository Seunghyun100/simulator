module Scheduler
end

module CostCalculator
    import ..Scheduler
end

module ErrorCalculator
end

module Simulator
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
            if typeof(i) !== Main.CircuitBuilder.OperationConfiguration.MultiGate && typeof(i) !== Main.Simulator.QCCDShuttlingProtocol.CircuitBuilder.OperationConfiguration.MultiGate
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

        if operationType == Main.CircuitBuilder.OperationConfiguration.SingleGate
            qubit.executionTime += operation.duration
            popfirst!(qubit.circuitQubit.operations)
            return
        elseif operationType == Main.CircuitBuilder.OperationConfiguration.MultiGate || operationType == Main.Simulator.QCCDShuttlingProtocol.CircuitBuilder.OperationConfiguration.MultiGate
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
                for i in 1:length(appliedQubits)
                    isShuttling = false
                    for q in values(targetPairs[i][1].qubits)
                        if q.isCommunicationQubit
                            isShuttling = q.isShuttling
                        end
                    end
                    if checkEndOperation(appliedQubits[i], refTime) && !multiGateTable[operationID]["isPreparedCommunication"] && !isShuttling
                        communicationOperations = CommunicationProtocol.buildCommunicationOperations(appliedQubits[i], operation, multiGateTable, architecture)
                        push!(communicationOperations, popfirst!(appliedQubits[i].circuitQubit.operations))
                        for s in reverse(communicationOperations[2:end-1])
                            push!(communicationOperations, s)
                        end
                        for communicationOperation in reverse(communicationOperations)
                            pushfirst!(appliedQubits[i].circuitQubit.operations, communicationOperation)
                        end
                    else
                        if i == length(appliedQubits) && !multiGateTable[operationID]["isPreparedCommunication"]  && !isShuttling
                            communicationOperations = CommunicationProtocol.buildCommunicationOperations(appliedQubits[i], operation, multiGateTable, architecture)
                                push!(communicationOperations, popfirst!(appliedQubits[i].circuitQubit.operations))
                            for s in reverse(communicationOperations[2:end-1])
                                push!(communicationOperations, s)
                            end
                            for communicationOperation in reverse(communicationOperations)
                                pushfirst!(appliedQubits[i].circuitQubit.operations, communicationOperation)
                            end
                        end
                    end
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
        
        elseif operationType == Main.Simulator.QCCDShuttlingProtocol.CommunicationConfiguration.Shuttling
            # TODO: multi qubit shuttling
            # TODO: optimize to piplining
            currentCooordinates = operation.currentCoordinates
            nextCoordinates = operation.nextCoordinates
            currentComponent = architecture.topology[currentCooordinates[1], currentCooordinates[2]]
            nextComponent = architecture.topology[nextCoordinates[1], nextCoordinates[2]]
            currentComponentType = typeof(currentComponent)
            nextComponentType = typeof(nextComponent)


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
                    currentComponent.qubits[qubitPairList[end][2]].isCommunicationQubit = true

                    nextComponent.isShuttling = true
                    # TODO
                    # nextComponent.direction # path
                    push!(nextComponent.qubits, qubit)
                    currentComponent.executionTime = qubit.executionTime

                    qubit.noOfPhonons = proportion + operation.heatingRate[2] # split

                    popfirst!(qubit.circuitQubit.operations)
                else # TODO: dwell time
                end

            elseif operation.type == "merge"
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
                    popfirst!(qubit.circuitQubit.operations)
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

            if refTime%5 < 0.1
                println(refTime)
            end
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
        return result
    end

    function printResult(result)
        println("Execution time is $(result["executionTime"])")
        println()
        println("Number of phonons per core are")
        for i in result["noOfPhonons"]
            println("$(i[1]): $(i[2])")
        end
    end

end