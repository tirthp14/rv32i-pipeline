module tb_alu;
    import rv32i_pkg::*;

    logic [31:0] a, b, result;
    logic zero;
    alu_op_t op;

    int errors = 0;
    int tests  = 0;

    alu dut (
        .a (a),
        .b (b),
        .op (op),
        .result (result),
        .zero (zero)
    );

    class alu_txn;
        rand logic [31:0] a;
        rand logic [31:0] b;
        rand alu_op_t     op;

        constraint c_operands {
            a dist {
                32'h00000000                 := 5,
                32'h00000001                 := 5,
                32'h7FFFFFFF                 := 5,
                32'h80000000                 := 5,
                32'hFFFFFFFF                 := 5,
                [32'h2 : 32'h7FFFFFFE]       :/ 40,
                [32'h80000001 : 32'hFFFFFFFE] :/ 35
            };

            b dist {
                32'h00000000                 := 5,
                32'h00000001                 := 5,
                32'h0000001F                 := 5,
                32'h00000020                 := 5,
                32'h7FFFFFFF                 := 5,
                32'h80000000                 := 5,
                32'hFFFFFFFF                 := 5,
                [32'h2 : 32'h7FFFFFFE]       :/ 35,
                [32'h80000001 : 32'hFFFFFFFE] :/ 30
            };
        }
    endclass

    // Reference model for ALU operations

    function automatic logic [31:0] alu_ref(
    input logic [31:0] a,
    input logic [31:0] b,
    input alu_op_t     op
    );

        case (op)
            ALU_ADD:  return a + b;
            ALU_SUB:  return a - b;
            ALU_AND:  return a & b;
            ALU_OR:   return a | b;
            ALU_XOR:  return a ^ b;
            ALU_SLL:  return a << b[4:0];
            ALU_SRL:  return a >> b[4:0];
            ALU_SRA:  return $signed(a) >>> b[4:0];
            ALU_SLT:  return ($signed(a) < $signed(b)) ? 32'd1 : 32'd0;
            ALU_SLTU: return (a < b) ? 32'd1 : 32'd0;
            default:  return 32'd0;
        endcase
    endfunction

    // Cheching tasks

    task automatic check(
        input string       name,
        input logic [31:0] in_a,
        input logic [31:0] in_b,
        input alu_op_t     in_op,
        input logic [31:0] expected_result
    );

        a = in_a;
        b = in_b;
        op = in_op;
        #1ns;

        tests++;
        if (result !== expected_result) begin
            errors++;
            $display("FAIL %-20s a=%08x b=%08x -> got %08x, expected %08x", name, in_a, in_b, result, expected_result);
        end else begin
            $display("PASS %-20s a=%08x b=%08x -> got %08x", name, in_a, in_b, result, expected_result);
        end
    endtask

    task automatic check_zero(
        input string       name,
        input logic [31:0] in_a,
        input logic [31:0] in_b,
        input alu_op_t     in_op,
        input logic        expected_zero
    );

        a = in_a;
        b = in_b;
        op = in_op;
        #1ns;

        tests++;
        if (zero !== expected_zero) begin
            errors++;
            $display("FAIL %-20s a=%08x b=%08x -> zero=%b, expected %b", name, in_a, in_b, zero, expected_zero);
        end else begin
            $display("PASS %-20s a=%08x b=%08x -> zero=%b", name, in_a, in_b, zero);
        end
    endtask

    // Test sequences

    initial begin

        alu_txn txn;
        int rand_errors = 0;

        $display("================ ALU tests ================");

    //------------------------------------------------------------------------
    // ADD
    //------------------------------------------------------------------------
    check("add basic",        32'd5,        32'd7,        ALU_ADD, 32'd12);
    check("add zero",         32'd0,        32'd0,        ALU_ADD, 32'd0);
    check("add wrap",         32'hFFFFFFFF, 32'd1,        ALU_ADD, 32'd0);
    check("add negative",     32'hFFFFFFFF, 32'hFFFFFFFF, ALU_ADD, 32'hFFFFFFFE);
    check("add max",          32'h7FFFFFFF, 32'd1,        ALU_ADD, 32'h80000000);

    //------------------------------------------------------------------------
    // SUB
    //------------------------------------------------------------------------
    check("sub basic",        32'd12,       32'd5,        ALU_SUB, 32'd7);
    check("sub to zero",      32'd42,       32'd42,       ALU_SUB, 32'd0);
    check("sub underflow",    32'd0,        32'd1,        ALU_SUB, 32'hFFFFFFFF);
    check("sub negative",     32'd5,        32'd12,       ALU_SUB, 32'hFFFFFFF9);

    //------------------------------------------------------------------------
    // Bitwise
    //------------------------------------------------------------------------
    check("and basic",        32'hFF00FF00, 32'h0F0F0F0F, ALU_AND, 32'h0F000F00);
    check("and all ones",     32'hFFFFFFFF, 32'hFFFFFFFF, ALU_AND, 32'hFFFFFFFF);
    check("and zero",         32'hFFFFFFFF, 32'h00000000, ALU_AND, 32'h00000000);

    check("or basic",         32'hFF00FF00, 32'h0F0F0F0F, ALU_OR,  32'hFF0FFF0F);
    check("or with zero",     32'hA5A5A5A5, 32'h00000000, ALU_OR,  32'hA5A5A5A5);

    check("xor basic",        32'hFF00FF00, 32'h0F0F0F0F, ALU_XOR, 32'hF00FF00F);
    check("xor self",         32'hDEADBEEF, 32'hDEADBEEF, ALU_XOR, 32'h00000000);
    check("xor all ones",     32'h0F0F0F0F, 32'hFFFFFFFF, ALU_XOR, 32'hF0F0F0F0);

    //------------------------------------------------------------------------
    // SLL — shift left logical
    //------------------------------------------------------------------------
    check("sll by 0",         32'h00000001, 32'd0,        ALU_SLL, 32'h00000001);
    check("sll by 1",         32'h00000001, 32'd1,        ALU_SLL, 32'h00000002);
    check("sll by 31",        32'h00000001, 32'd31,       ALU_SLL, 32'h80000000);
    check("sll shamt mask",   32'h00000001, 32'd33,       ALU_SLL, 32'h00000002);
    check("sll out the top",  32'h80000000, 32'd1,        ALU_SLL, 32'h00000000);

    //------------------------------------------------------------------------
    // SRL — shift right logical (zero fill)
    //------------------------------------------------------------------------
    check("srl by 0",         32'h80000000, 32'd0,        ALU_SRL, 32'h80000000);
    check("srl by 1",         32'h80000000, 32'd1,        ALU_SRL, 32'h40000000);
    check("srl by 31",        32'h80000000, 32'd31,       ALU_SRL, 32'h00000001);
    check("srl shamt mask",   32'h80000000, 32'd32,       ALU_SRL, 32'h80000000);
    check("srl neg zero fill",32'hFFFFFFFF, 32'd4,        ALU_SRL, 32'h0FFFFFFF);

    //------------------------------------------------------------------------
    // SRA — shift right arithmetic (sign fill)
    //------------------------------------------------------------------------
    check("sra positive",     32'h40000000, 32'd4,        ALU_SRA, 32'h04000000);
    check("sra negative",     32'h80000000, 32'd4,        ALU_SRA, 32'hF8000000);
    check("sra neg by 31",    32'h80000000, 32'd31,       ALU_SRA, 32'hFFFFFFFF);
    check("sra minus one",    32'hFFFFFFFF, 32'd8,        ALU_SRA, 32'hFFFFFFFF);
    check("sra by 0",         32'hFFFFFFFF, 32'd0,        ALU_SRA, 32'hFFFFFFFF);
    check("sra divide by 2",  32'hFFFFFFF8, 32'd1,        ALU_SRA, 32'hFFFFFFFC);

    //------------------------------------------------------------------------
    // SLT — signed comparison
    //------------------------------------------------------------------------
    check("slt true",         32'd5,        32'd7,        ALU_SLT, 32'd1);
    check("slt false",        32'd7,        32'd5,        ALU_SLT, 32'd0);
    check("slt equal",        32'd5,        32'd5,        ALU_SLT, 32'd0);
    check("slt neg vs pos",   32'hFFFFFFFF, 32'd1,        ALU_SLT, 32'd1);
    check("slt pos vs neg",   32'd1,        32'hFFFFFFFF, ALU_SLT, 32'd0);
    check("slt min vs max",   32'h80000000, 32'h7FFFFFFF, ALU_SLT, 32'd1);

    //------------------------------------------------------------------------
    // SLTU — unsigned comparison
    //------------------------------------------------------------------------
    check("sltu true",        32'd5,        32'd7,        ALU_SLTU, 32'd1);
    check("sltu false",       32'd7,        32'd5,        ALU_SLTU, 32'd0);
    check("sltu equal",       32'd5,        32'd5,        ALU_SLTU, 32'd0);
    check("sltu high bit",    32'hFFFFFFFF, 32'd1,        ALU_SLTU, 32'd0);
    check("sltu one vs max",  32'd1,        32'hFFFFFFFF, ALU_SLTU, 32'd1);
    check("sltu min vs max",  32'h80000000, 32'h7FFFFFFF, ALU_SLTU, 32'd0);

    //------------------------------------------------------------------------
    // Zero flag
    //------------------------------------------------------------------------
    check_zero("zero on sub eq",   32'd42,       32'd42,       ALU_SUB,  1'b1);
    check_zero("zero on sub neq",  32'd42,       32'd41,       ALU_SUB,  1'b0);
    check_zero("zero on add wrap", 32'hFFFFFFFF, 32'd1,        ALU_ADD,  1'b1);
    check_zero("zero on and",      32'hF0F0F0F0, 32'h0F0F0F0F, ALU_AND,  1'b1);
    check_zero("zero on xor self", 32'hDEADBEEF, 32'hDEADBEEF, ALU_XOR,  1'b1);
    check_zero("not zero",         32'd5,        32'd7,        ALU_ADD,  1'b0);

  // Contrained random test

    $display("--- constrained random (%0d transactions) ---", 10000);

    txn = new();

    repeat (10000) begin
        if (!txn.randomize()) $fatal(1, "randomize() failed");

        a = txn.a;
        b = txn.b;
        op = txn.op;
        #1;

        tests++;
        if (result !== alu_ref(a, b, op)) begin
            errors++;
            rand_errors++;
            $display("FAIL random  op=%s a=%08x b=%08x -> got %08x, expected %08x",
                     txn.op.name(), txn.a, txn.b, result,
                     alu_ref(txn.a, txn.b, txn.op));
        end
    end

    $display("--- random phase: %0d failures ---", rand_errors);        // rand specific failures

    $display("===========================================");            // universial tb failures
    $display("  %0d / %0d passed", tests - errors, tests);
    $display("===========================================");

    if (errors != 0) $fatal(1, "%0d failure(s)", errors);
    $finish;

  end

endmodule
