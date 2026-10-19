#!/bin/bash
# Builds and runs the whole project: C++ reference model, then the Verilog simulation

# Stop at the first command that fails
set -e

echo "1. C++ reference model..."
g++ -std=c++11 -o reference_model reference_model.cpp

echo "2. Random test matrices and correct answers..."
./reference_model "$@"

echo "3. Verilog simulation..."
iverilog -o sim pe.v delay_line.v systolic_array_4x4.v \
    tb_systolic_array_4x4.v

echo "4. Running the simulation..."
vvp sim
