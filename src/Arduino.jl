failed_to_open_str = "Arduino SerialPort is not connected. Call open(ard::Arduino) first"


arduino_buffer_size = 1020
msg_block_size = 256

mutable struct Arduino # SerialSocket
    portname::String
    baudrate::Int64
    sp::Union{Nothing, SerialPort}

    # Buffer for dumping read bytes into
    read_buffer::MVector{arduino_buffer_size, UInt8}

    # Buffer for encoded messages
    msg_out_buffer::MVector{msg_block_size, UInt8}
    msg_out_length::Int64

    # Buffer for decoded messages
    msg_in_buffer::MVector{msg_block_size, UInt8}
    msg_in_length::Int64

    # ProtoBuf IO stream
    proto_iob::IOBuffer

    function Arduino(portname::String, baudrate::Int)
        sp = nothing

        read_buffer = @MVector zeros(UInt8, arduino_buffer_size)

        msg_out_buffer = @SVector zeros(UInt8, msg_block_size)
        msg_out_length = 0

        msg_in_buffer = @SVector zeros(UInt8, msg_block_size)
        msg_in_length = 0

        proto_iob = IOBuffer(zeros(UInt8, msg_block_size), read=true, write=true,
                            #  maxsize=msg_block_size,
                             append=false
                             )

        return new(portname, baudrate, sp,
                   read_buffer,
                   msg_out_buffer, msg_out_length,
                   msg_in_buffer, msg_in_length,
                   proto_iob)
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

    if bytesavailable(ard) > 2
        return bytesavailable(ard) - 2
    else
        return bytesavailable(ard)
    end
end

# function Base.read!(ard::Arduino, array::AbstractVector{UInt8})
function read_into_buffer!(ard::Arduino)
    isopen(ard) || error(failed_to_open_str)

    if Base.bytesavailable(ard) <= arduino_buffer_size
        bytes_read = Base.bytesavailable(ard)
    else
        bytes_read = Base.bytesavailable(arduino_buffer_size)
    end

    readbytes!(ard.sp, ard.read_buffer, bytes_read)
    return bytes_read
end


function retrieve_encoded_msg(ard::Arduino)
    isopen(ard) || error(failed_to_open_str)

    port_buffered_bytes = Base.bytesavailable(ard)

    if msg_block_size < port_buffered_bytes
        readbytes!(ard.sp, ard.read_buffer, port_buffered_bytes)

        last_msg_last_byte = findfirst(x -> x == 0x00, ard.read_buffer)
        next_msg_last_byte = findnext(x -> x == 0x00, ard.read_buffer, last_msg_last_byte + 1)

        if next_msg_last_byte !== nothing
            encoded_msg = @view ard.read_buffer[last_msg_last_byte+1:next_msg_last_byte]

            return encoded_msg
        end
    end

    return nothing
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
