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
function Base.close(ard::Arduino)::Nothing
    if ard.sp === nothing
        return
    end
    if isopen(ard)
        close(ard.sp)
    end
end

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


function Base.bytesavailable(ard::Arduino)
    isopen(ard) || error(failed_to_open_str)

    return bytesavailable(ard.sp)
end

function messageBytesAvailable(ard::Arduino)
    isopen(ard) || error(failed_to_open_str)

    return bytesavailable(ard) - 2
end

# function Base.read!(ard::Arduino, array::AbstractVector{UInt8})
function read_into_buffer!(ard::Arduino)
    isopen(ard) || error(failed_to_open_str)

    # if Base.bytesavailable(ard) <= 256
        return read!(ard.sp, ard.read_buffer)
    # end
end

function Base.readuntil(ard::Arduino, delim)
    read_into_buffer!(ard)
    last_ind = findfirst(x -> x==delim, ard.read_buffer)

    if last_ind isa Int64
        return view(ard.read_buffer, 1:last_ind)
    else
        return ard.read_buffer
    end
end

function Base.write(ard::Arduino, x)
    isopen(ard) || error(failed_to_open_str)

    return write(ard.sp, x)
end
