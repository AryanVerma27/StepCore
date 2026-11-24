module pc (
    input  logic clk,
    input  logic reset,
    input  logic branch_en,
    input  logic [0:31] branch_addr,       // Reverse endian
    output logic [0:31] pc_out             // Current instruction address
);

    always_ff @(posedge clk) begin
        if (reset)
            pc_out <= 32'd0;
        else if (branch_en)
            pc_out <= branch_addr;
        else
            pc_out <= pc_out + 32'd4;
    end

endmodule
