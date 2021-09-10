module SerialCOBS
    using LibSerialPort
    using StaticArrays
    using ProtoBuf

    include("proto_helper.jl")
    include("Arduino.jl")
    include("COBS.jl")

    export Arduino, messageBytesAvailable
    export message, recieve!
    export encode, decode

    function message(ard::Arduino, msg::MSG_TYPE) where {MSG_TYPE <: ProtoBuf.ProtoType}
    # function message(ard::Arduino, msg::AbstractVector{UInt8})
        iob = IOBuffer()
        msg_size = writeproto(iob, msg)
        msg = @view iob.data[1:msg_size]

        encoded_msg = encode(ard, msg)

        status = write(ard, encoded_msg)

        return status
    end

    # function recieve(ard::Arduino{MSG_TYPE}, msg::MSG_TYPE) where {MSG_TYPE <: ProtoBuf.ProtoType}
    function recieve!(ard::Arduino, msg::MSG_TYPE) where {MSG_TYPE <: ProtoBuf.ProtoType}
        encoded_msg = (SerialCOBS.retrieve_encoded_msg(ard))
        if encoded_msg !== nothing
            decoded_msg = decode(ard, encoded_msg)
            readproto(IOBuffer(decoded_msg), msg)

            return true
        end

        return false
    end
end  # module SerialCOBS