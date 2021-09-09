# Module for Consistent Overhead Byte Stuffing (COBS)
#   See:    https://github.com/yakir12/COBS.jl
#           https://pythonhosted.org/cobs/intro.html


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



function _encode_block(xs)
    length(xs) == 0 && error("Empty message passed to encode!")
    length(xs) > 254 && error("Can only safely encode 254 bytes at a time")

    n = length(xs)
    ys = Vector{UInt8}(undef, n + 1)
    ind = 0x01
    acc = 0x01
    for x in reverse(xs)
        if iszero(x)
            ys[ind] = acc
            acc = 0x00
        else
            ys[ind] = x
        end
        ind += 0x01
        acc += 0x01
    end
    ys[end] = acc
    return reverse(ys)
end


"""
    encode(payload)
Return the encoded `payload`.
"""
function encode(payload::AbstractVector{UInt8})
    length(payload) == 0 && error("Empty message passed to encode!")
    length(payload) > 254 && error("Can only safely encode 254 bytes at a time")

    blocks = Vector{Vector{UInt8}}()
    for xs in Base.Iterators.partition(payload, 254)
        block = _encode_block(xs)
        push!(blocks, block)
    end

    return vcat(blocks..., 0x00)
end


"""
    decode(msg)

Return the decoded `msg`.
"""
function decode(_msg::AbstractVector)
    msg = copy(_msg)
    pl = UInt8[]
    n = popfirst!(msg)
    c = 0
    b = popfirst!(msg)
    while b ≠ 0
        c += 1
        if c < n
            push!(pl, b)
        else
            push!(pl, 0)
            n = b
            c = 0
        end
        b = popfirst!(msg)
    end

    return pl
end
