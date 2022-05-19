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

    function checkNeedCommunication()
    end

    function communicateInterCore()
    end

    function scheduling()
    end

    function checkEndOperation(qubit::Qubit,refTime)
        qubitTime = qubit.executionTime + qubit.communicationTime + qubit.dwellTime
        if refTime > qubitTime
            return true
        end
        return false
    end

    function executeOepration(qubit::Qubit)
        operation = popfirst!(qubit.circuitQubit.operations)
        operationType = typeof(operation)
        if operationType == SingleGate
            qubit.executionTime += operaiton.duration
        elseif operationType == MultiGate
            checkNeedCommunication()
            scheduling()
            communicateInterCore()
        # elseif
        end
    end

    function executeCircuitQubit(circuit, architecture)
        refTime = 0.1
        circuitQubits = circuit["circuit"].qubits

        qubits = Dict()
        for i in architecture.components["cores"]
            merge!(qubits, i.qubits)
        end

        while 1
            for i in qubits
                if checkEndOperation(i, refTime)
                    executeOperation(i)
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
        for i in architecture.components["cores"]
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

    function run(circuit, architecture)
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