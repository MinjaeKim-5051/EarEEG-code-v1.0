///////////////////////////////////////////////////////////////////////////////////////////////////
// Company: <Name>
//
// File: Deserializer.v
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

module Deserializer(
    input wire data_clk,
    input wire data,
    input wire read,

    output wire [3:0] de_out
);

    reg [3:0] cnt;
    reg [3:0] de_result;

    always @(posedge read) begin
        cnt <= 3'b000;
    end

    always @(posedge data_clk) begin
        if (cnt == 1) de_result[3] <= data;
        if (cnt == 5) de_result[2] <= data;
        if (cnt == 9) de_result[1] <= data;
        if (cnt == 13) de_result[0] <= data;
        cnt = cnt + 1;
    end

    assign de_out = de_result;

endmodule