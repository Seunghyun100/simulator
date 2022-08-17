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


########################

"""
Input
"""
########################

"""
BV strat
"""
# name = "bernstein-vazirani-180" # name
# noQubits = 180 # number of qubits
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
"""
BV end
"""

"""
QFT strat
"""
# name = "quantum-fourier-transformation-180" # name
# noQubits = 180 # number of qubits
# circuit = initCircuit(noQubits)

# for i in 1:noQubits
#     one(h,i)
#     for k in i:noQubits
#         two(cz,i, k)
#     end
# end
# for i in 1:Int(noQubits/2)
#     two(swap, i, noQubits-i+1)
# end
"""
QFT end
"""

"""
Grover start
"""
name = "grover-16x16"
rows = 16
size = rows^2
noQubits = size*2+1 # 73
circuit = initCircuit(noQubits)

for i in 1:size
    one(h,i)
end
one(x, noQubits)
one(h, noQubits)

for iteration in 1:Int(floor(sqrt(size)))
    # Oracle
    for i in 1:size
        two(cx,i,i+size)
        if fld(i,rows) == 0
            if mod(i,rows) == 1
                # two(cx,i,i+size-1)
                two(cx,i,i+size+1)
                # two(cx,i,i+size-rows)
                two(cx,i,i+size+rows)
            elseif mod(i,rows) == 0
                two(cx,i,i+size-1)
                # two(cx,i,i+size+1)
                # two(cx,i,i+size-rows)
                two(cx,i,i+size+rows)
            else
                two(cx,i,i+size-1)
                two(cx,i,i+size+1)
                # two(cx,i,i+size-rows)
                two(cx,i,i+size+rows)
            end
        elseif fld(i,rows) == rows-1
            if mod(i,rows) == 1
                # two(cx,i,i+size-1)
                two(cx,i,i+size+1)
                two(cx,i,i+size-rows)
                # two(cx,i,i+size+rows)
            elseif mod(i,rows) == 0
                two(cx,i,i+size-1)
                # two(cx,i,i+size+1)
                two(cx,i,i+size-rows)
                # two(cx,i,i+size+rows)
            else
                two(cx,i,i+size-1)
                two(cx,i,i+size+1)
                two(cx,i,i+size-rows)
                # two(cx,i,i+size+rows)
            end
        else
            if mod(i,rows) == 1
                # two(cx,i,i+size-1)
                two(cx,i,i+size+1)
                two(cx,i,i+size-rows)
                two(cx,i,i+size+rows)
            elseif mod(i,rows) == 0
                if fld(i,rows) ==1
                    two(cx,i,i+size-1)
                    # two(cx,i,i+size+1)
                    # two(cx,i,i+size-rows)
                    two(cx,i,i+size+rows)
                elseif fld(i,rows) == rows
                    two(cx,i,i+size-1)
                    # two(cx,i,i+size+1)
                    two(cx,i,i+size-rows)
                    # two(cx,i,i+size+rows)
                else
                    two(cx,i,i+size-1)
                    # two(cx,i,i+size+1)
                    two(cx,i,i+size-rows)
                    two(cx,i,i+size+rows)
                end
            else
                two(cx,i,i+size-1)
                two(cx,i,i+size+1)
                two(cx,i,i+size-rows)
                two(cx,i,i+size+rows)
            end
        end
    end

    for i in 1:size
        one(x,i+size)
    end
    for i in 1:size
        two(cx,i+size, i+size+1)
    end
    for i in reverse(1:size-1)
        two(cx,i+size, i+size+1)
    end
    for i in 1:size
        one(x,i+size)
    end


    for i in 1:size
        two(cx,i,i+size)
        if fld(i,rows) == 0
            if mod(i,rows) == 1
                # two(cx,i,i+size-1)
                two(cx,i,i+size+1)
                # two(cx,i,i+size-rows)
                two(cx,i,i+size+rows)
            elseif mod(i,rows) == 0
                two(cx,i,i+size-1)
                # two(cx,i,i+size+1)
                # two(cx,i,i+size-rows)
                two(cx,i,i+size+rows)
            else
                two(cx,i,i+size-1)
                two(cx,i,i+size+1)
                # two(cx,i,i+size-rows)
                two(cx,i,i+size+rows)
            end
        elseif fld(i,rows) == rows-1
            if mod(i,rows) == 1
                # two(cx,i,i+size-1)
                two(cx,i,i+size+1)
                two(cx,i,i+size-rows)
                # two(cx,i,i+size+rows)
            elseif mod(i,rows) == 0
                two(cx,i,i+size-1)
                # two(cx,i,i+size+1)
                two(cx,i,i+size-rows)
                # two(cx,i,i+size+rows)
            else
                two(cx,i,i+size-1)
                two(cx,i,i+size+1)
                two(cx,i,i+size-rows)
                # two(cx,i,i+size+rows)
            end
        else
            if mod(i,rows) == 1
                # two(cx,i,i+size-1)
                two(cx,i,i+size+1)
                two(cx,i,i+size-rows)
                two(cx,i,i+size+rows)
            elseif mod(i,rows) == 0
                if fld(i,rows) ==1
                    two(cx,i,i+size-1)
                    # two(cx,i,i+size+1)
                    # two(cx,i,i+size-rows)
                    two(cx,i,i+size+rows)
                elseif fld(i,rows) == rows
                    two(cx,i,i+size-1)
                    # two(cx,i,i+size+1)
                    two(cx,i,i+size-rows)
                    # two(cx,i,i+size+rows)
                else
                    two(cx,i,i+size-1)
                    # two(cx,i,i+size+1)
                    two(cx,i,i+size-rows)
                    two(cx,i,i+size+rows)
                end
            else
                two(cx,i,i+size-1)
                two(cx,i,i+size+1)
                two(cx,i,i+size-rows)
                two(cx,i,i+size+rows)
            end
        end
    end

    # Diffuser
    for i in 1:size
        one(h,i)
        one(x,i)
    end
    one(h,size)
    for i in 1:size
        two(cx,i+size, i+size+1)
    end
    for i in reverse(1:size-1)
        two(cx,i+size, i+size+1)
    end
    one(h,size)
    for i in 1:size
        one(h,i)
        one(x,i)
    end
