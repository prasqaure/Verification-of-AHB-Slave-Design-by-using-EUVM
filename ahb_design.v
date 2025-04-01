`timescale 1ns / 1ps

module ahb_slave #(
    parameter DW = 32,  // Data Width
    parameter AW = 32   // Address Width
)(
    input  logic         HCLK,      // Clock
    input  logic         HRESETn,   // Reset (active low)
    input  logic         HSEL,      // Slave select
    input  logic [AW-1:0] HADDR,    // Address
    input  logic         HWRITE,    // Write enable
    input  logic [2:0]   HSIZE,     // Transfer size
    input  logic [2:0]   HBURST,    // Burst type
    input  logic [1:0]   HTRANS,    // Transfer type
    input  logic [DW-1:0] HWDATA,   // Write data
    output logic [DW-1:0] HRDATA,   // Read data
    output logic         HREADY,    // Ready signal
    output logic         HRESP      // Response signal
);

    logic [DW-1:0] mem [0:15]; // Simple 16-word memory

    always_ff @(posedge HCLK or negedge HRESETn) begin
        if (!HRESETn) begin
            HREADY <= 1'b0;
            HRDATA <= 32'b0;
            HRESP  <= 1'b0;
        end else begin
            if (HSEL && HTRANS[1]) begin
                HREADY <= 1'b1;  // Indicate ready for next transfer
                HRESP  <= 1'b0;  // No error
                
                if (HWRITE) begin
                    mem[HADDR[3:0]] <= HWDATA;  // Write operation
                end else begin
                    HRDATA <= mem[HADDR[3:0]];  // Read operation
                end
            end else begin
                HREADY <= 1'b0;
            end
        end
    end

endmodule
// iverilog -g2012 -o ahb_tb ahb_design.v
