///////////////////////////////////////////////////////////////////////////////////////////////////
// Company: <Name>
//
// File: takeABS.v
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

// input b/w 13'sb1_0000_0000_0001(-4095) ~ 13'sb0_1111_1111_1111_1111(4095)
module takeABS #(parameter bitnum = 13) ( 
    input wire signed [bitnum-1:0] dataIn, 
    output wire [bitnum-1-1:0] dataOut
);

    wire [bitnum-1:0] dataIn_noSign;

    assign dataIn_noSign = dataIn;
    assign dataOut = dataIn_noSign[bitnum-1] ? (~dataIn_noSign + 1'b1) : dataIn_noSign;

endmodule
