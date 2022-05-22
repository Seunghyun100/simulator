module NonOptimizedMapper

    # function countConnection(circuit,architecture)
    #     multiGateTable = circuit["multiGateTable"]
    #     noQubits = length(circuit["circuit"].qubits)
    #     counting = Dict()
    #     for i in 1:noQubits
    #         qubitID = "q$i"
    #         counting[qubitID] = Vector()
    #         for k in 1:length(multiGateTable)
    #             if qubitID in multiGateTable[k]
    #                 push!(countin[qubitID], k)
    #             end
    #         end
    #     end

    # end

    function mapping(circuit, architecture)
        circuitQubits = circuit["circuit"].qubits
        noOfCircuitQubits = length(circuitQubits)

        qubits = Dict()
        for i in values(architecture.components["cores"])
            merge!(qubits, i.qubits)
        end

        # mapConfiguraiton = Dict()
        for i in 1:length(circuitQubits)
            qubits["Qubit$i"].circuitQubit = circuitQubits[i]
        end
        return qubits
    end
end