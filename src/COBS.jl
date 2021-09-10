empty_message_str = "Empty message passed to encode!"
big_message_str = "Can only safely encode 254 bytes at a time"


"""
    encode(ard::Arduino, payload::Vector{UInt8})
Zero Allocation encoding of a message block
"""
function encode(ard::Arduino, payload::AbstractVector{UInt8})
    length(payload) == 0 && error("empty_message_str")
    length(payload) > 254 && error("big_message_str")

    n = length(payload)
    ard.msg_out_length = n + 2

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
    length(payload) == 0 && error("empty_message_str")
    length(msg) > 256 && error(big_message_str)

    push_ind = 1
    ard.msg_in_buffer

    pop_ind = 1
    n = msg[pop_ind]
    pop_ind += 1

    c = 0

    b = msg[pop_ind]
    pop_ind += 1

    while b ≠ 0x00
        c += 1
        if c < n
            ard.msg_in_buffer[push_ind] = b
            push_ind += 1
        else
            ard.msg_in_buffer[push_ind] = 0x00
            push_ind += 1

            n = b
            c = 0
        end

        b = msg[pop_ind]
        pop_ind += 1
    end

    ard.msg_in_length = push_ind - 1

    return view(ard.msg_in_buffer, 1:ard.msg_in_length)
end

