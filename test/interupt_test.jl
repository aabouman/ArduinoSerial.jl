using ArduinoSerial
using Printf

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
