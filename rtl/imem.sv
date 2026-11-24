module imem (
    input  logic [0:31] addr,
    output logic [0:31] inst
);

    // Instruction ROM (64 words), loaded by the testbench before reset is released
    logic [0:31] rom [0:63];

    // The read logic: Convert the PC address to an array index
    assign inst = rom[addr / 4];

endmodule
