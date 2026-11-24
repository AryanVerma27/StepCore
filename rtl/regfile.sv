module regfile (
    input  logic clk,
    input  logic reset,
    input  logic write_enable,
    input  logic [0:3] a1,
    input  logic [0:3] a2,
    input  logic [0:3] a3,
    input  logic [0:31] wd3,
    output logic [0:31] rd1,
    output logic [0:31] rd2
);

    // Array of 16 registers, strictly reverse endian
    logic [0:31] rf [0:15];

    // Combinational asynchronous read
    assign rd1 = rf[a1];
    assign rd2 = rf[a2];

    // Synchronous write and reset
    always_ff @(posedge clk) begin
        if (reset) begin
            // Clear all registers to 0 on reset
            for (int i=0; i<16; i++) begin
                rf[i] <= 32'd0;
            end
        end else if (write_enable) begin
            rf[a3] <= wd3;
        end
    end

endmodule
