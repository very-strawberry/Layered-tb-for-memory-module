module memory (
  input wire clk,
  input wire wr_en,
  input wire rd_en,
  input wire [3:0] addrr,   // Read address (4 bits for 16 addresses)
  input wire [3:0] addrw,   // Write address (4 bits for 16 addresses)
  input wire [15:0] wdata,  // Data input for writing (16 bits)
  output reg [15:0] rdata   // Data output for reading (16 bits)
);

  // 16-word memory array, each word is 16 bits
  reg [15:0] mem [0:15];

  // Write operation
  always @(posedge clk) begin
    if (wr_en) begin
      mem[addrw] <= wdata;
    end
  end

  // Read operation
  always @(posedge clk) begin
    if (rd_en) begin
      rdata <= mem[addrr];
    end
  end

endmodule