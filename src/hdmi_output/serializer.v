module OutputSERDES #(
    parameter kParallelWidth = 10  // TMDS uses 10-bit encoding
)(
    input  wire        PixelClk,    // 1x TMDS clock (e.g., 25 MHz)
    input  wire        SerialClk,   // 5x TMDS clock (e.g., 125 MHz)
    input  wire        aRst,        // asynchronous reset

    input  wire [kParallelWidth-1:0] pDataOut, // Parallel 10-bit TMDS input
    output wire       sDataOut_p,   // TMDS differential positive
    output wire       sDataOut_n    // TMDS differential negative
);

// Internal signals
wire        sDataOut;
wire        ocascade1, ocascade2;
wire [13:0] pDataOut_q; // Bit-reversed data for OSERDESE2

//-------------------------------------
// Bit-reversal for OSERDESE2 D1–D8
//-------------------------------------
genvar i;
generate
    for (i = 0; i < kParallelWidth; i = i + 1) begin : BitReverse
        assign pDataOut_q[14 - i - 1] = pDataOut[i];
    end
endgenerate

//-------------------------------------
// TMDS differential buffer (OBUFDS)
//-------------------------------------
OBUFDS #(
    .IOSTANDARD("TMDS_33")
) TMDS_OBUFDS (
    .I(sDataOut),
    .O(sDataOut_p),
    .OB(sDataOut_n)
);

//-------------------------------------
// Master OSERDESE2 (Bits D1 to D8)
//-------------------------------------
OSERDESE2 #(
    .DATA_RATE_OQ("DDR"),
    .DATA_RATE_TQ("SDR"),
    .DATA_WIDTH(kParallelWidth),
    .TRISTATE_WIDTH(1),
    .TBYTE_CTL("FALSE"),
    .TBYTE_SRC("FALSE"),
    .SERDES_MODE("MASTER")
) OSERDES_Master (
    .OQ(sDataOut),
    .OFB(),
    .SHIFTOUT1(),
    .SHIFTOUT2(),
    .TBYTEOUT(),
    .TFB(),
    .TQ(),
    .CLK(SerialClk),
    .CLKDIV(PixelClk),
    .D1(pDataOut_q[13]),
    .D2(pDataOut_q[12]),
    .D3(pDataOut_q[11]),
    .D4(pDataOut_q[10]),
    .D5(pDataOut_q[9]),
    .D6(pDataOut_q[8]),
    .D7(pDataOut_q[7]),
    .D8(pDataOut_q[6]),
    .OCE(1'b1),
    .RST(aRst),
    .SHIFTIN1(ocascade1),
    .SHIFTIN2(ocascade2),
    .T1(1'b0),
    .T2(1'b0),
    .T3(1'b0),
    .T4(1'b0),
    .TBYTEIN(1'b0),
    .TCE(1'b0)
);

//-------------------------------------
// Slave OSERDESE2 (Bits D3–D8)
//-------------------------------------
OSERDESE2 #(
    .DATA_RATE_OQ("DDR"),
    .DATA_RATE_TQ("SDR"),
    .DATA_WIDTH(kParallelWidth),
    .TRISTATE_WIDTH(1),
    .TBYTE_CTL("FALSE"),
    .TBYTE_SRC("FALSE"),
    .SERDES_MODE("SLAVE")
) OSERDES_Slave (
    .OQ(),
    .OFB(),
    .SHIFTOUT1(ocascade1),
    .SHIFTOUT2(ocascade2),
    .TBYTEOUT(),
    .TFB(),
    .TQ(),
    .CLK(SerialClk),
    .CLKDIV(PixelClk),
    .D1(1'b0),
    .D2(1'b0),
    .D3(pDataOut_q[5]),
    .D4(pDataOut_q[4]),
    .D5(pDataOut_q[3]),
    .D6(pDataOut_q[2]),
    .D7(pDataOut_q[1]),
    .D8(pDataOut_q[0]),
    .OCE(1'b1),
    .RST(aRst),
    .SHIFTIN1(1'b0),
    .SHIFTIN2(1'b0),
    .T1(1'b0),
    .T2(1'b0),
    .T3(1'b0),
    .T4(1'b0),
    .TBYTEIN(1'b0),
    .TCE(1'b0)
);

endmodule
