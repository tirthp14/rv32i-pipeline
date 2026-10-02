package rv32i_pkg;

// Opcodes - instr[6:0]

typedef enum logic [6:0] {
    OP_R      = 7'b0110011, // ADD, SUB, AND, OR, XOR, SLL, SLR, SRA, SLA, SLT, SLTU -> R-type instructions
    OP_I_ALU  = 7'b0010011, // ADDI, ANDI, ORI, XORI, SLLI, SRLI, SRAI, SLTI, SLTIU  -> I-type instructions
    OP_LOAD   = 7'b0000011, // LB, LH, LW, LBU, LHU
    OP_STORE  = 7'b0100011, // SB, SH, SW
    OP_BRANCH = 7'b1100011, // BEQ, BNE, BLT, BGE, BLTU, BGEU
    OP_JAL    = 7'b1101111, // JAL
    OP_JALR   = 7'b1100111, // JALR
    OP_LUI    = 7'b0110111, // LUI
    OP_AUIPC  = 7'b0010111, // AUIPC
    OP_SYSTEM = 7'b1110011  // ECALL, EBREAK
} opcode_t;

// ALU Operations - Internal to this design, not defined by ISA

typedef enum logic [3:0] {
    ALU_ADD  = 4'd0, 
    ALU_SUB  = 4'd1,
    ALU_AND  = 4'd2,
    ALU_OR   = 4'd3,
    ALU_XOR  = 4'd4,
    ALU_SLL  = 4'd5, // shift left logical
    ALU_SRL  = 4'd6, // shift right logical
    ALU_SRA  = 4'd7, // shift right arithmetic
    ALU_SLT  = 4'd8, // set less than, signed
    ALU_SLTU = 4'd9  // set less than, unsigned
} alu_op_t;

// funct3 - instr[14:12]

// R-type and I-type ALU ops
// ADD/SUB and SRL/SRA are distinguished through funct7[5], not funct3
typedef enum logic [2:0] {
    F3_ADD_SUB = 3'b000,
    F3_SLL     = 3'b001,
    F3_SLT     = 3'b010,
    F3_SLTU    = 3'b011,
    F3_XOR     = 3'b100,
    F3_SRL_SRA = 3'b101,
    F3_OR      = 3'b110,
    F3_AND     = 3'b111
} alu_f3_t;

// Branches
typedef enum logic [2:0] {
    F3_BEQ  = 3'b000,
    F3_BNE  = 3'b001,
    F3_BLT  = 3'b100,
    F3_BGE  = 3'b101,
    F3_BLTU = 3'b110,
    F3_BGEU = 3'b111
} branch_f3_t;

// Loads
typedef enum logic [2:0] {
    F3_LB  = 3'b000,
    F3_LH  = 3'b001,
    F3_LW  = 3'b010,
    F3_LBU = 3'b100,
    F3_LHU = 3'b101
} load_f3_t;

// Stores
typedef enum logic [2:0] {
    F3_SB = 3'b000,
    F3_SH = 3'b001,
    F3_SW = 3'b010
} store_f3_t;

// ALUOp - the 2 bit hint that the main control passes to the alu_control
typedef enum logic [1:0] {
    ALUOP_ADD    = 2'b00, // loads, stores, HALR 
    ALUOP_BRANCH = 2'b01, // branches
    ALUOP_FUNCT  = 2'b10  // R/I type - decode from fucnt3/funct7
} alu_op_sel_t;

// Some useful constants because free will is a concept
localparam logic [31:0] NOP_INSTR = 32'h0000_0013; // ADDI x0, x0, 0
localparam logic [31:0] RESET_PC  = 32'h0000_0000; // self explanatory

endpackage
