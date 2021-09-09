using LibSerialPort
using StaticArrays

failed_to_open_str = "Arduino SerialPort is not connected. Call open(ard::Arduino) first"


mutable struct Arduino # SerialSocket
    portname::String
    baudrate::Int
    sp::Union{Nothing, SerialPort}
    # Buffer for dumping read bytes into
    read_buffer::MVector{256, UInt8}

    # Buffer for encoded messages
    msg_out_buffer::MVector{256, UInt8}
    msg_out_length::Int64

    # Buffer for decoded messages
    msg_in_buffer::MVector{256, UInt8}
    msg_in_length::Int64

    function Arduino(portname::String, baudrate::Int)
        sp = nothing
        read_buffer = @SVector zeros(UInt8, 256)

        msg_out_buffer = @SVector zeros(UInt8, 256)
        msg_out_length = 0

        msg_in_buffer = @SVector zeros(UInt8, 256)
        msg_in_length = 0
        return new(portname, baudrate, sp, read_buffer,
                   msg_out_buffer, msg_out_length,
                   msg_in_buffer, msg_in_length)
    end
end

####################################################################
#                        Serial port I/O
####################################################################
function Base.isopen(ard::Arduino)::Bool
    if ard.sp === nothing
        return false
    end

    return isopen(ard.sp)
end

function Base.open(ard::Arduino)::SerialPort
    close(ard)
    ard.sp = LibSerialPort.open(ard.portname, ard.baudrate)
    return ard.sp
end

function Base.close(ard::Arduino)::Nothing
    if ard.sp === nothing
        return
    end
    if isopen(ard)
        close(ard.sp)
    end
end

function Base.bytesavailable(ard::Arduino)
    isopen(ard) || error(failed_to_open_str)

    return bytesavailable(ard.sp)
end

# function Base.read!(ard::Arduino, array::AbstractVector{UInt8})
function Base.read_into_buffer!(ard::Arduino)
    isopen(ard) || error(failed_to_open_str)

    # if Base.bytesavailable(ard) <= 256
        return read!(ard.sp, ard.read_buffer)
    # end
end

function Base.readuntil(ard::Arduino, delim)
    read_into_buffer!(ard)
    last_ind = findfirst(x -> x==delim, ard.read_buffer)

    if istype(last_ind, Int64)
        return view(ard.read_buffer, 1:last_ind)
    else
        return ard.read_buffer
    end
end

function Base.write(ard::Arduino, x)
    isopen(ard) || error(failed_to_open_str)

    return write(ard.sp, x)
end

"""
    encode(ard::Arduino, payload::Vector{UInt8})
Zero Allocation encoding of a message block
"""
function encode(ard::Arduino, payload::AbstractVector{UInt8})
    length(payload) == 0 && error("Empty message passed to encode!")
    length(payload) > 254 && error("Can only safely encode 254 bytes at a time")

    n = length(payload)
    ard.msg_out_length = n + 2
    # Clear out portion of memory buffer to be used, useful for debuging
    # for i in 1:ard.msg_out_length
    #     ard.msg_buffer[i] = undef
    # end

    ind = 0x01
    acc = 0x01
    for x in Iterators.reverse(payload)
        if iszero(x)
            ard.msg_out_buffer[ind] = acc
            acc = 0x00
        else
            ard.msg_out_buffer[ind] = x
        end

        ind += 0x01
        acc += 0x01
    end
    ard.msg_out_buffer[ard.msg_out_length-1] = acc

    # Reverse the msg_buffer
    reverse!(ard.msg_out_buffer, 1, ard.msg_out_length-1)
    # Add on end flag to message
    ard.msg_out_buffer[ard.msg_out_length] = 0x00
    # Return a view into the msg buffer of just critical part of the buffer
    return view(ard.msg_out_buffer, 1:ard.msg_out_length)
end



"""
    decode(msg)
Zero allocation decoding of message block.
"""
function decode(ard::Arduino, msg::AbstractVector{UInt8})
    length(msg) > 256 && error("Can only safely decode 254 bytes at a time")

    push_ind = 1
    ard.msg_in_buffer
    # pl = UInt8[]

    pop_ind = 1
    n = msg[pop_ind]
    pop_ind += 1
    # n = popfirst!(msg)

    c = 0

    b = msg[pop_ind]
    pop_ind += 1
    # b = popfirst!(msg)

    while b ≠ 0x00
        c += 1
        if c < n
            ard.msg_in_buffer[push_ind] = b
            push_ind += 1
            # push!(pl, b)
        else
            ard.msg_in_buffer[push_ind] = 0x00
            push_ind += 1

            # push!(pl, 0)

            n = b
            c = 0
        end

        b = msg[pop_ind]
        pop_ind += 1
        # b = popfirst!(msg)
    end

    ard.msg_in_length = push_ind - 1

    return view(ard.msg_in_buffer, 1:ard.msg_in_length)
end