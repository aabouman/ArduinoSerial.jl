using ArduinoSerial
using Test

# %%  Verify the
a = rand(UInt8, 6)
@test decode(encode(a)) == a

# %%
ard = Arduino("/dev/tty.usbmodem14201", 9600);

# %%
@testset "Opening/Closing Port" begin
    @test !isopen(ard)

    open(ard)
    @test isopen(ard)

    close(ard)
    @test !isopen(ard)
end

# %% Check for Strings
@testset "Arduino Echo" begin
    input = "Test"
    output = 0
    try
        open(ard) do sp
            message(ard, Vector{UInt8}(input))

            while true
                if bytesavailable(ard) > 0
                    output = String(recieve(ard))
                    break
                end
            end
        end
        @test input == output

    # Check for Different Numeric Types
    input = Vector{Float64}([3., 5., 5.])
    output = 0

    open(ard) do sp
        message(ard, Vector(reinterpret(UInt8, input)))

        while true
            if bytesavailable(ard) > 0
                output = Vector(reinterpret(Float64, recieve(ard)))
                break
            end
        end
    end
    @test input == output

    catch
        error("Is Arduino running Echo.ino script?")
    end
end
