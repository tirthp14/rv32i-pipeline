//-----------------------------------------------------------------------------
// Requirements under test:
//   1. 32 registers, each independently addressable
//   2. Two simultaneous reads through independent ports
//   3. One write, gated by write enable
//   4. x0 always reads zero
//   5. Writes to x0 are discarded
//   6. Read-during-write returns the new data (write-first bypass)
//   7. Reset zeroes all registers
//-----------------------------------------------------------------------------

module tb_reg_file;

    logic clk;
    logic rst;
    logic [4:0] rs1;
    logic [4:0] rs2;
    logic [4:0] rd;
    logic [31:0] wd;
    logic we;

    logic [31:0] rd1;
    logic [31:0] rd2;

    int errors = 0;
    int tests = 0;

    reg_file dut (
        .clk(clk),
        .rst(rst),
        .rs1(rs1),
        .rs2(rs2),
        .rd(rd),
        .wd(wd),
        .we(we),
        .rd1(rd1),
        .rd2(rd2)
    );

    always #5ns clk = ~clk;

    // Write a value consume one clock edge

    task automatic write_reg (input logic [4:0] addr, input logic [31:0] data);
        @(negedge clk);
        we = 1'b1;
        rd = addr;
        wd = data;
        @(posedge clk);
        @(negedge clk);
        we = 1'b0;
    endtask

    // Read thorugh port 1 and compare

    task automatic read_rd1 (input string name, input logic [4:0] addr, input logic [31:0] expected);
        rs1 = addr;
        #1ns;

        tests++;

        if (rd1 !== expected) begin
            $display("FAIL %-24s x%0d -> got %08x, expected %08x", name, addr, rd1, expected);
            errors++;
        end else begin
            $display("PASS %-24s x%0d -> %08x", name, addr, rd1);
        end
    endtask

    // Read thorugh port 2 and compare

    task automatic read_rd2 (input string name, input logic [4:0] addr, input logic [31:0] expected);
        rs2 = addr;
        #1ns;

        tests++;

        if (rd2 !== expected) begin
            $display("FAIL %-24s x%0d -> got %08x, expected %08x", name, addr, rd2, expected);
            errors++;
        end else begin
            $display("PASS %-24s x%0d -> %08x", name, addr, rd2);
        end
    endtask

    //---------------------------------------------------------------------------------------------------

    initial begin
        $display("Starting reg_file testbench");

        clk = 1'b0;
        rst = 1'b1;
        rs1 = 5'd0;
        rs2 = 5'd0;
        rd = 5'd0;
        wd = 32'd0;
        we = 1'b0;

        repeat (2) @(negedge clk);
        rst = 1'b0;

        // reset zeroes every4thing

        read_rd1("Read x1 after reset", 5'd1, 32'd0);
        read_rd1("Read x17 after reset", 5'd17, 32'd0);
        read_rd1("Read x31 after reset", 5'd31, 32'd0);

        // basic read and write tests
        write_reg(5'd5, 32'hdeadbeef);
        read_rd1("Read x5 after write", 5'd5, 32'hdeadbeef);
        read_rd2("Read x2 (should be zero)", 5'd2, 32'd0);

        write_reg(5'd2, 32'hcafebabe);
        read_rd1("Read x2 after write", 5'd2, 32'hcafebabe);
        read_rd2("Read x5 (should be deadbeef)", 5'd5, 32'hdeadbeef);

        read_rd1("x5 unchanged by x2 write", 5'd5, 32'hDEADBEEF);

        // every reg is independently addressable

        for (int i = 1; i < 32; i++) begin
            write_reg(i[4:0], 32'hA0000000 + i);
        end
        for (int i = 1; i < 32; i++) begin
            read_rd1($sformatf("sweep x%0d", i), i[4:0], 32'hA0000000 + i);
        end

        // 2 indepenedent read ports

        write_reg(5'd3,  32'h11111111);
        write_reg(5'd9,  32'h22222222);

        rs1 = 5'd3;
        rs2 = 5'd9;
        #1ns;

        read_rd1("Read x3 through port 1", 5'd3, 32'h11111111);
        read_rd2("Read x9 through port 2", 5'd9, 32'h22222222);

        // same reg on both ports

        read_rd1("Both ports read x3", 5'd3, 32'h11111111);
        read_rd2("Both ports read x3", 5'd3, 32'h11111111);

        // x0 behaviour

        read_rd1("x0 reads zero (port 1)", 5'd0, 32'd0);
        read_rd2("x0 reads zero (port 2)", 5'd0, 32'd0);

        write_reg(5'd0, 32'hFFFFFFFF);
        read_rd1("x0 write discarded", 5'd0, 32'd0);
        read_rd2("x0 write discarded (p2)", 5'd0, 32'd0);

        // write enable being low means no write can happen

        write_reg(5'd10, 32'h0BADF00D);
        read_rd1("x10 before we-low attempt", 5'd10, 32'h0BADF00D);

        @(negedge clk);
        rd = 5'd10;
        wd = 32'hFFFFFFFF;
        we = 1'b0;              // enable deasserted
        @(posedge clk);
        @(negedge clk);
        read_rd1("x10 unchanged with we=0", 5'd10, 32'h0BADF00D);

        // write first bypassing

        write_reg(5'd7, 32'h00000001);     // seed an old value

        @(negedge clk);
        rd  = 5'd7;
        wd  = 32'h12345678;
        we  = 1'b1;
        rs1 = 5'd7;
        #1ns;
        read_rd1("bypass before clock edge", 5'd7, 32'h12345678);
        read_rd2("bypass on port 2",         5'd7, 32'h12345678);

        @(posedge clk);
        @(negedge clk);
        we = 1'b0;
        read_rd1("value stored after edge", 5'd7, 32'h12345678);

        // bypass must not fire when we is low
        @(negedge clk);
        rd  = 5'd7;
        wd  = 32'hAAAAAAAA;
        we  = 1'b0;
        #1ns;
        read_rd1("no bypass when we=0", 5'd7, 32'h12345678);

        // x0 wins over bypass
        @(negedge clk);
        rd  = 5'd0;
        wd  = 32'h99999999;
        we  = 1'b1;
        #1ns;
        read_rd1("x0 beats bypass", 5'd0, 32'd0);
        @(posedge clk);
        @(negedge clk);
        we = 1'b0;

        // setting a reset mid test should clear everything

        read_rd1("x5 before reset", 5'd5, 32'hA0000005);

        @(negedge clk);
        rst = 1'b1;
        @(posedge clk);
        @(negedge clk);
        rst = 1'b0;

        read_rd1("x5 cleared by reset",  5'd5,  32'd0);
        read_rd1("x31 cleared by reset", 5'd31, 32'd0);
        read_rd2("x9 cleared by reset",  5'd9,  32'd0);

        $display("============================================");
        $display("  %0d / %0d passed", tests - errors, tests);
        $display("============================================");

        if (errors != 0) $fatal(1, "%0d failure(s)", errors);
        $finish;
    end

endmodule