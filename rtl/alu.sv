module alu (
    input  logic [0:31] a,
    input  logic [0:31] b,
    input  logic [0:2]  alu_ctrl,
    output logic [0:31] result,
    output logic zero_flag
);

    always_comb begin
        case (alu_ctrl)
            3'b000: result = a + b;       // ADD
            3'b001: result = a - b;       // SUB (and CMP)
            3'b010: result = a & b;       // AND (and TST)
            3'b011: result = a & (~b);    // BIC (Bit Clear)
            default: result = 32'b0;
        endcase
    end

    // The Zero Flag triggers if the result of ANY math operation is exactly 0
    assign zero_flag = (result == 32'd0);

endmodule
