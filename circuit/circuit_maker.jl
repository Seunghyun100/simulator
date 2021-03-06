import JSON

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
function two(name, q1, q2)
    output = [id,name,"q$q1","q$q2"]
    global id += 1
    push!(circuit["q$q1"], output)
    push!(circuit["q$q2"], output)
    return output
end

#single gate
function one(name, q::Int64)
    push!(circuit["q$q"], name)
    return name
end
#measurement

function initCircuit(no::Int64)
    circuit = Dict()
    for i in 1:no
        circuit["q$i"] = []
    end
    return circuit
end

"""
Input
"""

# name = "bernstein-vazirani" # name
# noQubits = 90 # number of qubits
# circuit = initCircuit(noQubits)

# """
# Circuit
# """

# for i in 1:noQubits
#     one(h, i)
# end
# one(z,noQubits)

# # Oracle
# for i in 1:noQubits
#     if rand(Bool)
#         two(cx, i, noQubits)
#     end
# end

# #
# for i in 1:noQubits
#     one(h, i)
#     one(m, i)
# end


name = "quantum-fourier-transformation-60" # name
noQubits = 60 # number of qubits
circuit = initCircuit(noQubits)

for i in 1:noQubits
    one(h,i)
    for k in i:noQubits
        two(cz,i, k)
    end
end
for i in 1:Int(noQubits/2)
    two(swap, i, noQubits-i+1)
end


"""
Output
"""

config = Dict("name"=>name, "number_of_qubits"=>noQubits, "qubits" =>circuit)


output = JSON.json(Dict(name => config))

open("$name.json","w") do f 
    JSON.write(f, output) 
end