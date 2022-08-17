using JSON, Plots

currentDirectory = pwd()

QCCD_Grid_results = JSON.parsefile("$currentDirectory/results/QCCD-Grid_results.json")
QCCD_Comb_results = JSON.parsefile("$currentDirectory/results/QCCD-Comb_results.json")

QBUS_results_tmp = JSON.parsefile("$currentDirectory/results/Q-bus_results.json")
QBUS_results = Dict()

for arch in keys(QBUS_results_tmp)
    for i in keys(QBUS_results_tmp[arch])
        QBUS_results["$arch/$i"] = QBUS_results_tmp[arch]["$i"]
    end
end

total_results = Dict()
merge!(total_results,QCCD_Grid_results)
merge!(total_results,QCCD_Comb_results)
merge!(total_results,QBUS_results)

x = [2,3,4,6]

algorithmList = ["bernstein-vazirani-60","quantum-fourier-transformation-60","qaoa-60"]
executionTimeDict = Dict([("bernstein-vazirani-60",Dict()),("quantum-fourier-transformation-60",Dict()),("qaoa-60",Dict())])
noOfShuttlingDict = Dict([("bernstein-vazirani-60",Dict()),("quantum-fourier-transformation-60",Dict()),("qaoa-60",Dict())])
noOfPhononsDict = Dict([("bernstein-vazirani-60",Dict()),("quantum-fourier-transformation-60",Dict()),("qaoa-60",Dict())])

# Execution Time
for arch in keys(total_results)
    executionTimeList = []
    for algorithm in algorithmList
        executionTime = total_results["$arch"]["$algorithm"]["executionTime"]
        push!(executionTimeList,executionTime)
    end
    executionTimeDict["bernstein-vazirani-60"][arch] = executionTimeList[1]
    executionTimeDict["quantum-fourier-transformation-60"][arch] = executionTimeList[2]
    executionTimeDict["qaoa-60"][arch] = executionTimeList[3]
end

# Number of Shuttling
for arch in keys(total_results)
    noOfShuttlingList = []
    for algorithm in algorithmList
        noOfShuttling = total_results["$arch"]["$algorithm"]["shuttlingCounting"]
        push!(noOfShuttlingList,noOfShuttling)
    end
    noOfShuttlingDict["bernstein-vazirani-60"][arch] = noOfShuttlingList[1]
    noOfShuttlingDict["quantum-fourier-transformation-60"][arch] = noOfShuttlingList[2]
    noOfShuttlingDict["qaoa-60"][arch] = noOfShuttlingList[3]
end

# Number of Phonons
for arch in keys(total_results)
    noOfPhononsList = []
    for algorithm in algorithmList
        noOfPhononsEachCore = total_results["$arch"]["$algorithm"]["noOfPhonons"]
        noOfPhonons = 0.0
        for ph in values(noOfPhononsEachCore)
            noOfPhonons += ph
        end
        noOfPhonons = noOfPhonons/6

        push!(noOfPhononsList,noOfPhonons)
    end
    noOfPhononsDict["bernstein-vazirani-60"][arch] = noOfPhononsList[1]
    noOfPhononsDict["quantum-fourier-transformation-60"][arch] = noOfPhononsList[2]
    noOfPhononsDict["qaoa-60"][arch] = noOfPhononsList[3]
end

archs = ["Q-bus/1","Q-bus/2","Q-bus/3","Q-bus/4","QCCD-Grid","QCCD-Comb"]
output = Dict([("Q-bus/1",Dict()),("Q-bus/2",Dict()),("Q-bus/3",Dict()),("Q-bus/4",Dict()),("QCCD-Grid",Dict()),("QCCD-Comb",Dict())])

final_results = Dict()

# Option of Dictionary
resultDictionary = noOfShuttlingDict #####################################

for al in algorithmList
    for i in keys(resultDictionary[al])
        # push!(archs, i)
        # push!(y_tmp, round(executionTimeDict[al][i]))
        if occursin("Q-bus", i)
            if occursin("/1",i)
                if occursin("30",i)
                    output["Q-bus/1"][2] = resultDictionary[al][i]
                elseif occursin("20",i)
                    output["Q-bus/1"][3] = resultDictionary[al][i]
                elseif occursin("15",i)
                    output["Q-bus/1"][4] = resultDictionary[al][i]
                elseif occursin("10",i)
                    output["Q-bus/1"][6] = resultDictionary[al][i]
                end
            elseif occursin("/2",i)
                if occursin("30",i)
                    output["Q-bus/2"][2] = resultDictionary[al][i]
                elseif occursin("20",i)
                    output["Q-bus/2"][3] = resultDictionary[al][i]
                elseif occursin("15",i)
                    output["Q-bus/2"][4] = resultDictionary[al][i]
                elseif occursin("10",i)
                    output["Q-bus/2"][6] = resultDictionary[al][i]
                end
            elseif occursin("/3",i)
                if occursin("30",i)
                    output["Q-bus/3"][2] = resultDictionary[al][i]
                elseif occursin("20",i)
                    output["Q-bus/3"][3] = resultDictionary[al][i]
                elseif occursin("15",i)
                    output["Q-bus/3"][4] = resultDictionary[al][i]
                elseif occursin("10",i)
                    output["Q-bus/3"][6] = resultDictionary[al][i]
                end
            elseif occursin("/4",i)
                if occursin("30",i)
                    output["Q-bus/4"][2] = resultDictionary[al][i]
                elseif occursin("20",i)
                    output["Q-bus/4"][3] = resultDictionary[al][i]
                elseif occursin("15",i)
                    output["Q-bus/4"][4] = resultDictionary[al][i]
                elseif occursin("10",i)
                    output["Q-bus/4"][6] = resultDictionary[al][i]
                end
            end
        elseif occursin("QCCD-Grid", i)
            if occursin("30",i)
                output["QCCD-Grid"][2] = resultDictionary[al][i]
            elseif occursin("20",i)
                output["QCCD-Grid"][3] = resultDictionary[al][i]
            elseif occursin("15",i)
                output["QCCD-Grid"][4] = resultDictionary[al][i]
            elseif occursin("10",i)
                output["QCCD-Grid"][6] = resultDictionary[al][i]
            end
        elseif occursin("QCCD-Comb", i)
            if occursin("30",i)
                output["QCCD-Comb"][2] = resultDictionary[al][i]
            elseif occursin("20",i)
                output["QCCD-Comb"][3] = resultDictionary[al][i]
            elseif occursin("15",i)
                output["QCCD-Comb"][4] = resultDictionary[al][i]
            elseif occursin("10",i)
                output["QCCD-Comb"][6] = resultDictionary[al][i]
            end
        end
    end

    y_tmp = []
    for a in archs
        for q in x
            push!(y_tmp,output[a][q])
        end
    end
    y_tmp = convert(Array{Float64,1},y_tmp)
    y = reshape(y_tmp, 4, 6)
    final_results[al] = y
end


algorithmList = ["bernstein-vazirani-60","quantum-fourier-transformation-60","qaoa-60"]
ex = algorithmList[1]
y = final_results[ex] #####################################
archs = reshape(archs, 1, 6)

println(y)
println(archs)
plot(x,y, yaxis=:log, title = "Number of Shuttling for BV", label=archs, legend=:topright) #####################################
savefig("Shuttling_BV.png") #####################################