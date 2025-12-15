

module tb_pipelined_mips_advanced;

    reg         clk;
    reg         rst;
    reg  [4:0]  ra3;

    pipelined_mips_top DUT (
        .clk(clk),
        .rst(rst),
        .ra3(ra3)
    );

    wire [31:0] pc_F;
    wire [31:0] instr_F;
    wire [31:0] instr_D;
    wire [31:0] pc_plus4_D;
    wire [31:0] instr_E;
    wire [31:0] alu_out_E;
    wire [31:0] instr_M;
    wire [31:0] alu_out_M;
    wire [31:0] instr_W;
    wire [31:0] result_W;

    wire        stall_F;
    wire        stall_D;
    wire        flush_E;
    wire        flush_D;
    wire [1:0]  forward_A;
    wire [1:0]  forward_B;

    wire        branch_D;
    wire        jump_D;
    wire        we_reg_W;
    wire [4:0]  write_reg_W;

    assign pc_F = DUT.cpu.dp.pc_F;
    assign instr_F = DUT.instr;
    assign instr_D = DUT.cpu.dp.instr_D;
    assign pc_plus4_D = DUT.cpu.dp.pc_plus4_D;

    assign stall_F = DUT.cpu.dp.stall_F;
    assign stall_D = DUT.cpu.dp.stall_D;
    assign flush_E = DUT.cpu.dp.flush_E;
    assign flush_D = DUT.cpu.dp.flush_D;
    assign forward_A = DUT.cpu.dp.forward_A;
    assign forward_B = DUT.cpu.dp.forward_B;

    assign branch_D = DUT.cpu.dp.branch_D;
    assign jump_D = DUT.cpu.dp.jump_D;
    assign we_reg_W = DUT.cpu.dp.we_reg_W;
    assign write_reg_W = DUT.cpu.dp.write_reg_W;

    assign alu_out_M = DUT.cpu.dp.alu_out_M;

    integer cycle;

    initial begin
        clk = 0;
        forever #5 clk = ~clk;
    end

    initial begin
        $dumpfile("pipelined_mips_advanced.vcd");
        $dumpvars(0, tb_pipelined_mips_advanced);
        $dumpvars(0, DUT.cpu.dp.if_id);
        $dumpvars(0, DUT.cpu.dp.id_ex);
        $dumpvars(0, DUT.cpu.dp.ex_mem);
        $dumpvars(0, DUT.cpu.dp.mem_wb);
        $dumpvars(0, DUT.cpu.dp.hdu);
        $dumpvars(0, DUT.cpu.dp.fwd);
    end

    initial begin
        $display("\n========================================");
        $display("PIPELINED MIPS - PIPELINE STAGE MONITOR");
        $display("========================================\n");
        $display("Cycle | IF (pc_current)  | ID (Inst) | EX (Inst) | MEM (Inst) | WB (Inst)  | Hazards");
        $display("------|----------|-----------|-----------|------------|------------|------------------");
    end

    always @(posedge clk) begin
        if (!rst) begin
            $write("%5d | %08h | %08h  | %08h  | %08h   | %08h   | ",
                   cycle, pc_F, instr_D,
                   DUT.cpu.dp.id_ex.rd1_E[31:0] ? DUT.cpu.dp.alu_ctrl_E : 32'h0,
                   alu_out_M,
                   we_reg_W ? write_reg_W : 32'h0);

            if (stall_F || stall_D)
                $write("STALL ");
            if (flush_D)
                $write("FLUSH_D ");
            if (flush_E)
                $write("FLUSH_E ");
            if (forward_A == 2'b10)
                $write("FWD_A(MEM) ");
            else if (forward_A == 2'b01)
                $write("FWD_A(WB) ");
            if (forward_B == 2'b10)
                $write("FWD_B(MEM) ");
            else if (forward_B == 2'b01)
                $write("FWD_B(WB) ");
            if (branch_D)
                $write("BRANCH ");
            if (jump_D)
                $write("JUMP ");

            $display("");
        end
    end

    initial begin
        cycle = 0;
        rst = 1;
        ra3 = 0;

        #20;
        rst = 0;

        #600;

        $display("\n========================================");
        $display("Total Cycles: %d", cycle);
        $display("========================================\n");

        $finish;
    end

    always @(posedge clk) begin
        if (rst)
            cycle = 0;
        else
            cycle = cycle + 1;
    end

    initial begin
        #10000;
        $display("\nERROR: Simulation timeout!");
        $finish;
    end

endmodule

module tb_hazard_detection;

    reg         clk;
    reg         rst;

    pipelined_mips_top DUT (
        .clk(clk),
        .rst(rst),
        .ra3(5'h0)
    );

    wire        stall;
    wire        flush;
    wire [31:0] pc;
    wire [31:0] instr;

    assign stall = DUT.cpu.dp.stall_F;
    assign flush = DUT.cpu.dp.flush_E | DUT.cpu.dp.flush_D;
    assign pc = DUT.pc;
    assign instr = DUT.instr;

    initial begin
        clk = 0;
        forever #5 clk = ~clk;
    end

    initial begin
        $dumpfile("hazard_detection.vcd");
        $dumpvars(0, tb_hazard_detection);

        $display("\n=== HAZARD DETECTION TEST ===\n");
        $display("Time | pc_current   | Instruction | Stall | Flush | Event");
        $display("-----|------|-------------|-------|-------|------------------");

        rst = 1;
        #20;
        rst = 0;

        #500;

        $display("\n=== Test Complete ===\n");
        $finish;
    end

    always @(posedge clk) begin
        if (!rst) begin
            $display("%4t | %04h | %08h    | %1b     | %1b     | %s",
                     $time, pc, instr, stall, flush,
                     stall ? "HAZARD DETECTED" : (flush ? "FLUSHING" : "Normal"));
        end
    end

endmodule

module tb_forwarding;

    reg         clk;
    reg         rst;

    pipelined_mips_top DUT (
        .clk(clk),
        .rst(rst),
        .ra3(5'h0)
    );

    wire [1:0]  forward_A;
    wire [1:0]  forward_B;
    wire [31:0] pc;
    wire [31:0] instr;
    wire [31:0] alu_in_a;
    wire [31:0] alu_in_b;

    assign forward_A = DUT.cpu.dp.forward_A;
    assign forward_B = DUT.cpu.dp.forward_B;
    assign pc = DUT.pc;
    assign instr = DUT.instr;
    assign alu_in_a = DUT.cpu.dp.alu_pa_fwd;
    assign alu_in_b = DUT.cpu.dp.alu_pb_fwd;

    initial begin
        clk = 0;
        forever #5 clk = ~clk;
    end

    initial begin
        $dumpfile("forwarding_test.vcd");
        $dumpvars(0, tb_forwarding);

        $display("\n=== DATA FORWARDING TEST ===\n");
        $display("Time | pc_current   | Instruction | FwdA | FwdB | ALU_A    | ALU_B    | Source");
        $display("-----|------|-------------|------|------|----------|----------|------------------");

        rst = 1;
        #20;
        rst = 0;

        #500;

        $display("\n=== Test Complete ===\n");
        $finish;
    end

    always @(posedge clk) begin
        if (!rst) begin
            $display("%4t | %04h | %08h    | %2b   | %2b   | %08h | %08h | %s",
                     $time, pc, instr, forward_A, forward_B, alu_in_a, alu_in_b,
                     get_forward_source(forward_A, forward_B));
        end
    end

    function [200*8:1] get_forward_source;
        input [1:0] fwd_a;
        input [1:0] fwd_b;
        begin
            if (fwd_a == 2'b10 || fwd_b == 2'b10)
                get_forward_source = "MEM Stage";
            else if (fwd_a == 2'b01 || fwd_b == 2'b01)
                get_forward_source = "WB Stage";
            else
                get_forward_source = "Register File";
        end
    endfunction

endmodule