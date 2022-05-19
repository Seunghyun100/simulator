module CommunicationConfiguraiton

    struct Shuttling
        type::String
        duration::Float64
        speed::Float64
        heatingRate::Float64
        function Shuttling(type::String, duration::Float64=0.0, speed::Float64=0.0, heatingRate::Float64=0.0)
            if type=="linearTransport"
                @assert(speend>0.0, "Speed must be larger than 0.")
            else
                @assert(duraiton>0.0, "Duration must be larger than 0.")
            end
            new(type, duration, speed, heatingRate)
        end
    end


    """
    This part is about to build the communication operaitons.
    """

    function generateComponent(communicationName, componentConfig)
        if communicationName =="shuttling"
            if componentConfig["type"] =="linearTransport"
                component = Shuttling(componentConfig["type"], 0.0, componentConfig["speed"], componentConfig["heatingRate"])
            else
                component = Shuttling(componentConfig["type"], componentConfig["duration"], componentConfig["heatingRate"])
            end
        end
        if communicationName == "pathRow"
            component = componentConfig["pathRow"]
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
            filePath = currentPath * "/input/communication_configuraiton.json"
        end

        configJSON = JSON.parsefile(filePath) 

        communications = Dict()
        for communicationConfigPair in configJSON
            communicationName = communicationConfigPair[1]
            communicationConfig = communicationConfigPair[2]
            communications[communicationName] = buildcommunication(communicationName, communicationConfig)
        end
        return communications    
    end

end