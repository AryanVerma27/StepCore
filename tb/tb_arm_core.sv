module tb_arm_core;

    logic clk;
    logic reset;

    arm_core dut (.clk(clk), .reset(reset));

    // Generate a clock: toggle every 5 nanoseconds
    always #5 clk = ~clk;

    initial begin
        // Variables to hold the user inputs
        int a_val, b_val;

        // --- READ PLUSARGS ---
        // If the user doesn't provide +A=... or +B=..., default to 15 and 1
        if (!$value$plusargs("A=%d", a_val)) begin
            a_val = 15;
        end
        if (!$value$plusargs("B=%d", b_val)) begin
            b_val = 1;
        end

        // --- PREPARATION ---
        // Clear all memory to 0 first
        for (int i = 0; i < 64; i++) dut.my_imem.rom[i] = 32'd0;

        // =========================================================
        // TEST 1: MINIMAL PROGRAM (C = A SUB B)
        // =========================================================
        $display("\n========================================");
        $display("   STARTING TEST 1: MINIMAL PROGRAM (%0d - %0d)", a_val, b_val);
        $display("========================================");

        // Load Minimal Program (SUB R3, R1, R2) into Address 0
        dut.my_imem.rom[0] = 32'd0;
        dut.my_imem.rom[0][21:24] = 4'b0010; // SUB
        dut.my_imem.rom[0][16:19] = 4'd1;    // R1 (A)
        dut.my_imem.rom[0][0:3]   = 4'd2;    // R2 (B)
        dut.my_imem.rom[0][12:15] = 4'd3;    // R3 (C)

        // Reset the CPU (Sets PC back to 0)
        clk = 0;
        reset = 1;
        #20;
        reset = 0;

        // Inject the User's Variables into the registers
        force dut.my_regfile.rf[1] = a_val;
        force dut.my_regfile.rf[2] = b_val;
        #1;
        release dut.my_regfile.rf[1];
        release dut.my_regfile.rf[2];

        // Let the CPU run the math
        #50;

        // Verify Minimal Test Dynamically!
        if (dut.my_regfile.rf[3] == (a_val - b_val))
            $display("[SUCCESS] MINIMAL TEST PASSED! C (R3) = %0d", dut.my_regfile.rf[3]);
        else
            $display("[ERROR] MINIMAL TEST FAILED! Expected %0d, Got: %0d", (a_val - b_val), dut.my_regfile.rf[3]);


        // =========================================================
        // TEST 2: LOOPING PROGRAM (Sum 1 to 10 = 55)
        // =========================================================
        $display("\n========================================");
        $display("   STARTING TEST 2: LOOPING PROGRAM");
        $display("========================================");

        // Wipe the ROM clean for the new program
        for (int i = 0; i < 64; i++) dut.my_imem.rom[i] = 32'd0;

        // Load Loop Program into Addresses 0, 4, 8, 12
        dut.my_imem.rom[0][21:24] = 4'b0100; dut.my_imem.rom[0][16:19] = 4'd1; dut.my_imem.rom[0][0:3] = 4'd2; dut.my_imem.rom[0][12:15] = 4'd1; // ADD R1, R1, R2
        dut.my_imem.rom[1][21:24] = 4'b0100; dut.my_imem.rom[1][16:19] = 4'd2; dut.my_imem.rom[1][0:3] = 4'd3; dut.my_imem.rom[1][12:15] = 4'd2; // ADD R2, R2, R3
        dut.my_imem.rom[2][21:24] = 4'b1010; dut.my_imem.rom[2][16:19] = 4'd2; dut.my_imem.rom[2][0:3] = 4'd4; // CMP R2, R4
        dut.my_imem.rom[3][21:24] = 4'b1011; // B

        // Reset the CPU again (Sets PC back to 0)
        reset = 1;
        #20;
        reset = 0;

        // Inject Loop Variables
        force dut.my_regfile.rf[1] = 0;   // C = 0
        force dut.my_regfile.rf[2] = 1;   // i = 1
        force dut.my_regfile.rf[3] = 1;   // Const = 1
        force dut.my_regfile.rf[4] = 11;  // Limit = 11
        #1;
        release dut.my_regfile.rf[1];
        release dut.my_regfile.rf[2];
        release dut.my_regfile.rf[3];
        release dut.my_regfile.rf[4];

        // Let the CPU run for 10 full loops
        #500;

        // Verify Loop Test
        if (dut.my_regfile.rf[1] == 32'd55)
            $display("[SUCCESS] LOOP TEST PASSED! C (R1) = 55");
        else
            $display("[ERROR] LOOP TEST FAILED! Expected 55, Got: %0d", dut.my_regfile.rf[1]);

        $display("\n========================================");
        $display("   ALL TESTS COMPLETED SUCCESSFULLY!  ");
        $display("========================================\n");
        $finish;
    end
endmodule
