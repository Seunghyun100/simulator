using JSON
using DataFrames
using CSV

input = "bv" # input algorithm name

j = JSON.parsefile("result_$input.json")

circuits = []
for i in keys(j)
    push!(circuits, i)
end
circuits = sort!(circuits)

architectures = ["single-core", "bus", "comb"]

execution_time = Dict{Any,Any}("name"=>["Single Core", "Q-bus", "QCCD"])
noOfShuttling = Dict{Any,Any}("name"=>["Q-bus", "QCCD"])
meanPhonon = Dict{Any,Any}("name"=>["Q-bus", "QCCD"])


for i in 1:length(circuits)
    for a in architectures
        if a == "single-core"
            execution_time["$(i+1)"] = [j[circuits[i]][a]["executionTime"]]
        elseif a[1:3] == "bus"
            push!(execution_time["$(i+1)"], j[circuits[i]]["$(a)$(i+1)"]["executionTime"])
            noOfShuttling["$(i+1)"] = [j[circuits[i]]["$(a)$(i+1)"]["shuttlingCounting"]]
            ph = 0
            for k in keys(j[circuits[i]]["$(a)$(i+1)"]["noOfPhonons"])
                if k[1:3] == "Bus"
                    continue
                end
                ph += j[circuits[i]]["$(a)$(i+1)"]["noOfPhonons"][k]
            end
            ph /= (length(keys(j[circuits[i]]["$(a)$(i+1)"]["noOfPhonons"])) -2)
            meanPhonon["$(i+1)"]  = [ph]
        else
            push!(execution_time["$(i+1)"], j[circuits[i]]["$(a)$(i+1)"]["executionTime"])
            push!(noOfShuttling["$(i+1)"], j[circuits[i]]["$(a)$(i+1)"]["shuttlingCounting"])
            ph = 0
            for k in keys(j[circuits[i]]["$(a)$(i+1)"]["noOfPhonons"])
                ph += j[circuits[i]]["$(a)$(i+1)"]["noOfPhonons"][k]
            end
            ph /= length(keys(j[circuits[i]]["$(a)$(i+1)"]["noOfPhonons"]))
            push!(meanPhonon["$(i+1)"], ph)
        end
    end
end

df_execution_time = DataFrame(execution_time)
df_noOfShuttling = DataFrame(noOfShuttling)
df_meanPhonon = DataFrame(meanPhonon)

CSV.write("$(input)_execution_time.csv", df_execution_time)
CSV.write("$(input)_noOfShuttling.csv", df_noOfShuttling)
CSV.write("$(input)_meanPhonon.csv", df_meanPhonon)