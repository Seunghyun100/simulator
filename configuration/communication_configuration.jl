module CommunicationConfiguraiton
    struct LinearTransport <: Shuttling
        speed::Float64 # To calculate shuttling time of path
        heatingRate::Float64
        function LinearTransport(speed::Float64, heatingRate::Float64=0.0)
            @assert(speend>0.0, "Speed must be larger than 0.")
            new(speed, heatingRate)
        end
    end

    struct JunctionRotate <: Shuttling
        duration::Float64
        heatingRate::Float64
        toPath::Path
        function JunctionRotate(duration::Float64, heatingRate::Float64=0.0, toPath::Path=nothing)
            @assert(duraiton>0.0, "Duration must be larger than 0.")
            new(duration, heatingRate, toPath)
        end
    end

    struct Split <: Shuttling
        duration::Float64
        heatingRate::Tuple{Float64, Float64} # (Core, CommQubit)
        function Split(duration::Float64, heatingRate::Tuple{Float64, Float64}=(0.0, 0.0))
            @assert(duraiton>0.0, "Duration must be larger than 0.")
            new(duration, heatingRate)
        end
    end

    struct Merge <: Shuttling
        duration::Float64
        heatingRate::Float64
        function Merge(duration::Float64, heatingRate::Float64=0.0)
            @assert(duraiton>0.0, "Duration must be larger than 0.")
            new(duration, heatingRate)
    end
end
