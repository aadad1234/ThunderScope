`timescale 1ns / 1ps

module FT2_FIFO_SPI(
		input clk,
		input ft2_txe_n,
		input ft2_rxf_n,
		inout[7:0] ft2_data,
		output ft2_rd_n,
		output ft2_wr_n,
		output fe_sdo,				
		output fe_sclk,
		output fe_cs,
		output fifo_empty,
		output fifo_wr_en,
		output fifo_rd_en
    );

wire spi_done;
//wire fifo_wr_en;
wire fifo_full;
//wire fifo_empty;
wire[7:0] fifo_wr_data;
wire[7:0] fifo_rd_data; 
//wire fifo_rd_en;

wire data_ready;
wire fifo_full_n;
wire status_wr_en;
wire[7:0] status_data;

assign data_ready = ~fifo_empty;
assign fifo_full_n = ~fifo_full;
assign status_wr_en = 1'b0;
assign status_data = 8'h00;

parameter  	IDLE = 1'b0,
				TRANSMIT = 1'b1;

reg state;
reg rst;
reg spi_en;

always @(posedge clk) begin
	rst <= 1'b0;
	spi_en <= 1'b0;
	
	case (state)
		IDLE: 
			if (~fifo_empty) begin
				state <= TRANSMIT;
				spi_en <= 1'b1;
			end
			else
				state <= IDLE;
		TRANSMIT:
			if (fifo_full) begin
				state <= IDLE;
				rst <= 1'b1;
			end
			else if (spi_done) begin
				state <= IDLE;
			end
			else
				state <= TRANSMIT;
	endcase
end

SPI_Transmit 	SPI_Transmit( // TODO: change for FIFO operation
.clk				(clk),
.data				(fifo_rd_data),
.data_ready		(data_ready),
.en				(spi_en),
.data_req		(fifo_rd_en),
.sdo				(fe_sdo),
.sclk				(fe_sclk),
.cs				(fe_cs),
.done				(spi_done)
);

FT2_FIFO			FT2_FIFO(
.clk				(clk),
.rst				(rst),
.wr_en			(fifo_wr_en),
.rd_en			(fifo_rd_en),
.wr_data			(fifo_wr_data),
.full				(fifo_full),
.empty			(fifo_empty),
.rd_data			(fifo_rd_data)
);

FT2_Read_Write	FT2_Read_Write(
.clk				(clk),
.ft2_txe_n		(ft2_txe_n),
.ft2_rxf_n		(ft2_rxf_n),
.rd_en			(fifo_full_n),
.wr_en			(status_wr_en),
.write_data		(status_data),
.ft2_data		(ft2_data),
.ft2_rd_n		(ft2_rd_n),
.ft2_wr_n		(ft2_wr_n),
.read_data		(fifo_wr_data), 
.data_ready		(fifo_wr_en),
.data_sent		() 
);

endmodule
