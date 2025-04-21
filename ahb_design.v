module ahb_design (
    input  wire        HCLK,
    input  wire        HRESETn,
    input  wire        HSEL,
    input  wire        HWRITE,
    output wire        HREADY,
    input  wire [1:0]  HTRANS,
    input  wire [11:0] HADDR,
    input  wire [31:0] HWDATA,
    output reg  [31:0] HRDATA
);

  reg [31:0] mem [0:15];

  // Always ready (no wait states)
  assign HREADY = 1'b1;

  // Valid transfer: selected, non-idle
  wire valid;
  assign valid = HSEL && HTRANS[1]; // Do NOT include HREADY in this condition

  always @(posedge HCLK or negedge HRESETn) begin
    if (!HRESETn) begin
      HRDATA <= 32'h0;
    end else begin
      if (valid) begin
        if (HWRITE)
          mem[HADDR[5:2]] <= HWDATA;
        else
          HRDATA <= mem[HADDR[5:2]];
      end
    end
  end

endmodule
