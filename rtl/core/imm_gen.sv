module imm_gen import rv32i_pkg::*; (
    input logic [31:0] instr,
    output logic [31:0] imm
);

    always_comb begin

        case (opcode_t'(instr[6:0]))
            OP_I_ALU, OP_LOAD, OP_JALR: begin
                imm = {{20{instr[31]}}, instr[31:20]};
            end
            OP_STORE: begin
                imm = {{20{instr[31]}}, instr[31:25], instr[11:7]};
            end
            OP_BRANCH: begin
                imm = {{20{instr[31]}}, instr[7], instr[30:25], instr[11:8], 1'b0};
            end
            OP_LUI, OP_AUIPC: begin
                imm = {instr[31:12], 12'b0};
            end
            OP_JAL: begin
                imm = {{12{instr[31]}}, instr[19:12], instr[20], instr[30:21], 1'b0};
            end
            default: begin
                imm = 32'd0;
            end
        endcase
    end

endmodule
