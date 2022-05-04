module HardwareConfiguration

import ..CircuitConfiguration

abstract type Hardware end
abstract type Communication end
abstract type Circuit end

abstract type Operation <: Circuit end
abstract type CircuitQubit <: Circuit end

abstract type ActualQubit <: Hardware end
abstract type Core <: Hardware end

abstract type CommunicationQubit <: Communication end
abstract type CommunicationChannel <: Communication end
abstract type CommunicationOperation <: Communication end

abstract type Path <: CommunicationChannel end
abstract type Junction <: CommunicationChannel end
abstract type Edge <: CommunicationChannel end

abstract type Shuttling <:CommunicationOperation end
abstract type JunctionRotating <:CommunicationOperation end
abstract type Split <:CommunicationOperation end
abstract type Merge <:CommunicationOperation end


"""
This part is about the hardware configuration.
"""

mutable struct actualQubit <: ActualQubit
    id::Int64
    intraConnectivity::Array{ActualQubit}
    runningOperations::Array{Operation, CommunicationOperation} # running oepration list
    error::Float64
    executionTime::Float64
    circuitQubit::CircuitQubit
    communicationQubit::CommunicationQubit
    isCommunicationQubit::Bool
end

mutable struct core <: Core
    id::Int64
    capacity::Int64
    noOfQubits::Int64
    qubits::Array{ActualQubit}
    noOfPhonons::Float64
    interConnectivity::Array{Core}
end

struct hardware <: Hardware
    noOfCores::Int64
    totalTime::Float64
    cores::Array{Core}
end


"""
This part is about the communication configuration.
"""

mutable struct communicationQubit <:CommunicationQubit
    interConnectivity::Array{Core}
    communicationTime::Float64
    noOfPhonons::Float64
    dwellTime::Float64
    inChannel::CommunicationChannel
    isCommunicating::Bool
end

mutable struct path <:Path
    id::Int64
    isOccupide::Bool
    length::Float64 # length of shuttling path to calculate shuttling duration
    connectedChannel::Tuple{Junction, Edge}
end

mutable struct junction <:Junction
    id::Int64
    isOccupide::Bool
    noOfPath::Int64
    connectedChannel::Tuple{Path}
end

mutable struct edge <:Edge
    id::Int64
    isOccupide::Bool
    connectedChannel::Path
    connectedCore::Core
end

struct shuttling <:Shuttling
    speed::Float64 # To calculate shuttling time of path
    heatingRate::Float64
end

struct junctionRotating <:JunctionRotating
    duration::Float64
    heatingRate::Float64
    toPath::Path
end

struct split <:Split
    duration::Float64
    heatingRate::Tuple{Float64} # (Core, CommQubit)
end

struct merge <:Merge
    duration::Float64
    heatingRate::Float64
end
end