/**
 * systolic_array_4x4.v
 *
 * 4x4 Output-Stationary Systolic Array Matrix Multiplier
 *
 * Patrick Kraft
 * jpkraft@umich.edu
 *
 * Computes C = A * B for two 4x4 matrices using a grid of 16 processing
 * elements. Numbers from A move right, numbers from B move down, and each
 * PE keeps the running total for one entry of C.
 *
 * How to use it:
 *   1. Set start high for one tick to clear the old results.
 *   2. For the next 4 ticks (k = 0 to 3), set in_valid high and drive
 *      a_column with column k of A and b_row with row k of B.
 *   3. When done goes high, c_flat holds the answer. C[i][j] is at
 *      c_flat[(i * 4 + j) * ACC_WIDTH +: ACC_WIDTH].
 */

`timescale 1ns / 1ps

/**
 * Requires: start is held high for exactly one tick before the inputs are
 *           fed, and in_valid is high only while real inputs are present.
 * Modifies: done, c_flat
 * Effects:  Multiplies the matrices fed in through a_column and b_row and
 *           places the result in c_flat. Raises done once the last PE has
 *           finished, 3 * (ARRAY_SIZE - 1) + 1 ticks after the first input.
 */
module systolic_array_4x4 #(
    parameter ARRAY_SIZE = 4,
    parameter DATA_WIDTH = 8,
    parameter ACC_WIDTH = 32
)(
    input wire clk,
    input wire rst,
    input wire start,
    input wire in_valid,
    input wire [ARRAY_SIZE * DATA_WIDTH - 1:0] a_column,
    input wire [ARRAY_SIZE * DATA_WIDTH - 1:0] b_row,
    output reg done,
    output wire [ARRAY_SIZE * ARRAY_SIZE * ACC_WIDTH - 1:0] c_flat
);
    localparam LANE_BUS_WIDTH = ARRAY_SIZE * DATA_WIDTH;

    // The last PE does its final multiply-accumulate on this tick,
    // counting from 0: it is (ARRAY_SIZE - 1) ticks of input, plus
    // (ARRAY_SIZE - 1) ticks of row delay, plus (ARRAY_SIZE - 1) ticks
    // of column delay.
    localparam LAST_TICK = 3 * (ARRAY_SIZE - 1);
    localparam COUNT_WIDTH = $clog2(LAST_TICK + 1);

    // Feed zeros into the array whenever the inputs are not valid
    wire [LANE_BUS_WIDTH - 1:0] a_gated =
        in_valid ? a_column : {LANE_BUS_WIDTH{1'b0}};
    wire [LANE_BUS_WIDTH - 1:0] b_gated =
        in_valid ? b_row : {LANE_BUS_WIDTH{1'b0}};

    // a_bus[i][j] is the A input of PE(i, j), and b_bus[i][j] is its
    // B input. The extra last column of a_bus and last row of b_bus are
    // the outputs of the edge PEs, which are not used.
    wire [DATA_WIDTH - 1:0] a_bus [0:ARRAY_SIZE - 1][0:ARRAY_SIZE];
    wire [DATA_WIDTH - 1:0] b_bus [0:ARRAY_SIZE][0:ARRAY_SIZE - 1];

    reg [COUNT_WIDTH - 1:0] tick_count;
    reg running;

    genvar i;
    genvar j;
    generate
        // Delay lane i by i ticks so matching A and B values meet
        for (i = 0; i < ARRAY_SIZE; i = i + 1) begin : skew
            delay_line #(
                .DEPTH(i),
                .WIDTH(DATA_WIDTH)
            ) a_delay(
                .clk(clk),
                .rst(rst),
                .clr(start),
                .data_in(a_gated[i * DATA_WIDTH +: DATA_WIDTH]),
                .data_out(a_bus[i][0])
            );

            delay_line #(
                .DEPTH(i),
                .WIDTH(DATA_WIDTH)
            ) b_delay(
                .clk(clk),
                .rst(rst),
                .clr(start),
                .data_in(b_gated[i * DATA_WIDTH +: DATA_WIDTH]),
                .data_out(b_bus[0][i])
            );
        end

        for (i = 0; i < ARRAY_SIZE; i = i + 1) begin : row
            for (j = 0; j < ARRAY_SIZE; j = j + 1) begin : col
                pe #(
                    .DATA_WIDTH(DATA_WIDTH),
                    .ACC_WIDTH(ACC_WIDTH)
                ) u_pe(
                    .clk(clk),
                    .rst(rst),
                    .clr(start),
                    .a_in(a_bus[i][j]),
                    .b_in(b_bus[i][j]),
                    .a_out(a_bus[i][j + 1]),
                    .b_out(b_bus[i + 1][j]),
                    .acc(c_flat[(i * ARRAY_SIZE + j) * ACC_WIDTH +: ACC_WIDTH])
                );
            end
        end
    endgenerate

    always @(posedge clk) begin
        if (rst) begin
            tick_count <= 0;
            running <= 1'b0;
            done <= 1'b0;
        end else if (start) begin
            tick_count <= 0;
            running <= 1'b1;
            done <= 1'b0;
        end else if (running) begin
            tick_count <= tick_count + 1'b1;
            if (tick_count == LAST_TICK) begin
                running <= 1'b0;
                done <= 1'b1;
            end
        end
    end
endmodule
