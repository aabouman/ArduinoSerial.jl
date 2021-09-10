"""
Helper function fills a newly initalized protobuf message with zeros
"""
function fill_protobuf!(msg::MSG_TYPE) where {MSG_TYPE <: ProtoBuf.ProtoType}
    names_list = propertynames(msg)
    attr_dict = msg.__protobuf_jl_internal_meta.symdict

    for name in names_list
        # Verify we can generate a random message
        @assert attr_dict[name].jtyp <: Real
        setproperty!(msg, name, zero(attr_dict[name].jtyp))
    end
end

"""
Helper function gets the size of an initalized protobuf message
"""
function get_msg_size(msg::MSG_TYPE) where {MSG_TYPE <: ProtoBuf.ProtoType}
    if isinitialized(msg)
        return writeproto(IOBuffer(), msg)
    else
        error("Must initialize the protobuf message.")
    end
end

