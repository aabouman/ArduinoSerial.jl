using LibSerialPort

failed_to_open_str = "Arduino SerialPort is not connected. Call open(ard::Arduino) first"

mutable struct Arduino
    c::ReentrantLock
    portname::String
    baudrate::Int
    sp::Union{Nothing, SerialPort}

    function Arduino(portname::String, baudrate::Int)
        c = ReentrantLock()
        sp = nothing

        return new(c, portname, baudrate, sp)
    end
end


function Base.isopen(ard::Arduino)::Bool
    if ard.sp === nothing
        return false
    end

    return isopen(ard.sp)
end

function Base.close(ard::Arduino)::Nothing
    if ard.sp === nothing
        return
    end
    if isopen(ard)
        close(ard.sp)
    end
end

function Base.open(ard::Arduino)::SerialPort
    close(ard)
    ard.sp = LibSerialPort.open(ard.portname, ard.baudrate)
    return ard.sp
end

##############################################################################
#               READ AND WRITE TO THE ARDUINO SERIALPORT
##############################################################################
function Base.readline(ard::Arduino; keep::Bool=false)
    isopen(ard) || error(failed_to_open_str)

    return readline(ard.sp)
end

function Base.readuntil(ard::Arduino, delim; keep::Bool=false)
    isopen(ard) || error(failed_to_open_str)

    return readuntil(ard.sp, delim; keep=keep)
end

function Base.readbytes!(ard::Arduino, b::AbstractVector{UInt8}, nb=length(b))
    isopen(ard) || error(failed_to_open_str)

    return readbytes!(ard.sp, b, nb)
end

function Base.read!(ard::Arduino, array::AbstractVector{UInt8})
    isopen(ard) || error(failed_to_open_str)

    return read!(ard.sp, array)
end

function Base.write(ard::Arduino, x)
    isopen(ard) || error(failed_to_open_str)

    return write(ard.sp, x)
end

function Base.bytesavailable(ard::Arduino)
    isopen(ard) || error(failed_to_open_str)

    return bytesavailable(ard.sp)
end
