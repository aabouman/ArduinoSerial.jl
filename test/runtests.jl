using SerialCOBS
using Test

# %%
portname = "/dev/tty.usbmodem14201"
holybro_baudrate = 57600

include("$(@__DIR__)/test.jl")