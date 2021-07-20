# Module for Consistent Overhead Byte Stuffing (COBS)
#   See:    https://github.com/yakir12/COBS.jl
#           https://pythonhosted.org/cobs/intro.html

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
function encode(payload::Vector{UInt8})
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
