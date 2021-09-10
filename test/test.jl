using SerialCOBS
using Printf
using Test

# %%
@testset "Encode/Decode Are Inverse Functions" begin
    test_message1 = rand(UInt8, 25)
    ard = Main.SerialCOBS.Arduino("/dev/tty.usbmodem14201", 57600)

    encoded_msg1 = Main.SerialCOBS.encode(ard, test_message1)
    decoded_msg1 = Main.SerialCOBS.decode(ard, encoded_msg1)
    @test decoded_msg == test_message

    # Large message size
    test_message2 = rand(UInt8, 254)
    ard = Main.SerialCOBS.Arduino("/dev/tty.usbmodem14201", 57600)

    encoded_msg2 = Main.SerialCOBS.encode(ard, test_message2)
    decoded_msg2 = Main.SerialCOBS.decode(ard, encoded_msg2)
    @test decoded_msg == test_message
end


# %%
ard = Arduino(portname, holybro_baudrate)

# %%
@testset "Opening/Closing Arduino Port" begin
    @test !isopen(ard)

    open(ard)
    @test isopen(ard)

    close(ard)
    @test !isopen(ard)
end


# %% Check for Strings
@testset "Arduino Echo" begin
    # Send arduino the byte array encoding the string "Test"
    input = Vector{UInt8}("Test")
    output = 0

    open(ard) do sp
        message(ard, input)
        while true
            # Wait for the arudino to echo back with the reversed message
            if bytesavailable(ard) > 0
                output = recieve(ard)
                break
            end
        end
    end
    @test isequal(input, output)

    # Do same test but with different Numeric Types
    input = Vector{Float64}([3., 5., 5.])
    output = 0

    open(ard) do sp
        message(ard, Vector(reinterpret(UInt8, input)))

        while true
            if bytesavailable(ard) > 0
                output = reinterpret(Float64, recieve(ard))
                break
            end
        end
    end
    @test input == output
end