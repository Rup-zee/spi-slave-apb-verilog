//============================================================================
// spi_shift.v - SPI Shift Engine (MSB-first)
// 
// Performs serial-to-parallel (MOSI → rx_data) and parallel-to-serial 
// (tx_data → MISO) conversion. Controlled by the SPI Control FSM via 
// shift_enable and sample_enable signals.
//
// Architecture prepared for LSB-first extension via BIT_ORDER parameter.
//============================================================================

module spi_shift #(
  parameter DATA_WIDTH = 8,
  parameter BIT_ORDER  = 1'b0   // 0 = MSB-first, 1 = LSB-first (future)
) (
  // System interface
  input  wire                     clk,
  input  wire                     rst_n,
  
  // Processor data interface
  input  wire [DATA_WIDTH-1:0]    tx_data,
  input  wire                     tx_load,
  output wire [DATA_WIDTH-1:0]    rx_data,
  output wire                     rx_valid,
  
  // SPI interface
  input  wire                     sclk,
  input  wire                     cs,
  input  wire                     mosi,
  output wire                     miso,
  
  // Control from FSM
  input  wire                     shift_enable,
  input  wire                     sample_enable
);

  //==========================================================================
  // Shift Register (SCLK domain)
  //==========================================================================
  reg [DATA_WIDTH-1:0] shift_reg;
  
  // MISO output selection
  // Future LSB-first: use shift_reg[0] when BIT_ORDER=1
  assign miso = shift_reg[DATA_WIDTH-1];  // MSB-first for now
  
  always @(posedge sclk or negedge rst_n) begin
    if (!rst_n) begin
      shift_reg <= {DATA_WIDTH{1'b0}};
    end
    else if (!cs) begin
      // CS is active low - we are inside a transaction
      if (tx_load) begin
        shift_reg <= tx_data;
      end
      else if (shift_enable) begin
        // Shift left by one, capture MOSI at LSB
        shift_reg <= {shift_reg[DATA_WIDTH-2:0], mosi};
      end
    end
    // When CS is high (inactive), shift_reg holds its value
  end

  //==========================================================================
  // Receive Data Register (System Clock domain)
  // NOTE: This is a Clock Domain Crossing (CDC) path. shift_reg is in SCLK
  // domain, but we sample it into CLK domain when sample_enable is asserted.
  // For a production design, add a 2-FF synchronizer before this register.
  //==========================================================================
  reg [DATA_WIDTH-1:0] rx_data_reg;
  reg                  rx_valid_reg;
  
  assign rx_data  = rx_data_reg;
  assign rx_valid = rx_valid_reg;
  
  always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      rx_data_reg  <= {DATA_WIDTH{1'b0}};
      rx_valid_reg <= 1'b0;
    end
    else begin
      if (sample_enable) begin
        // Latch the complete received word
        rx_data_reg  <= shift_reg;
        rx_valid_reg <= 1'b1;
      end
      else begin
        rx_valid_reg <= 1'b0;
      end
    end
  end

endmodule
