using SerialCOBS
using Printf
using Test

# %%
test_message = rand(UInt8, 25)
ard = Main.SerialCOBS.Arduino("/dev/tty.usbmodem14201", 57600)

encoded_msg = Main.SerialCOBS.encode(ard, test_message)
decoded_msg = Main.SerialCOBS.decode(ard, encoded_msg)

@test decoded_msg == test_message

# %%
HOLYBRO_BAUDRATE = 57600
ard = Arduino("/dev/tty.usbmodem142401", HOLYBRO_BAUDRATE);

# %%
output = 0
open(ard) do sp

    while true
        if bytesavailable(ard) > 0
            global output = recieve(ard)
            @printf("Accel: (%1.3f, %1.3f, %1.3f)\t Gyro: (%1.3f, %1.3f, %1.3f)", Vector(reinterpret(Float64, output))...)
            print("\r")
        end
        sleep(0.1)
    end
end
