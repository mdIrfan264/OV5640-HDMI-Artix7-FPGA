module TMDS_Encoder (
    input wire PixelClk,              // Pixel clock (e.g., 25MHz for 640x480)
    input wire aRst,                  // Asynchronous reset
    input wire [7:0] pDataOut,        // 8-bit pixel data
    input wire pC0,                   // Control bit 0 (used during blanking)
    input wire pC1,                   // Control bit 1 (used during blanking)
    input wire pVde,                  // Video data enable

    output reg [9:0] pDataOutRaw      // TMDS encoded 10-bit output
);

// Internal signals
reg [7:0] pDataOut_1;
reg [8:0] q_m_1;
reg [3:0] n1d_1, n1q_m_1, n0q_m_2, n1q_m_2;

reg [8:0] q_m_2;
reg [9:0] q_out_2;
reg [4:0] cnt_t_2, cnt_t_3;
reg signed [4:0] dc_bias_2;

reg pC0_1, pC1_1, pVde_1;
reg pC0_2, pC1_2, pVde_2;

wire cond_balanced_2, cond_not_balanced_2;

// Control tokens (TMDS encoding of HSync/VSync during blanking)
localparam [9:0] kCtlTkn0 = 10'b1101010100;
localparam [9:0] kCtlTkn1 = 10'b0010101011;
localparam [9:0] kCtlTkn2 = 10'b0101010100;
localparam [9:0] kCtlTkn3 = 10'b1010101011;

// --------------------
// Stage 1: Minimize transitions using XOR/XNOR
// --------------------
integer i;
always @(posedge PixelClk or posedge aRst) begin
    if (aRst) begin
        pDataOut_1 <= 8'd0;
        pC0_1 <= 0;
        pC1_1 <= 0;
        pVde_1 <= 0;
        n1d_1 <= 0;
    end else begin
        pDataOut_1 <= pDataOut;
        pC0_1 <= pC0;
        pC1_1 <= pC1;
        pVde_1 <= pVde;
        n1d_1 <= pDataOut[0] + pDataOut[1] + pDataOut[2] + pDataOut[3] +
                 pDataOut[4] + pDataOut[5] + pDataOut[6] + pDataOut[7];
    end
end

reg [8:0] q_m_xor, q_m_xnor;

always @(*) begin
    q_m_xor[0] = pDataOut_1[0];
    for (i = 1; i < 8; i = i + 1)
        q_m_xor[i] = q_m_xor[i-1] ^ pDataOut_1[i];
    q_m_xor[8] = 1'b1;

    q_m_xnor[0] = pDataOut_1[0];
    for (i = 1; i < 8; i = i + 1)
        q_m_xnor[i] = ~(q_m_xnor[i-1] ^ pDataOut_1[i]);
    q_m_xnor[8] = 1'b0;

    q_m_1 = (n1d_1 > 4 || (n1d_1 == 4 && pDataOut_1[0] == 1'b0)) ? q_m_xnor : q_m_xor;
end

always @(*) begin
    n1q_m_1 = q_m_1[0] + q_m_1[1] + q_m_1[2] + q_m_1[3] +
              q_m_1[4] + q_m_1[5] + q_m_1[6] + q_m_1[7];
end

// --------------------
// Stage 2: DC balancing
// --------------------
always @(posedge PixelClk or posedge aRst) begin
    if (aRst) begin
        q_m_2 <= 9'd0;
        n1q_m_2 <= 0;
        n0q_m_2 <= 0;
        pC0_2 <= 0;
        pC1_2 <= 0;
        pVde_2 <= 0;
    end else begin
        q_m_2 <= q_m_1;
        n1q_m_2 <= n1q_m_1;
        n0q_m_2 <= 8 - n1q_m_1;
        pC0_2 <= pC0_1;
        pC1_2 <= pC1_1;
        pVde_2 <= pVde_1;
    end
end

assign cond_balanced_2    = (cnt_t_3 == 0 || n1q_m_2 == 4);
assign cond_not_balanced_2 = ((cnt_t_3 > 0 && n1q_m_2 > 4) ||
                              (cnt_t_3 < 0 && n1q_m_2 < 4));

always @(*) begin
    if (!pVde_2) begin
        case ({pC1_2, pC0_2})
            2'b00: q_out_2 = kCtlTkn0;
            2'b01: q_out_2 = kCtlTkn1;
            2'b10: q_out_2 = kCtlTkn2;
            2'b11: q_out_2 = kCtlTkn3;
        endcase
    end else if (cond_balanced_2 && q_m_2[8] == 1'b0) begin
        q_out_2 = {1'b1, 1'b0, ~q_m_2[7:0]};
    end else if (cond_balanced_2 && q_m_2[8] == 1'b1) begin
        q_out_2 = {1'b1, 1'b1,  q_m_2[7:0]};
    end else if (cond_not_balanced_2) begin
        q_out_2 = {1'b1, q_m_2[8], ~q_m_2[7:0]};
    end else begin
        q_out_2 = {1'b0, q_m_2[8], q_m_2[7:0]};
    end

    // DC Bias
    dc_bias_2 = $signed({1'b0, n0q_m_2}) - $signed({1'b0, n1q_m_2});
end

always @(*) begin
    if (!pVde_2)
        cnt_t_2 = 0;
    else if (cond_balanced_2 && q_m_2[8] == 1'b0)
        cnt_t_2 = cnt_t_3 + dc_bias_2;
    else if (cond_balanced_2 && q_m_2[8] == 1'b1)
        cnt_t_2 = cnt_t_3 - dc_bias_2;
    else if (cond_not_balanced_2)
        cnt_t_2 = cnt_t_3 + {3'b000, q_m_2[8]} + dc_bias_2;
    else
        cnt_t_2 = cnt_t_3 - {3'b000, ~q_m_2[8]} - dc_bias_2;
end

// --------------------
// Stage 3: Output register
// --------------------
always @(posedge PixelClk or posedge aRst) begin
    if (aRst) begin
        cnt_t_3 <= 0;
        pDataOutRaw <= 10'd0;
    end else begin
        cnt_t_3 <= cnt_t_2;
        pDataOutRaw <= q_out_2;
    end
end

endmodule
