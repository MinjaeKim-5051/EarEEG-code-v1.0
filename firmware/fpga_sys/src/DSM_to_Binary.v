///////////////////////////////////////////////////////////////////////////////////////////////////
// Company: <Name>
//
// File: DSM_to_Binary.v
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

module DSM_to_Binary(
    input wire clk,
    input wire reset,
    input wire in_stream,
    input wire start_trig,

    output wire [7:0] scale_out,
    output wire [11:0] out_data,
    output wire signed [13:0] out_check
    // output wire [11:0] out_data_pos

);
    
    reg [7:0] scale;
    reg [4:0] scale_cali;
    
    reg signed [13:0] out_result_Check;

    reg [11:0] out_result;
    // reg [11:0] out_result_pos;
    assign out_data = out_result;
    assign out_check = out_result_Check;
    // assign out_data_pos = out_result_pos;
    reg start;
    reg scaled;

    localparam min_scale = 8'b00000001;
    localparam max_scale = 8'b10000000;

    reg signed [12:0] max_value;
    reg signed [12:0] min_value;

    assign scale_out = scale;

    wire signed [13:0] minus_check;
    wire signed [13:0] plus_check;

    always @(posedge start_trig or posedge reset) begin
        if (reset) begin
            // start <= 0; // use when there is a start_trig
            start <= 1; // use when there is no start_trig
        end
        if (start_trig) begin
            start <= 1;
        end
    end
    

    always @(posedge clk or posedge reset) begin
        if (reset) begin
            scale = min_scale;
            scale_cali = 5'b10100;
            scaled <= 1'b0;
            max_value <= 13'sb0_1111_1111_1111;   //    decimal 2047 + 2048
            min_value <= 13'sb0_0000_0000_0000;   //    decimal -2048 + 2048            
        end

        else begin
            if (start) begin
                scale_cali = (scale_cali << 1) | in_stream;  
                if ((scale_cali[0] == scale_cali[1]) & (scale_cali[1] == scale_cali[2]) & (scale_cali[2] == scale_cali[3]) & (scale_cali[3] == scale_cali[4])) begin
                    if (scale < max_scale) begin
                        scale = (scale << 1);
                        // scale = min_scale;
                    end
                end 
                else if ((scale_cali[0] != scale_cali[1]) & (scale_cali[1] != scale_cali[2])) begin
                    if (scale > min_scale) begin
                        scale = (scale >> 1);
                        // scale = min_scale;
                    end
                end
                scaled <= 1'b1;
                out_result_Check <= out_result;
                
            end
        end
    end

    assign minus_check = out_result_Check - scale;
    assign plus_check = out_result_Check + scale;

    always @(negedge clk or posedge reset) begin
        if (reset) begin
            out_result = 12'b1000_0000_0000;
            // out_result_pos <= 0;
        end

        else if (start) begin
            if (scaled) begin
                if (in_stream) begin
                    if (plus_check < max_value) begin
                        out_result = out_result + scale;
                    end
                    else begin
                        out_result = out_result;
                    end
                end

                else if (~in_stream) begin
                    if (minus_check >= min_value) begin
                        out_result = out_result - scale;
                    end
                    else begin
                        out_result = out_result;
                    end
                end

                // -0.5 ~ 0.5 ==> 0 ~ 1
                //if (out_result[11] == 0) begin
                  //  out_result_pos <= {1'b1, out_result[10:0]};
                //end
                //else if (out_result[11] == 1) begin
                  //  out_result_pos <= 12'b0111_1111_1111 - (~out_result);
                //end
            end
        end
    end

    
endmodule
