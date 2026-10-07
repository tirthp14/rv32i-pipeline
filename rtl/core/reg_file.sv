module reg_file (
    input logic clk,
    input logic rst,
    input logic [4:0] rs1,   // source register addresses 1
    input logic [4:0] rs2,   // source register addresses 2
    input logic [4:0] rd,    // destination register address
    input logic [31:0] wd,   // actual value being written to the reg file
    input logic we,          // write enable

    output logic [31:0] rd1, // actual value being read from the reg file
    output logic [31:0] rd2  // value being read from the reg file
);

    // reg file
    logic [31:0] regs [0:31];

    always_ff @(posedge clk or posedge rst) begin
        if (rst) begin
            //rest all my regs please
            for (int i = 0; i < 32; i++) begin
                regs[i] <= 32'd0;
            end
        end else if (we && rd != 5'd0) begin
            regs[rd] <= wd;
        end
    end

    assign rd1 = (rs1 == 5'd0) ? 32'd0 : (we && rd == rs1) ? wd : regs[rs1];
    assign rd2 = (rs2 == 5'd0) ? 32'd0 : (we && rd == rs2) ? wd : regs[rs2];

endmodule
