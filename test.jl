import JSON

currentPath = pwd()
filePath = currentPath * "/test.json"

configJSON = JSON.parsefile(filePath) 

println(typeof(configJSON))
print(configJSON)
