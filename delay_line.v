/**
 * delay_line.v
 *
 * 4x4 Output-Stationary Systolic Array Matrix Multiplier
 *
 * Patrick Kraft
 * jpkraft@umich.edu
 *
 * A chain of registers that delays a signal by a set number of clock
 * ticks. The systolic array uses these to stagger its inputs so that
 * matching numbers from A and B reach each PE on the same tick.
 */

`timescale 1ns / 1ps

/**
 * Requires: DEPTH >= 0 and WIDTH > 0.
 * Modifies: data_out
 * Effects:  data_out equals data_in delayed by DEPTH clock ticks. When
 *           DEPTH is 0, data_out is wired directly to data_in. When rst or
 *           clr is high, every stage of the delay line is set to zero.
 */
module delay_line #(
    parameter DEPTH = 1,
    parameter WIDTH = 8
)(
    input wire clk,
    input wire rst,
    input wire clr,
    input wire [WIDTH - 1:0] data_in,
    output wire [WIDTH - 1:0] data_out
);
    generate
        if (DEPTH == 0) begin : no_delay
            assign data_out = data_in;
        end else begin : delay
            reg [WIDTH - 1:0] stages [0:DEPTH - 1];
            integer i;

            always @(posedge clk) begin
                for (i = 0; i < DEPTH; i = i + 1) begin
                    if (rst || clr) begin
                        stages[i] <= {WIDTH{1'b0}};
                    end else if (i == 0) begin
                        stages[i] <= data_in;
                    end else begin
                        stages[i] <= stages[i - 1];
                    end
                end
            end

            assign data_out = stages[DEPTH - 1];
        end
    endgenerate
endmodule
