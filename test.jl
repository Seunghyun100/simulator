mutable struct test
    tt
    function test(tt::Int64)
        print("gg")
     end
     function test(tt::Float64)
        print("Float")
     end
     function test()::String
        print("Fuk")
     end
end