module SerialCOBS
    using LibSerialPort
    using StaticArrays

    include("Arduino.jl")
    include("COBS.jl")

    export Arduino, bytesavailable
    export message, recieve
    export encode, decode

    function message(ard::Arduino, msg::AbstractVector{UInt8})
        encoded_msg = encode(ard, msg)
        status = write(ard, encoded_msg)

        return status
    end

    function recieve(ard::Arduino)::Vector{UInt8}
        encoded_msg = readuntil(ard, UInt8(0))
        decoded_msg = decode(ard, encoded_msg)

        return decoded_msg
    end
end  # module SerialCOBS