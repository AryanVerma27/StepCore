module arm_core (
    input  logic clk,
    input  logic reset
);

    // --- Internal Wires ---
    logic [0:31] pc_current;
    logic [0:31] instruction;
    logic [0:31] read_data_1, read_data_2;
    logic [0:31] alu_result;
    logic        alu_zero;

    logic        branch_en;
    logic [0:31] branch_target;
    logic        reg_write_en;
    logic [0:2]  alu_control;

    // Memory Control Wires
    logic        mem_write_en;
    logic        mem_to_reg;
    logic [0:31] read_data_mem;

    // --- Instruction Slicing (Reverse Endian [0:31]) ---
    logic [0:3] reg_src_1;
    logic [0:3] reg_src_2;
    logic [0:3] reg_dest;
    logic [0:3] opcode;

    assign reg_src_1 = instruction[16:19]; // Rn (Base Address for LDR/STR)
    assign reg_src_2 = instruction[0:3];   // Rm (Data to Store for STR)
    assign reg_dest  = instruction[12:15]; // Rd (Destination for LDR)
    assign opcode    = instruction[21:24]; // bits 24:21

    // --- Status Register (CPSR bit) ---
    logic saved_zero_flag;
    always_ff @(posedge clk) begin
        if (reset) saved_zero_flag <= 1'b0;
        else if (opcode == 4'b1010 || opcode == 4'b1000) // CMP or TST
            saved_zero_flag <= alu_zero;
    end

    // --- Diagnostic Print Commands ---
    always @(posedge clk) begin
        if (!reset && instruction !== 32'dx && instruction !== 32'd0) begin
            $display("\n[Cycle at %0t ns] --------------------------", $time);
            $display("  FETCH  : PC=%0d | Inst=0x%h", pc_current, instruction);
            $display("  DECODE : Op=4'b%b | Rn=R%0d | Rm=R%0d | Rd=R%0d", opcode, reg_src_1, reg_src_2, reg_dest);
            $display("  READ   : Reg[R%0d]=%0d | Reg[R%0d]=%0d", reg_src_1, read_data_1, reg_src_2, read_data_2);
            $display("  EXEC   : ALU Result=%0d | Zero=%b", alu_result, alu_zero);
            if (reg_write_en && !mem_to_reg)
                $display("  WRITE  : Storing ALU %0d into Register R%0d", alu_result, reg_dest);
            if (reg_write_en && mem_to_reg)
                $display("  WRITE  : Loading RAM %0d into Register R%0d", read_data_mem, reg_dest);
            if (branch_en)
                $display("  BRANCH : Jumping to Address %0d", branch_target);
            $display("----------------------------------------------");
        end
    end

    // --- Module Instantiations ---
    pc my_pc (.clk(clk), .reset(reset), .branch_en(branch_en), .branch_addr(branch_target), .pc_out(pc_current));

    imem my_imem (.addr(pc_current), .inst(instruction));

    alu my_alu (.a(read_data_1), .b(read_data_2), .alu_ctrl(alu_control), .result(alu_result), .zero_flag(alu_zero));

    // --- Data Memory ---
    dmem my_dmem (
        .clk(clk),
        .mem_write_en(mem_write_en),
        .addr(read_data_1),       // Address comes from Rn
        .write_data(read_data_2), // Data to store comes from Rm
        .read_data(read_data_mem) // Data loaded from RAM
    );

    // --- Register File Writeback Multiplexer ---
    logic [0:3]  final_write_reg;
    logic [0:31] final_write_data;

    regfile my_regfile (
        .clk(clk), .reset(reset), .write_enable(reg_write_en),
        .a1(reg_src_1), .a2(reg_src_2), .a3(final_write_reg),
        .wd3(final_write_data), .rd1(read_data_1), .rd2(read_data_2)
    );

    // --- Control Unit (Combinational) ---
    always_comb begin
        // Default behaviors
        reg_write_en     = 1'b0;
        mem_write_en     = 1'b0;
        mem_to_reg       = 1'b0;
        branch_en        = 1'b0;
        branch_target    = 32'd0;
        alu_control      = 3'b000;

        // Multiplexers for writeback
        final_write_reg  = reg_dest;   // Normally write to Rd
        final_write_data = mem_to_reg ? read_data_mem : alu_result;

        case(opcode)
            4'b0100: begin alu_control = 3'b000; reg_write_en = 1'b1; end // ADD
            4'b0010: begin alu_control = 3'b001; reg_write_en = 1'b1; end // SUB
            4'b0000: begin alu_control = 3'b010; reg_write_en = 1'b1; end // AND
            4'b1110: begin alu_control = 3'b011; reg_write_en = 1'b1; end // BIC

            4'b1010: begin alu_control = 3'b001; reg_write_en = 1'b0; end // CMP
            4'b1000: begin alu_control = 3'b010; reg_write_en = 1'b0; end // TST

            4'b0111: begin // LDR (Load from Memory)
                reg_write_en = 1'b1;
                mem_to_reg   = 1'b1; // Pull data from RAM, not ALU
            end
            4'b0101: begin // STR (Store to Memory)
                mem_write_en = 1'b1; // Tell RAM to save data
            end

            4'b1011: begin // B (Branch)
                if (!saved_zero_flag) begin
                    branch_en = 1'b1;
                    branch_target = 32'd0;
                end
            end
            4'b1111: begin // BL (Branch with Link)
                branch_en = 1'b1;
                reg_write_en = 1'b1;
                final_write_reg = 4'd14; // Save to R14
                final_write_data = pc_current + 32'd4;
            end
            default: reg_write_en = 1'b0;
        endcase
    end

endmodule
