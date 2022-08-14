module CommunicationConfiguration
    import JSON

    mutable struct Shuttling
        type::String
        duration::Float64
        speed::Float64
        heatingRate
        currentCoordinates::Tuple{Int64,Int64}
        nextCoordinates::Tuple{Int64,Int64}
        function Shuttling(type::String, duration::Float64=0.0, speed::Float64=0.0, heatingRate=0.0,currentCoordinates::Tuple{Int64,Int64}=(0,0), nextCoordinates::Tuple{Int64,Int64}=(0,0))
            if type=="linearTransport"
                @assert(speed>0.0, "Speed must be larger than 0.")
            else
                @assert(duration>=0.0, "Duration must be equal or larger than 0.")
            end
            # @assert(currentCoordinates !== (0,0)&&nextCoordinates !== (0,0), "Coordinates must be defined.")
            new(type, duration, speed, heatingRate, currentCoordinates, nextCoordinates)
        end
    end


    """
    This part is about to build the communication operations.
    """

    function generateComponent(communicationName, componentConfig)
        if communicationName =="shuttling"
            if componentConfig["type"] =="linearTransport"
                component = Shuttling(componentConfig["type"], 0.0, componentConfig["speed"], componentConfig["heatingRate"])
            else
                component = Shuttling(componentConfig["type"], componentConfig["duration"], 0.0, componentConfig["heatingRate"])
            end
        elseif communicationName == "pathRow"
            component = componentConfig["pathRow"]
        else
            return
        end
        return component
    end

    function buildCommunication(communicationName, communicationConfig)
        communication = Dict()
        for component in communicationConfig
            componentName = component[1]
            componentConfig = component[2]
            communication[componentName] = generateComponent(communicationName, componentConfig)
        end
        return communication
    end

    function openConfigFile(filePath::String = "")::Dict
        if filePath === "" 
            currentPath = pwd()
            filePath = currentPath * "/input/communication_configuration.json" 
        end

        configJSON = JSON.parsefile(filePath) 

        communications = Dict()
        for communicationConfigPair in configJSON
            communicationName = communicationConfigPair[1]
            communicationConfig = communicationConfigPair[2]
            if communicationName == "protocol"
                communications[communicationName] = Dict()
                for i in communicationConfig
                    communications[communicationName][i[1]] = i[2]
                end
            else
                communications[communicationName] = buildCommunication(communicationName, communicationConfig)
            end
        end
        return communications    
    end

    filePath = "" # Define to communication configuration json file path
    const communicationConfiguration = openConfigFile(filePath)

    # TODO: renovate to fit Q-bus
    function generateCommunicationOperation(operationName::String, currentCoordinates::Tuple{Int64,Int64}, nextCoordinates::Tuple{Int64,Int64})
        dummyOperation = communicationConfiguration["shuttling"][operationName]
        operation = deepcopy(dummyOperation)
        operation.currentCoordinates = currentCoordinates
        operation.nextCoordinates = nextCoordinates
        return operation
    end
end
