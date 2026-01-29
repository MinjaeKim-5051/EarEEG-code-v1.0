///////////////////////////////////////////////////////////////////////////////////////////////////
// Company: <Name>
//
// File: read_sig_generator.v
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

`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2023/01/10 16:13:29
// Design Name: 
// Module Name: read_sig_generator
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////

module read_sig_generator(
    input wire enable,
    input wire f_data_clk,
    input wire adc_clk,
    output wire read_sig
    );
    
    reg read;
    reg [3:0] count;        
    assign read_sig = read;
    
    initial begin 
        read <= 1'b0;
        count <= 4'b0000;
    end 
    
    always @(negedge f_data_clk) begin
        if(enable && ~adc_clk) begin
            if(count < 4'b0111) begin
                count <= count + 1;
            end else if (count == 4'b0111) begin
                read <= 1'b1;        
            end 
        end else if(adc_clk || ~enable) begin
            read <= 1'b0;
            count <= 4'b0000;
        end 
    end
       
endmodule