end
for i in 1:size
    one(m, i)
end
"""
Grover end
"""

"""
QAOA start
"""
# name = "qaoa-180"
# noQubits = 180
# circuit = initCircuit(noQubits)
# function buildQAOA()
#     num = noQubits
#     weights = 0.1
#     p = 1
#     beta = [0.4]
#     gamma = [0.4]
    
#     # Init Quantum Circuit
#     # qc = QuantumCircuit(num)
    
#     # Mixer Ground State
#     for i in 1:noQubits
#         one(h,i)
#     end
#     # Evolving
#     for i in 1:p
#         costFunction()
#         mixerHamiltonian()
#     end

#     for i in 1:noQubits
#         one(m,i)
#     end
#     return
# end

# function mixerHamiltonian()
#     for i in 1:noQubits
#         one(x, i)
#     end
# end

#     # i1, i2 = qubit index
# function costFunctionUnit(i1, i2)
#     one(x,i1)
#     one(x,i2)
#     two(cx,i1,i2)
# end

# function costFunction()
#     for i in 1:noQubits
#         for k in i+1:noQubits
#             costFunctionUnit(i, k)
#         end
#     end
# end

# buildQAOA()
"""
QAOA start
"""

"""
RCS start
"""

"""
RCS start
"""

########################
"""
Output
"""
########################

config = Dict("name"=>name, "number_of_qubits"=>noQubits, "qubits" =>circuit)


output = JSON.json(Dict(name => config))

open("$name.json","w") do f 
    JSON.write(f, output) 
end

