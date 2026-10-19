/**
 * pe.v
 *
 * 4x4 Output-Stationary Systolic Array Matrix Multiplier
 *
 * Patrick Kraft
 * jpkraft@umich.edu
 *
 * One processing element (PE) of the systolic array. On every clock tick
 * it multiplies the two numbers it receives, adds the product to its
 * running total, and passes the numbers on to its right and lower
 * neighbors.
 */

`timescale 1ns / 1ps

/**
 * Requires: DATA_WIDTH and ACC_WIDTH are positive, and ACC_WIDTH is large
 *           enough to hold the final sum without overflowing.
 * Modifies: a_out, b_out, acc
 * Effects:  On each rising clock edge, clears all outputs if rst or clr is
 *           high. Otherwise adds a_in * b_in to acc, copies a_in to a_out,
 *           and copies b_in to b_out.
 */
module pe #(
    parameter DATA_WIDTH = 8,
    parameter ACC_WIDTH = 32
)(
    input wire clk,
    // synchronous reset
    input wire rst,
    // clears the running total before a new multiply starts
    input wire clr,
    // number arriving from the left neighbor (from matrix A)
    input wire [DATA_WIDTH - 1:0] a_in,
    // number arriving from the upper neighbor (from matrix B)
    input wire [DATA_WIDTH - 1:0] b_in,
    output reg [DATA_WIDTH - 1:0] a_out,
    output reg [DATA_WIDTH - 1:0] b_out,
    // running total, which ends up holding one entry of C
    output reg [ACC_WIDTH - 1:0] acc
);
    always @(posedge clk) begin
        if (rst || clr) begin
            a_out <= {DATA_WIDTH{1'b0}};
            b_out <= {DATA_WIDTH{1'b0}};
            acc <= {ACC_WIDTH{1'b0}};
        end else begin
            a_out <= a_in;
            b_out <= b_in;
            acc <= acc + a_in * b_in;
        end
    end
endmodule
