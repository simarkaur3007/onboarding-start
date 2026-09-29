module spi_peripheral (
    input  wire clk,
    input  wire rst_n,
    input  wire SCLK,
    input  wire COPI,
    input  wire nCS,

    output reg [7:0] en_reg_out_7_0,
    output reg [7:0] en_reg_out_15_8,
    output reg [7:0] en_reg_pwm_7_0,
    output reg [7:0] en_reg_pwm_15_8,
    output reg [7:0] pwm_duty_cycle
);

reg SCLK_sync1;
reg SCLK_sync2;

reg COPI_sync1;
reg COPI_sync2;

reg nCS_sync1;
reg nCS_sync2;

reg SCLK_prev;
reg nCS_prev;

reg [15:0] shift_reg;
reg [4:0] bit_count;

localparam [6:0] MAX_ADDRESS = 7'h04;

wire SCLK_rising = SCLK_sync2 && !SCLK_prev;

wire nCS_falling = !nCS_sync2 && nCS_prev;
wire nCS_rising  = nCS_sync2 && !nCS_prev;


always @(posedge clk or negedge rst_n) begin

    // RESET SECTION
    if (!rst_n) begin

        en_reg_out_7_0   <= 8'h00;
        en_reg_out_15_8  <= 8'h00;
        en_reg_pwm_7_0   <= 8'h00;
        en_reg_pwm_15_8  <= 8'h00;
        pwm_duty_cycle   <= 8'h00;
        SCLK_sync1 <= 1'b0;
        SCLK_sync2 <= 1'b0;

        COPI_sync1 <= 1'b0;
        COPI_sync2 <= 1'b0;

        nCS_sync1 <= 1'b1;
        nCS_sync2 <= 1'b1;

        SCLK_prev <= 1'b0;
        nCS_prev  <= 1'b1;

        shift_reg <= 16'b0;
        bit_count <= 5'b0;

    // NORMAL SECTION
    end else begin
    SCLK_sync1 <= SCLK;
    SCLK_sync2 <= SCLK_sync1;

    COPI_sync1 <= COPI;
    COPI_sync2 <= COPI_sync1;

    nCS_sync1 <= nCS;
    nCS_sync2 <= nCS_sync1;

    SCLK_prev <= SCLK_sync2;
    nCS_prev  <= nCS_sync2;

    if (nCS_falling) begin
        shift_reg <= 16'b0;
        bit_count <= 5'b0;
    end
    else if (!nCS_sync2 && SCLK_rising && bit_count < 16) begin
        shift_reg <= {shift_reg[14:0], COPI_sync2};
        bit_count <= bit_count + 1'b1;
    end
   if (nCS_rising) begin
    if (bit_count == 16 && shift_reg[15] == 1'b1) begin
        if (shift_reg[14:8] <= MAX_ADDRESS) begin
            case (shift_reg[14:8])

                7'h00: en_reg_out_7_0   <= shift_reg[7:0];
                7'h01: en_reg_out_15_8  <= shift_reg[7:0];
                7'h02: en_reg_pwm_7_0   <= shift_reg[7:0];
                7'h03: en_reg_pwm_15_8  <= shift_reg[7:0];
                7'h04: pwm_duty_cycle   <= shift_reg[7:0];

                default: begin
                    // Ignore invalid address
                end

            endcase
        end
    end
end


// EDGE DETECTION


endmodule
