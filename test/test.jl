using Revise
using SerialCOBS
using ProtoBuf
using Printf
using Test
using BenchmarkTools

include("$(@__DIR__)/msgs/imu_msg_pb.jl")
imu = IMU(acc_x=0., acc_y=0., acc_z=0.,
          gyr_x=0., gyr_y=0., gyr_z=0.,
          time=time())
in_vicon = VICON(pos_x=0., pos_y=0., pos_z=0.,
                 quat_w=0., quat_x=0., quat_y=0., quat_z=0.,
                 time=time())
imu_vicon = IMU_VICON(imu=imu, vicon=in_vicon)

ard = Arduino("/dev/tty.usbmodem92225501", 57600);

out_vicon = VICON(pos_x=0., pos_y=0., pos_z=0.,
                  quat_w=0., quat_x=0., quat_y=0., quat_z=0.,
                  time=time())
holybro = Arduino("/dev/tty.usbmodem14201", 57600);


# %% Benchmark recieve
open(ard)
results = @benchmark recieve!($ard, $imu_vicon)
close(ard)
display(results)


# %% Benchmark message
open(holybro)

# %%
message(holybro, out_vicon)

# %%
try
    for i in 1:1000
        message(holybro, out_vicon)
        sleep(0.0001)
    end
catch
    close(holybro)
end

# %%

open(holybro) do sp
    message(ard, out_vicon)
end
# close(holybro)

# %%
decoded_msg = 0
encoded_msg = 0
cnt = 0

open(ard)
    start_time = time()
# results = @benchmark begin
    for i in 1:100000
        encoded_msg = SerialCOBS.retrieve_encoded_msg(ard)
        if encoded_msg !== nothing
            decoded_msg = decode(ard, encoded_msg)
            readproto(IOBuffer(decoded_msg), imu_vicon)

            cnt += 1
            # @printf("IMU accel: \t[%1.3f, %1.3f, %1.3f]\n",
            #         imu_vicon.imu.acc_x, imu_vicon.imu.acc_y, imu_vicon.imu.acc_z)
            # @printf("Vicon pos: \t[%1.3f, %1.3f, %1.3f]\n",
            #         imu_vicon.vicon.pos_x, imu_vicon.vicon.pos_x, imu_vicon.vicon.pos_x)
        end
    end
end_time = time()

# end
close(ard)

println(cnt/(end_time - start_time))

# display(results)



# %% Begin Testing here
@testset "Encode/Decode Are Inverse Functions" begin
    test_message1 = rand(UInt8, 25)
    ard = Main.SerialCOBS.Arduino("/dev/tty.usbmodem14201", 57600)

    encoded_msg1 = Main.SerialCOBS.encode(ard, test_message1)
    decoded_msg1 = Main.SerialCOBS.decode(ard, encoded_msg1)
    @test decoded_msg1 == test_message1

    # Large message size
    test_message2 = rand(UInt8, 254)
    ard = Main.SerialCOBS.Arduino("/dev/tty.usbmodem14201", 57600)

    encoded_msg2 = Main.SerialCOBS.encode(ard, test_message2)
    decoded_msg2 = Main.SerialCOBS.decode(ard, encoded_msg2)
    @test decoded_msg2 == test_message2
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
        for i in 1:1000
            # Wait for the arudino to echo back with the reversed message
            if bytesavailable(ard) > 0
                output = recieve(ard)
                break
            end
            sleep(0.01)
            i == 1000 ? error("Is arduino running PacketSerialEcho.ino connected to port $(ard.portname)?") : nothing
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