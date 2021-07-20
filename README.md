# ArduinoSerial.jl
A simple package to communicate with a Arduino over serial (ie. URART/USB). Uses `LibSerialPort.jl` to communicate and sends messages using Consistent Overhead Byte Stuffing (COBS). Designed to work along side the popular [PacketSerial](https://github.com/bakercp/PacketSerial) library for Arduino.

Contained COBS code is borrowed from yakri12's
[COBS.jl](https://github.com/yakir12/COBS.jl).


## Example
```julia
using ArduinoSerial

# In this example an Arduino is connected to port /dev/tty.usbmodem14201
# communicating at a baudrate of 9600.
ard = Arduino("/dev/tty.usbmodem14201", 9600);

# Connect to Arduino's port, opening a buffer stream
open(ard) do sp
    # Send a message to the open Arduino channel, this is encoded using COBS
    message(ard, Vector{UInt8}("Hey there!"))

    # Wait for Arduino to reply back, after it does exit
    while true
        if bytesavailable(ard) > 0
            display(String(recieve(ard)))
            break
        end
    end
end

```
