   
    """
    This part is about the configuration functions.
    """
    function configure(configType::String, operation::String, specification::Vector{Any})::Tuple
        config = nothing
        ex = "$operation = $configType("
        for i in specification
            ex = ex * i[2]*','
        end
        ex = ex * ')'
        ex = Meta.parse(ex)
        config = eval(ex)
        return (operation, config)
    end

    function openConfigFile(filePath::String = "")::Dict
        if filePath === "" 
            currentPath = pwd()
            filePath = currentPath * "/test.json"
        end

        configuration = Dict() 

        configJSON = JSON.parsefile(filePath)
        configTypes = keys(configJSON)

        for configType in configTypes
            for operation in configJSON[configType]
                specification = operation[2]
                # println("1: ", configType)
                # println("2: ", operation[1])
                # println("3: ", specification)
                config = configure(configType, operation[1], specification)
                configuration[config[1]] = config[2]
            end
        end
        return configuration
    end