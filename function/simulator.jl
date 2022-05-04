module Scheduler
end

module CostCalculator
    import ..Scheduler
end

module ErrorCalculator
end

module Simulator
    import ..CostCalculator
    import ..ErrorCalculator
end