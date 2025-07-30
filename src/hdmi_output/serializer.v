// OutputSERDES.v
// Converts parallel 10-bit TMDS data to high-speed serial differential output
// Serializer
module OutputSERDES #(
    parameter kParallelWidth = 10
)(
    input  wire              PixelClk,     // TMDS clock x1 (CLKDIV)
    input  wire              SerialClk,    // TMDS clock x5 (CLK)
    input  wire              aRst,         // Asynchronous reset
    input  wire [kParallelWidth-1:0] pDataOut, // 10-bit TMDS encoded data
    output wire              sDataOut_p,   // TMDS differential output +
    output wire              sDataOut_n    // TMDS differential output -
);

    wire sDataOut;
    wire ocascade1, ocascade2;
    wire [13:0] pDataOut_q;

    // Map LSB first for OSERDES2 (D1 is transmitted first)
    genvar i;
    generate
        for (i = 0; i < kParallelWidth; i = i + 1) begin : SliceOSERDES_q
            assign pDataOut_q[13 - i] = pDataOut[i];
        end
    endgenerate

    // Differential output buffer for TMDS
    OBUFDS #(
        .IOSTANDARD("TMDS_33")
    ) OutputBuffer (
        .O (sDataOut_p),
        .OB(sDataOut_n),
        .I (sDataOut)
    );

    // Master serializer (upper 6 bits)
    OSERDESE2 #(
        .DATA_RATE_OQ("DDR"),
        .DATA_RATE_TQ("SDR"),
        .DATA_WIDTH    (kParallelWidth),
        .TRISTATE_WIDTH(1),
        .TBYTE_CTL     ("FALSE"),
        .TBYTE_SRC     ("FALSE"),
        .SERDES_MODE   ("MASTER")
    ) SerializerMaster (
        .OQ       (sDataOut),
        .CLK      (SerialClk),
        .CLKDIV   (PixelClk),
        .RST      (aRst),
        .OCE      (1'b1),
        .D1       (pDataOut_q[13]),
        .D2       (pDataOut_q[12]),
        .D3       (pDataOut_q[11]),
        .D4       (pDataOut_q[10]),
        .D5       (pDataOut_q[9]),
        .D6       (pDataOut_q[8]),
        .D7       (pDataOut_q[7]),
        .D8       (pDataOut_q[6]),
        .SHIFTIN1 (ocascade1),
        .SHIFTIN2 (ocascade2),
        .SHIFTOUT1(),
        .SHIFTOUT2(),
        .T1       (1'b0), .T2(1'b0), .T3(1'b0), .T4(1'b0),
        .TBYTEIN  (1'b0),
        .TCE      (1'b0),
        .TFB      (),
        .TQ       (),
        .TBYTEOUT (),
        .OFB      ()
    );

    // Slave serializer (lower 4 bits)
    OSERDESE2 #(
        .DATA_RATE_OQ("DDR"),
        .DATA_RATE_TQ("SDR"),
        .DATA_WIDTH    (kParallelWidth),
        .TRISTATE_WIDTH(1),
        .TBYTE_CTL     ("FALSE"),
        .TBYTE_SRC     ("FALSE"),
        .SERDES_MODE   ("SLAVE")
    ) SerializerSlave (
        .OQ       (),
        .CLK      (SerialClk),
        .CLKDIV   (PixelClk),
        .RST      (aRst),
        .OCE      (1'b1),
        .D1       (1'b0),
        .D2       (1'b0),
        .D3       (pDataOut_q[5]),
        .D4       (pDataOut_q[4]),
        .D5       (pDataOut_q[3]),
        .D6       (pDataOut_q[2]),
        .D7       (pDataOut_q[1]),
        .D8       (pDataOut_q[0]),
        .SHIFTIN1 (1'b0),
        .SHIFTIN2 (1'b0),
        .SHIFTOUT1(ocascade1),
        .SHIFTOUT2(ocascade2),
        .T1       (1'b0), .T2(1'b0), .T3(1'b0), .T4(1'b0),
        .TBYTEIN  (1'b0),
        .TCE      (1'b0),
        .TFB      (),
        .TQ       (),
        .TBYTEOUT (),
        .OFB      ()
    );

endmodule
