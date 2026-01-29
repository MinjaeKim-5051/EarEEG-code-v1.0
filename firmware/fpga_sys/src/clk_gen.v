///////////////////////////////////////////////////////////////////////////////////////////////////
// Company: <Name>
//
// File: clk_gen.v
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
/* ================================================================
Module Name: clk_gen()
===================================================================
This module
- generates CLKs based on sys_clk
================================================================ */
module clk_gen (
   // in-out for interface and basic system
   input  wire       sys_clk,  // 200MHz system clock
   input  wire       rst_n,    // reset active low
   input  wire       R_L_con,  // READ_G?? LOAD_G?? ????????? ???? ???
   output wire [5:0] new_clks, // generated clocks
                               // [0] fdata_G (1024kHz)
                               // [1] LOAD_G (duty ???, on/off gate ????)
                               // [2] READ_G (64kHz, duty ???, on/off gate ????)
                               // [3] fch_G (64kHz)
                               // [4] fadc_G (64kHz)
                               // [5] fdown (CIC)
   output wire       R_L_state
   );

   // Generate sub_CLKs (counters)
   reg [5:0] r_new_clks; // 200MHz
   reg [7:0] r_count98; // 1024kHz (~1020kHz)
   reg [3:0] r_count8; // 128kHz (~127.5kHz)
   reg [4:0] r_count16; // 64kHz (~63.75kHz)
   reg r_count1;
   reg [6:0] r_count64;

   //==================================================
   // Clock generation
   //--------------------------------------------------
   // Control signal
   R_L_controller m_R_L_controller(
      .rst_n(rst_n),
      .R_L_con(R_L_con),
      .fdata_G(r_new_clks[0]),
      .LOAD_G(r_new_clks[1]),
      .R_L_state(R_L_state)
   );

   assign new_clks = r_new_clks;

   initial begin
      r_new_clks = 0;
      r_count98 = 0;
      r_count8 = 0;
      r_count16 = 0;
      r_count1 = 0;

      r_count64 = 0;
   end

   // always @(posedge sys_clk) begin // 1024kHz
         // // fdata_G (always on)
         // if (r_count98 == 7'd98) begin
            // r_count98 <= 7'd1;
            // r_new_clks[0] <= ~r_new_clks[0];
         // end
         // else begin
            // r_count98 <= r_count98 + 1'b1;
         // end
   //end

   always @(posedge sys_clk) begin // 1024kHz
         // fdata_G (always on)
         if (r_count1 == 1'd1) begin
            r_count1 <= 1'd0;
            r_new_clks[0] <= ~r_new_clks[0];
         end
         else begin
            r_count1 <= r_count1 + 1'b1;
            r_new_clks[0] <= ~r_new_clks[0];
         end
   end

   always @(negedge r_new_clks[0] or negedge rst_n) begin
      if (!rst_n) begin
         r_new_clks[4:1] <= 0;
         r_count8 <= 0;
         r_count16 <= 0;
      end

      else begin
         if (R_L_state) begin
            // LOAD_G
            if (r_count8 == 4'd8) begin
               r_count8 <= r_count8 + 1'b1;
               r_new_clks[1] <= ~r_new_clks[1];
            end
            else if (r_count8 == 4'd9) begin
               r_count8 <= 4'd2;
               r_new_clks[1] <= ~r_new_clks[1];
            end
            else begin
               r_count8 <= r_count8 + 1'b1;
            end

            // READ_G, fch_G, fadc_G
            r_count16 <= 0;
            r_new_clks[4:2] <= 0;
         end

         else begin
            // LOAD_G
            r_count8 <= 0;
            r_new_clks[1] <= 0;
         
            // READ_G, fch_G, fadc_G
            if (r_count16 == 4'd8) begin
               r_count16 <= r_count16 + 1'b1;
               r_new_clks[2] <= ~r_new_clks[2];
               r_new_clks[4:3] <= ~r_new_clks[4:3];
            end
            else if (r_count16 == 4'd9) begin
               r_count16 <= r_count16 + 1'b1;
               r_new_clks[2] <= ~r_new_clks[2];
            end
            else if (r_count16 == 5'd16) begin
               r_count16 <= r_count16 + 1'b1;
               r_new_clks[4:3] <= ~r_new_clks[4:3];
            end
            else if (r_count16 == 5'd17) begin
               r_count16 <= 2'd2;
            end
            else begin
               r_count16 <= r_count16 + 1'b1;
            end
         end
      end
   end

    always @(posedge r_new_clks[4] or negedge rst_n) begin
        if (!rst_n) begin
            r_new_clks[5] <= 0;
            r_count64 <= 0;
        end
        else begin
            if (r_count64 == 0) begin
               r_count64 <= r_count64 + 1'b1;
               r_new_clks[5] <= ~r_new_clks[5];
            end
            if (r_count64 == 7'd32) begin
               r_count64 <= r_count64 + 1'b1;
               r_new_clks[5] <= ~r_new_clks[5];
            end
            else if (r_count64 == 7'd64) begin
               r_count64 <= 1;
               r_new_clks[5] <= ~r_new_clks[5];
            end
            else begin
               r_count64 <= r_count64 + 1'b1;
            end
        end
   end

endmodule