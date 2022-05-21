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
        appliedCores = []
        for appliedQubit in appliedQubits
            for core in values(architecture.components["cores"])
                for qubitID in keys(core.qubits)
                    if qubitID == appliedQubit.id
                        append!(appliedCores, core)
                        break
                    end
                end
            end
        end
        for i in 1:length(appliedCores)-1
            if appliedCores[i] !== appliedCores[i+1]
                return true
            end
        end
        return false
    end

    function communicateInterCore()
    end

    function scheduling()
    end

    function checkEndOperation(qubit::Qubit,refTime)
        qubitTime = qubit.executionTime
        if refTime > qubitTime
            return true
        end
        return false
    end

    function checkEndOperation(appliedQubits::Vector,refTime)
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

    function executeOperation(qubit::Qubit, refTime, multiGateTable, architecture)
        operation = qubit.circuitQubit.operations[1]
        operationType = typeof(operation)
        if operationType == SingleGate
            qubit.executionTime += operation.duration
            popfirst!(qubit.circuitQubit.operation)
            return
        elseif operationType == MultiGate
            operationID = operation.id
            appliedQubits = multiGateTable[operationID]

            qubits = Dict()
            for core in values(architecture.components["cores"])
                merge!(qubits, core.qubits)
            end

            for i in 1:length(appliedQubits)
                for k in 1:length(values(qubits))
                    if qubits[k].circuitQubit.id == appliedQubits[i]
                        appliedQubits[i] = qubits[k]
                        break
                    end
                    @assert(k < length(qubits),"Not found qubit")
                end
            end

            if checkNeedCommunications(appliedQubits, architecture)
                for i in 1:length(appliedQubits)
                    if checkEndOperation(appliedQubits[i], refTime)
                        communicationOperations = CommunicationProtocol.buildCommunicationOperations(appliedQubits[i], operation, multiGateTable, architecture)
                        for communicationOperation in reverse(communicationOperations)
                            pushfirst!(appliedQubits[i].circuitQubit.operation, communicationOperation)
                        end
                    else
                        if i == length(appliedQubits)
                            communicationOperations = CommunicationProtocol.buildCommunicationOperations(appliedQubits[i], operation, multiGateTable, architecture)
                            for communicationOperation in reverse(communicationOperations)
                                pushfirst!(appliedQubits[i].circuitQubit.operation, communicationOperation)
                            end
                        end
                    end
                end
                
                return
            else
                if checkEndOperation(appliedQubits, refTime)
                    for qubit in appliedQubits
                        qubit.executionTime += operation.duration
                        popfirst!(qubit.circuitQubit.operation)
                        return
                    end
                else
                    return
                end
            end
           
            
            # TODO: scheduling()
        
        elseif operationType == Shuttling
            # TODO: execute shuttling
        end
    end

    function executeCircuitQubit(circuit, architecture)
        refTime = 0.1
        circuitQubits = circuit["circuit"].qubits
        multiGateTable = circuit["multiGateTable"]

        qubits = Dict()
        for i in architecture.components["cores"]
            merge!(qubits, i.qubits)
        end

        while 1
            for i in qubits
                if checkEndOperation(i, refTime)
                    executeOperation(i, refTime, multiGateTable, architecture)
                end
            end

            # check ending
            remainderOperation = 0
            for i in circuitQubits
                remainderOperation += length(i.operations)
            end
            if remainderOperaiton == 0
                break
            end
            refTime += 0.1
        end
    end

    function evaluateResult(architecture)
        executionTimeList = []
        noOfPhonons = Dict()
        cores = architecture.component["cores"]
        qubits = Dict()
        for i in cores
            merge!(qubits, i.qubits)
        end

        for i in valuse(qubits)
            time = i.executionTime + i.communicationTime + i.dwellTime
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

        executeCircuitQubit(circuit, architecture)
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