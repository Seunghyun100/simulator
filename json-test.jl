import JSON

# JSON.parse - string or stream to Julia data structures
s = "{\"a_number\" : 5.0, \"an_array\" : [\"string\", 9]}"
j = JSON.parse(s)
#  Dict{AbstractString,Any} with 2 entries:
#    "an_array" => {"string",9}
#    "a_number" => 5.0

# JSON.json - Julia data structures to a string
JSON.json([2,3])
#  "[2,3]"
JSON.json(j)
#  "{\"an_array\":[\"string\",9],\"a_number\":5.0}"

conf = Dict("x"=>(("name","x"),("duration",40.0),),"y"=>(("name","y"),("duration",40.0),))


name::String
duration::Float64
fidelity::Fidelity