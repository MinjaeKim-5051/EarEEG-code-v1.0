///////////////////////////////////////////////////////////////////////////////////////////////////
// Company: <Name>
//
// File: R_L_controller.v
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

module R_L_controller (
   input  wire rst_n,
   input  wire R_L_con,
   input  wire fdata_G,
   input  wire LOAD_G,
   output wire R_L_state
   );

   //==================================================

   reg       r_R_L_state;
   reg       r_token;
   reg [2:0] r_count_Load;
   assign R_L_state = !(r_R_L_state ^ r_token); // 0: Read state, 1: Load state
   
   initial begin
      r_R_L_state = 0;
      r_token = 1'b1;
      r_count_Load = 0;
   end

   always @(posedge fdata_G or negedge rst_n) begin
      if (!rst_n) begin
         r_R_L_state <= 0;
      end

      else begin
         r_R_L_state <= R_L_con;
      end
   end

   always @(posedge LOAD_G or negedge rst_n) begin
      if (!rst_n) begin
         r_token <= 1'b1;
         r_count_Load <= 3'b111;
      end

      else begin
         if (!(&r_count_Load)) begin
            if (r_count_Load == 3'd1) begin
               r_token <= r_token;
               r_count_Load <= r_count_Load + 1'b1;
            end

            else begin
               r_token <= r_token;
               r_count_Load <= r_count_Load + 1'b1;
            end
         end
         
         else begin
            r_token <= ~r_R_L_state;
            r_count_Load <= 1'b1;
         end
      end
   end
endmodule