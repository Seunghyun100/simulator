import JSON


"""
Input
"""
name = # name
noQubits = #number of qubits



id = 1

function two(name, q1, q2)
    output = [id,name,q1,q2]
    id += 1
    return output
end

function initCircuit(no::Int64)
    circuit = Dict()
    for i in 1:no
        circuit["q$i"] = []
    end
    return circuit
end

circuit = initCircuit(noQubits)


"""
Output
"""
config = Dict("name"=>name, "number_of_qubits"=>noQubits, "qubits" =>circuit)


output = JSON.json(Dict(name => config))