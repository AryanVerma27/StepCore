module dmem (
    input  logic clk,
    input  logic mem_write_en,
    input  logic [0:31] addr,
    input  logic [0:31] write_data,
    output logic [0:31] read_data
);

    // Data Memory Array (64 words, 32-bits each)
    // Bit-reversed [0:31] vector ordering, consistent with the rest of the design
    logic [0:31] ram [0:63];

    initial begin
        // Initialize all RAM to 0 on startup
        for (int i = 0; i < 64; i++) begin
            ram[i] = 32'd0;
        end
    end

    // --- LDR (Load) ---
    // Combinational asynchronous read. Word-aligned (addr / 4).
    assign read_data = ram[addr / 4];

    // --- STR (Store) ---
    // Synchronous write on the clock edge.
    // Plain always (not always_ff) so the initial block may also drive ram[] in VCS
    always @(posedge clk) begin
        if (mem_write_en) begin
            ram[addr / 4] <= write_data;

            // Diagnostic print for every store
            $display("  [RAM]  Stored %0d into Memory Address %0d", write_data, addr);
        end
    end

endmodule
