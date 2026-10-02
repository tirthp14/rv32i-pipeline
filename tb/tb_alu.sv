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

    task automatic check(
        input string       name,
        input logic [31:0] in_a,
        input logic [31:0] in_b,
        input alu_op_t     in_op,
        input logic [31:0] expected_result,
    );

        a = in_a;
        b = in_b
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