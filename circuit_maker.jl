import JSON

"""
Input
"""
name = # name
noQubits = #number of qubits


"""
Operation
"""
x = "x"
y = "y"
z = "z"
rx = "rx"
ry = "ry"
rz = "rz"
h = "h"
s = "s"
t = "t"
    
cx = "cx"
cy = "cy"
cz = "cz"
rxx = "rxx"
ryy = "ryy"
rzz = "rzz"
swap = "swap"
toffoli = "toffoli"
    
init = "init"
m = "commonMeasure"
fast_m = "snspMeasure"

"""
function
"""

id = 1

# two-qubit gate
function 2(name, q1, q2)
    output = [id,name,q1,q2]
    id += 1
    push!(circuit["q$q1"], output)
    push!(circuit["q$q2"], output)
    return output
end

#single gate
function 1(name, q)
    push!(circuit["q$q"], name)
    return
end
#measurement

function initCircuit(no::Int64)
    circuit = Dict()
    for i in 1:no
        circuit["q$i"] = []
    end
    return circuit
end

circuit = initCircuit(noQubits)

"""
Circuit
"""



"""
Output
"""
config = Dict("name"=>name, "number_of_qubits"=>noQubits, "qubits" =>circuit)


output = JSON.json(Dict(name => config))