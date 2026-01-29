///////////////////////////////////////////////////////////////////////////////////////////////////
// Company: <Name>
//
// File: CICfilter.v
// File history:
//      <Revision number>: <Date>: <Comments>
//      <Revision number>: <Date>: <Comments>
//      <Revision number>: <Date>: <Comments>
//
// Description: 
//
// <Description here>
//
// Targeted device: <Family::IGLOO> <Die::AGL600V5> <Package::144 FBGA>
// Author: <Name>
//
/////////////////////////////////////////////////////////////////////////////////////////////////// 

//`timescale <time_units> / <precision>

// `default_nettype none // disable implicit nets to reduce some types of bugs

// OSR should be 2^()

module CICfilter #(parameter OSR = 64, parameter BIT = 12) (
    //synopsys template
    input  wire                         RST_S,      // ...
    input  wire                         FADC,       // ...
    input  wire                         FDOWN,      // ...
    input  wire [BIT-1:0]               RECOV_DATA, // ...
    output reg  [BIT+2*$clog2(OSR)-1:0] CIC_OUT // ...

    // output wire  [BIT+2*$clog2(OSR)-1:0] INT_1ST_OUT,
    // output wire  [BIT+2*$clog2(OSR)-1:0] INT_2ND_OUT,
    // output wire  [BIT+2*$clog2(OSR)-1:0] DOWN_DATA_OUT,
    // output wire  [BIT+2*$clog2(OSR)-1:0] DIFF_1ST_OUT
);

// ===========================================================================
// Main Code
//--------------------------------------------------
// CIC
// - Integrator
reg [BIT+2*$clog2(OSR)-1:0] INT_1ST;
reg [BIT+2*$clog2(OSR)-1:0] INT_2ND;
always @(posedge FADC or posedge RST_S) begin
    if (RST_S) begin
        INT_1ST <= 0;
        INT_2ND <= 0;
    end
    else begin
        INT_1ST <= INT_1ST + RECOV_DATA;
        INT_2ND <= INT_2ND + INT_1ST;
    end
end

// - Downsampler
reg [BIT+2*$clog2(OSR)-1:0] DOWN_DATA;
always @(posedge FDOWN or posedge RST_S) begin
    if (RST_S) begin
        DOWN_DATA <= 0;
    end
    else begin
        DOWN_DATA <= INT_2ND;
    end
end

// - Differenciator
reg [BIT+2*$clog2(OSR)-1:0] DOWN_1D;
reg [BIT+2*$clog2(OSR)-1:0] DIFF_1ST;
reg [BIT+2*$clog2(OSR)-1:0] DIFF_1ST_1D;
always @(posedge FDOWN or posedge RST_S) begin
    if (RST_S) begin
        DOWN_1D <= 0;
        DIFF_1ST <= 0;
        CIC_OUT <= 0;
    end
    else begin
        DOWN_1D <= DOWN_DATA;
        // DIFF_1ST <= DOWN_1D - DOWN_DATA;
        // CIC_OUT <= DIFF_1ST - (DOWN_1D - DOWN_DATA);
        DIFF_1ST <= DOWN_DATA - DOWN_1D;
        CIC_OUT <= (DOWN_DATA - DOWN_1D) - DIFF_1ST;
    end
end

// assign INT_1ST_OUT = INT_1ST;
// assign INT_2ND_OUT = INT_2ND;
// assign DOWN_DATA_OUT = DOWN_DATA;
// assign DIFF_1ST_OUT = DIFF_1ST;

endmodule
