module CommunicationConfiguration
    export communicationChannel, communicationQubit

    abstract type CommunicationChannel end
    abstract type ShuttlingPath <:CommunicationChannel end
    abstract type LinearPath <:ShuttlingPath end
    abstract type Junction <:ShuttlingPath end
    abstract type Edge <:ShuttlingPath end

    # Add abstract type (i.e., shuttlingPath)
    function addType(type::String, supreType::String)
        if supreType
            abstract type $type <:supreType end
        else
            abstract type $type end
        end
    end

    struct communicationQubit
    end

    mutable struct communicationChannel
        type <:CommunicationChannel
        duration::Float64 # duration of communication
        heatingRate::Float64 # heating rate by shuttling
        id::Int64
        connectivity::Array{communicationChannel,1} # connectivity between channels
        dwellTime::Float64 # dwell time to avoid deadlock
    end
end

module HardwareConfiguration
    using communicationConfiguration
    
    struct actualQubit
        id::Int64
        intraConnectivity::Array{::Int64,1}
        state
        isCommunicationQubit::Bool
    end

    mutable struct core
        id::Int64
        capacity::Int64
        phononNumber::Float64
        interConnectivity::Array{::communicationChannel,1}
    end

    struct hardware
        cores::Array{::core}
    end

end

