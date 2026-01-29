///////////////////////////////////////////////////////////////////////////////////////////////////
// Company: <Name>
//
// File: Deserializer_16to4.v
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

module Deserializer_16to4(
    input wire data_clk,
    input wire [15:0] data16,
    input wire read,
    input wire reset,

    output wire [3:0] data4
);

    reg [3:0] de_result;
    reg [1:0] cnt;
    reg active;
    

    always @(posedge data_clk or posedge reset) begin
        if (reset) begin
            cnt <= 0;
            active <= 0;
        end
    
        else if (read) begin
            cnt <= cnt + 1;
            active <= 0;
        end
        
        else if (cnt==1) begin
            active <= 1;
            cnt <= cnt + 1;
        end
        
        else if (cnt == 2) begin
            active <= 0;
            cnt <= 0;
        end
    end

    always @(negedge active or posedge reset) begin
        if (reset) begin
            de_result <= 0;
        end
        else begin
            de_result[3] <= data16[13];
            de_result[2] <= data16[9];
            de_result[1] <= data16[5];
            de_result[0] <= data16[1];
        end
    end

    assign data4 = de_result;

endmodule
