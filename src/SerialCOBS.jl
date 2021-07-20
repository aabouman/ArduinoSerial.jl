module SerialCOBS

    include("Arduino.jl")
    include("COBS.jl")

    export Arduino, bytesavailable
    export message, recieve
    export encode, decode

    function message(ard::Arduino, msg::Vector{UInt8})
        isopen(ard) || error(failed_to_open_str)

        encoded_msg = encode(msg)
        return write(ard, encoded_msg)
    end


    function recieve(ard::Arduino)::Vector{UInt8}
        isopen(ard) || error(failed_to_open_str)

        encoded_msg = readuntil(ard, UInt8(0); keep=true)

        msg = decode(encoded_msg)
        return msg
    end


end  # module ArduinoSerial
