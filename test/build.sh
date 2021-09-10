#!/bin/bash

NANOPB_PLUGIN="Arduino/libraries/nanopb/generator/protoc-gen-nanopb"
JL_PLUGIN="$HOME/.julia/packages/ProtoBuf/TYEdo/plugin/protoc-gen-julia"
JL_BUILD_DIR="msgs"
INO_BUILD_DIR="Arduino/libraries/msgs"

# VICON MESSAGE
SRC_DIR="proto"
MSG_NAME="imu_msg.proto"
protoc -I=. --plugin=$NANOPB_PLUGIN --proto_path=$SRC_DIR --nanopb_out=$INO_BUILD_DIR  $MSG_NAME
protoc -I=. --plugin=$JL_PLUGIN     --proto_path=$SRC_DIR --julia_out=$JL_BUILD_DIR    $MSG_NAME