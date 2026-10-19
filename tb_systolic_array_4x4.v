/**
 * tb_systolic_array_4x4.v
 *
 * 4x4 Output-Stationary Systolic Array Matrix Multiplier
 *
 * Patrick Kraft
 * jpkraft@umich.edu
 *
 * Self-checking testbench for systolic_array_4x4. Loads random test
 * matrices and their correct answers from the hex files written by the
 * C++ reference model (reference_model.cpp), feeds each pair of matrices
 * to the circuit, and reports whether every result matches.
 */

`timescale 1ns / 1ps

module tb_systolic_array_4x4;
    localparam ARRAY_SIZE = 4;
    localparam DATA_WIDTH = 8;
    localparam ACC_WIDTH = 32;
    localparam LANE_BUS_WIDTH = ARRAY_SIZE * DATA_WIDTH;
    localparam RESULT_BUS_WIDTH = ARRAY_SIZE * ARRAY_SIZE * ACC_WIDTH;

    // One clock period is 2 * HALF_PERIOD = 10 ns, which is 100 MHz
    localparam HALF_PERIOD = 5;
    localparam RESET_TICKS = 2;

    // Must match NUM_TESTS in reference_model.cpp
    localparam NUM_TESTS = 10;
    localparam ENTRIES_PER_MATRIX = ARRAY_SIZE * ARRAY_SIZE;
    localparam TOTAL_ENTRIES = NUM_TESTS * ENTRIES_PER_MATRIX;

    reg clk = 0;
    reg rst = 1;
    reg start = 0;
    reg in_valid = 0;
    reg [LANE_BUS_WIDTH - 1:0] a_column = 0;
    reg [LANE_BUS_WIDTH - 1:0] b_row = 0;
    wire done;
    wire [RESULT_BUS_WIDTH - 1:0] c_flat;

    // Every test's values, loaded from the reference model's hex files
    reg [DATA_WIDTH - 1:0] a_values [0:TOTAL_ENTRIES - 1];
    reg [DATA_WIDTH - 1:0] b_values [0:TOTAL_ENTRIES - 1];
    reg [ACC_WIDTH - 1:0] expected_values [0:TOTAL_ENTRIES - 1];

    // The matrices for the test that is currently running
    reg [DATA_WIDTH - 1:0] matrix_a [0:ARRAY_SIZE - 1][0:ARRAY_SIZE - 1];
    reg [DATA_WIDTH - 1:0] matrix_b [0:ARRAY_SIZE - 1][0:ARRAY_SIZE - 1];

    reg [ACC_WIDTH - 1:0] expected = 0;
    reg [ACC_WIDTH - 1:0] actual = 0;
    integer i;
    integer j;
    integer k;
    integer test_num;
    integer num_errors = 0;
    integer num_cycles = 0;

    systolic_array_4x4 #(
        .ARRAY_SIZE(ARRAY_SIZE),
        .DATA_WIDTH(DATA_WIDTH),
        .ACC_WIDTH(ACC_WIDTH)
    ) dut(
        .clk(clk),
        .rst(rst),
        .start(start),
        .in_valid(in_valid),
        .a_column(a_column),
        .b_row(b_row),
        .done(done),
        .c_flat(c_flat)
    );

    always #HALF_PERIOD clk = ~clk;

    /**
     * Requires: 0 <= test, 0 <= row < ARRAY_SIZE, 0 <= col < ARRAY_SIZE.
     * Modifies: nothing
     * Effects:  Returns where entry [row][col] of the given test is stored
     *           in a_values, b_values, and expected_values.
     */
    function integer entry_index;
        input integer test;
        input integer row;
        input integer col;
        begin
            entry_index = test * ENTRIES_PER_MATRIX + row * ARRAY_SIZE + col;
        end
    endfunction

    /**
     * Requires: 0 <= row < ARRAY_SIZE and 0 <= col < ARRAY_SIZE.
     * Modifies: nothing
     * Effects:  Returns the circuit's result for C[row][col].
     */
    function [ACC_WIDTH - 1:0] get_result;
        input integer row;
        input integer col;
        begin
            get_result = c_flat[(row * ARRAY_SIZE + col) * ACC_WIDTH
                                +: ACC_WIDTH];
        end
    endfunction

    /**
     * Requires: 0 <= test < NUM_TESTS, and the hex files have been loaded.
     * Modifies: matrix_a, matrix_b
     * Effects:  Copies the matrices for the given test out of a_values and
     *           b_values.
     */
    task load_test;
        input integer test;
        begin
            for (i = 0; i < ARRAY_SIZE; i = i + 1) begin
                for (j = 0; j < ARRAY_SIZE; j = j + 1) begin
                    matrix_a[i][j] = a_values[entry_index(test, i, j)];
                    matrix_b[i][j] = b_values[entry_index(test, i, j)];
                end
            end
        end
    endtask

    /**
     * Requires: rst is low, and matrix_a and matrix_b are filled.
     * Modifies: start, in_valid, a_column, b_row, num_cycles
     * Effects:  Pulses start, then feeds column k of matrix_a and row k of
     *           matrix_b on tick k. Waits until done is high and stores the
     *           number of ticks taken in num_cycles.
     */
    task run_multiply;
        begin
            @(negedge clk);
            start = 1;
            @(negedge clk);
            start = 0;
            num_cycles = 0;

            for (k = 0; k < ARRAY_SIZE; k = k + 1) begin
                in_valid = 1;
                for (i = 0; i < ARRAY_SIZE; i = i + 1) begin
                    a_column[i * DATA_WIDTH +: DATA_WIDTH] = matrix_a[i][k];
                    b_row[i * DATA_WIDTH +: DATA_WIDTH] = matrix_b[k][i];
                end
                @(negedge clk);
                num_cycles = num_cycles + 1;
            end

            in_valid = 0;
            a_column = 0;
            b_row = 0;

            while (!done) begin
                @(negedge clk);
                num_cycles = num_cycles + 1;
            end
        end
    endtask

    /**
     * Requires: run_multiply has just finished for the given test.
     * Modifies: expected, actual, num_errors
     * Effects:  Compares each entry of the circuit's result with the C++
     *           reference model's answer, prints any mismatches, and adds
     *           the number of mismatches to num_errors.
     */
    task check_results;
        input integer test;
        begin
            for (i = 0; i < ARRAY_SIZE; i = i + 1) begin
                for (j = 0; j < ARRAY_SIZE; j = j + 1) begin
                    expected = expected_values[entry_index(test, i, j)];
                    actual = get_result(i, j);
                    if (actual !== expected) begin
                        $display("MISMATCH C[%0d][%0d] = %0d, expected %0d",
                                 i, j, actual, expected);
                        num_errors = num_errors + 1;
                    end
                end
            end
        end
    endtask

    initial begin
        $dumpfile("systolic.vcd");
        $dumpvars(0, tb_systolic_array_4x4);

        $readmemh("a_matrices.hex", a_values);
        $readmemh("b_matrices.hex", b_values);
        $readmemh("expected_results.hex", expected_values);

        repeat (RESET_TICKS) @(negedge clk);
        rst = 0;

        // An x in the last entry means a file was missing or too short
        if (^expected_values[TOTAL_ENTRIES - 1] === 1'bx) begin
            $display("ERROR: could not load the test files.");
            $display("Run the C++ reference model first.");
        end else begin
            for (test_num = 0; test_num < NUM_TESTS;
                 test_num = test_num + 1) begin
                load_test(test_num);
                run_multiply;
                check_results(test_num);
                $display("Test %0d done after %0d cycles",
                         test_num, num_cycles);
            end

            if (num_errors == 0) begin
                $display("PASS: all results match");
            end else begin
                $display("FAIL: %0d mismatches", num_errors);
            end
        end
        $finish;
    end
endmodule
