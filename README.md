# Systolic-Array-for-4x4-Matrices
4×4 Output-Stationary Systolic Array Matrix Multiplier

A 4×4 systolic array that multiplies two 4×4 matrices. Written in Verilog and verified using a C++ reference model with a testbench.

Patrick Kraft · University of Michigan · jpkraft@umich.edu

What is a systolic array?

A systolic array is a grid of simple processing elements (PEs) that pass data to their neighbors every clock tick, like a heartbeat. Matrix multiplication fits this well because every output entry is a running sum of products, and each input value gets reused across a whole row or column.

In this project each PE keeps the running total for the designated entry in the result matrix:

Values of A go from left to right across each row.
Values of B go from top to bottom down each column.
For every tick, each PE multiplies the two values it receives then adds the product to its own accumulator and passes both values on to its neighbors.

Delay lines skew the inputs so the matching A and B values reach each PE on the same tick.

Design
1. pe.v:	One processing element that multiplies and accumulate the variables and pass them on
2. delay_line.v: Delays a signal by N ticks to skew the inputs so that some PE aren't left behind.
3. systolic_array_4x4.v:	Creates: 16 PEs, 8 delay lines, and a small controller that raises done
4. tb_systolic_array_4x4.v:	Testbench
5. reference_model.cpp:	C++ model that generates random test matrices and their correct answers
6. run.sh:	Builds and runs everything

Parameters: 8-bit unsigned inputs, 32-bit accumulators, 4×4 array.


How to run

Requires Icarus Verilog and g++.

bash
bash run.sh          # default seed
bash run.sh 42       # or choose a random seed

The simulation also writes systolic.vcd, which you can open in GTKWave to view the waveforms.

Limitations and next steps
8-bit inputs only
Fixed 4×4 size, though the sizes are parameters in the code
It's one multiplication at a time; back to back multiplications aren't overlapped
Possible extensions: wider data types, larger arrays
