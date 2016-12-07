`timescale 1ns / 1p
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: james holodnak
// 
// Create Date:    14:25:35 04/26/2016 
// Design Name: 
// Module Name:    mapper90 
// Project Name: 
// Target Devices: 
// Tool versions: 
// Description: 
//
// Dependencies: 
//
// Revision: 
// Revision 0.01 - File Created
// Additional Comments: 
//
//////////////////////////////////////////////////////////////////////////////////
module mapper90(
	input				m2,				//cpu m2
	input				cpu_rw,			//cpu r/w
	input				ppu_rd,			//ppu rd
	input				ppu_wr,			//ppu wr
	inout	[7:0]		data,				//cpu data lines
	input	[15:0]		cpu_addr,		//cpu address lines
	input	[13:0]		ppu_addr,		//ppu address lines
	output	[18:12]		prg_addr,		//prg rom addr lines
	output	[18:10]		chr_addr,		//chr rom addr lines
	output				prg_ce,			//prg rom /ce (/romsel)
	output				chr_ce,			//chr rom /ce
	output				vram_a10,		//mirroring
	output				vram_ce,			//mirroring
	output				irq,				//irq
	output				datadir,
	output	[3:0]		debug,
	input	[3:0]		cfg
	);
	
	wire [1:0] dip = {~cfg[1], ~cfg[2]};
	wire ntctl = ~cfg[3];
//	wire ntctl_soft = ~cfg[0];

	wire write_reg_val;
	assign write_reg_val = (m2 & cpu_addr[15] & ~cpu_rw);	

	wire write_reg_val_lo;
	assign write_reg_val_lo = (m2 & ~cpu_rw & cpu_addr[15:12] == 4'h5);

	reg[7:0]	reg_mul1, reg_mul2, reg_ram;
	reg[6:0]	reg_prg_0, reg_prg_1, reg_prg_2, reg_prg_3;
	reg[15:0]	reg_chr_0, reg_chr_1, reg_chr_2, reg_chr_3;
	reg[15:0]	reg_chr_4, reg_chr_5, reg_chr_6, reg_chr_7;
	reg[15:0]	reg_nt_0, reg_nt_1, reg_nt_2, reg_nt_3;
	reg[7:0]	reg_control_0, reg_control_1, reg_control_2, reg_control_3 = 8'h20;

	reg      reg_irq_enable;
	reg[7:0] reg_irq_mode;
	reg[7:0] reg_irq_xor;
	reg[15:0] reg_irqtotal;

	reg mirroring;
	reg need_irq;

	always @ (negedge write_reg_val)
	begin
		casez({cpu_addr[14:12],cpu_addr[2:0]})
		
			//$8000-$8007
			6'b000_?00: reg_prg_0 = data[6:0];
			6'b000_?01: reg_prg_1 = data[6:0];
			6'b000_?10: reg_prg_2 = data[6:0];
			6'b000_?11: reg_prg_3 = data[6:0];
			
			//$9000-9007
			6'b001_000: reg_chr_0[7:0] = data[7:0];
			6'b001_001: reg_chr_1[7:0] = data[7:0];
			6'b001_010: reg_chr_2[7:0] = data[7:0];
			6'b001_011: reg_chr_3[7:0] = data[7:0];
			6'b001_100: reg_chr_4[7:0] = data[7:0];
			6'b001_101: reg_chr_5[7:0] = data[7:0];
			6'b001_110: reg_chr_6[7:0] = data[7:0];
			6'b001_111: reg_chr_7[7:0] = data[7:0];

			//$A000-A007
			6'b010_000: reg_chr_0[15:8] = data[7:0];
			6'b010_001: reg_chr_1[15:8] = data[7:0];
			6'b010_010: reg_chr_2[15:8] = data[7:0];
			6'b010_011: reg_chr_3[15:8] = data[7:0];
			6'b010_100: reg_chr_4[15:8] = data[7:0];
			6'b010_101: reg_chr_5[15:8] = data[7:0];
			6'b010_110: reg_chr_6[15:8] = data[7:0];
			6'b010_111: reg_chr_7[15:8] = data[7:0];

			//$B000-B007
			6'b011_000: reg_nt_0[7:0] = data[7:0];
			6'b011_001: reg_nt_1[7:0] = data[7:0];
			6'b011_010: reg_nt_2[7:0] = data[7:0];
			6'b011_011: reg_nt_3[7:0] = data[7:0];
			6'b011_100: reg_nt_0[15:8] = data[7:0];
			6'b011_101: reg_nt_1[15:8] = data[7:0];
			6'b011_110: reg_nt_2[15:8] = data[7:0];
			6'b011_111: reg_nt_3[15:8] = data[7:0];

			//$C000-$C007
			6'b100_000: reg_irq_enable = data[0];
			6'b100_001: reg_irq_mode = data[7:0];
			6'b100_010: reg_irq_enable = 1'b0;
			6'b100_011: reg_irq_enable = 1'b1;
			6'b100_100: begin end
			6'b100_101: begin end
			6'b100_110: reg_irq_xor = data[7:0];
			6'b100_111: begin end

			//$D000-$D007
			6'b101_?00: begin
				reg_control_0[7:0] = data[7:0];
				reg_control_0[5] = ntctl;
			end
			6'b101_?01: reg_control_1 = data[7:0];
			6'b101_?10: reg_control_2 = data[7:0];
			6'b101_?11: reg_control_3 = data[7:0];

		endcase
	end

	reg [7:0] dataout;
	wire [15:0] mul_result;

	mul multiplier(m2, 1'b1, 1'b0, reg_mul1, reg_mul2, mul_result);

	always @ (negedge write_reg_val_lo)
	begin
		casez({cpu_addr[11],cpu_addr[2:0]})
			//$5800-$5807
			4'b1_000: reg_mul1[7:0] <= data[7:0];
			4'b1_001: reg_mul2[7:0] <= data[7:0];
			4'b1_011: reg_ram[7:0] <= data[7:0];
		endcase		
	end

	wire [6:0] lastbank;
	reg [6:0] prg_out;
	reg [6:0] prglo_out;

	assign lastbank = reg_control_0[2] ? reg_prg_3 : 7'b111_1111;

	//prg banks
	always @ (*)
	begin

		//8000-FFFF
		casez({cpu_addr[14:13],reg_control_0[1:0]})
		
			//32kb bank
			4'b??_00: prg_out = {lastbank[4:0],cpu_addr[14:13]};
			
			//16kb bank
			4'b?0_01: prg_out = {reg_prg_1[5:0],cpu_addr[13]};
			4'b?1_01: prg_out = {lastbank[5:0],cpu_addr[13]};

			//8kb bank
			4'b00_10: prg_out = reg_prg_0;
			4'b01_10: prg_out = reg_prg_1;
			4'b10_10: prg_out = reg_prg_2;
			4'b11_10: prg_out = lastbank;

			//8kb bank (bit reverse)
			4'b00_11: prg_out = {reg_prg_0[0],reg_prg_0[1],reg_prg_0[2],reg_prg_0[3],reg_prg_0[4],reg_prg_0[5],reg_prg_0[6]};
			4'b01_11: prg_out = {reg_prg_1[0],reg_prg_1[1],reg_prg_1[2],reg_prg_1[3],reg_prg_1[4],reg_prg_1[5],reg_prg_1[6]};
			4'b10_11: prg_out = {reg_prg_2[0],reg_prg_2[1],reg_prg_2[2],reg_prg_2[3],reg_prg_2[4],reg_prg_2[5],reg_prg_2[6]};
			4'b11_11: prg_out = {lastbank[0],lastbank[1],lastbank[2],lastbank[3],lastbank[4],lastbank[5],lastbank[6]};
		endcase

		//6000-7FFF
		case(reg_control_0[1:0])
			2'h0:	prglo_out = (reg_prg_3 * 4) + 3;
			2'h1:	prglo_out = (reg_prg_3 * 2) + 1;
			2'h2:	prglo_out = reg_prg_3;
			2'h3:	prglo_out = {reg_prg_3[0],reg_prg_3[1],reg_prg_3[2],reg_prg_3[3],reg_prg_3[4],reg_prg_3[5],reg_prg_3[6]};
		endcase

	end

	reg [15:0] chr_out;

	always @ (*)
	begin
		casez({reg_control_0[4:3],ppu_addr[12:10]})
		
			//8k bank size
			5'b00_???: chr_out = reg_control_3[5] ? {reg_chr_0[12:0],ppu_addr[12:10]} : {reg_control_3[4:0],reg_chr_0[7:0],ppu_addr[12:10]};

			//4k bank size
			5'b01_??0: chr_out = reg_control_3[5] ? {reg_chr_0[13:0],ppu_addr[11:10]} : {1'b0, reg_control_3[4:0], reg_chr_0[7:0], ppu_addr[11:10]};
			5'b01_??1: chr_out = reg_control_3[5] ? {reg_chr_4[13:0],ppu_addr[11:10]} : {1'b0, reg_control_3[4:0], reg_chr_4[7:0], ppu_addr[11:10]};

			//2k bank size
			5'b10_?00: chr_out = reg_control_3[5] ? {reg_chr_0[14:0],ppu_addr[10]} : {2'b00, reg_control_3[4:0], reg_chr_0[7:0], ppu_addr[10]};
			5'b10_?01: chr_out = reg_control_3[5] ? {reg_chr_2[14:0],ppu_addr[10]} : {2'b00, reg_control_3[4:0], reg_chr_2[7:0], ppu_addr[10]};
			5'b10_?10: chr_out = reg_control_3[5] ? {reg_chr_4[14:0],ppu_addr[10]} : {2'b00, reg_control_3[4:0], reg_chr_4[7:0], ppu_addr[10]};
			5'b10_?11: chr_out = reg_control_3[5] ? {reg_chr_6[14:0],ppu_addr[10]} : {2'b00, reg_control_3[4:0], reg_chr_6[7:0], ppu_addr[10]};

			//1k bank size
			5'b11_000: chr_out = reg_control_3[5] ? reg_chr_0[15:0] : {3'b000, reg_control_3[4:0], reg_chr_0[7:0]};
			5'b11_001: chr_out = reg_control_3[5] ? reg_chr_1[15:0] : {3'b000, reg_control_3[4:0], reg_chr_1[7:0]};
			5'b11_010: chr_out = reg_control_3[5] ? reg_chr_2[15:0] : {3'b000, reg_control_3[4:0], reg_chr_2[7:0]};
			5'b11_011: chr_out = reg_control_3[5] ? reg_chr_3[15:0] : {3'b000, reg_control_3[4:0], reg_chr_3[7:0]};
			5'b11_100: chr_out = reg_control_3[5] ? reg_chr_4[15:0] : {3'b000, reg_control_3[4:0], reg_chr_4[7:0]};
			5'b11_101: chr_out = reg_control_3[5] ? reg_chr_5[15:0] : {3'b000, reg_control_3[4:0], reg_chr_5[7:0]};
			5'b11_110: chr_out = reg_control_3[5] ? reg_chr_6[15:0] : {3'b000, reg_control_3[4:0], reg_chr_6[7:0]};
			5'b11_111: chr_out = reg_control_3[5] ? reg_chr_7[15:0] : {3'b000, reg_control_3[4:0], reg_chr_7[7:0]};

		endcase
	end

	reg [15:0] nt_out;

	always @ (*)
	begin
		casez(ppu_addr[11:10])

			2'b00: nt_out = (reg_control_0[6] | (reg_control_2[7] ^ reg_nt_0[7])) ? reg_nt_0[15:0] : reg_nt_0[0];
			2'b01: nt_out = (reg_control_0[6] | (reg_control_2[7] ^ reg_nt_1[7])) ? reg_nt_1[15:0] : reg_nt_1[0];
			2'b10: nt_out = (reg_control_0[6] | (reg_control_2[7] ^ reg_nt_2[7])) ? reg_nt_2[15:0] : reg_nt_2[0];
			2'b11: nt_out = (reg_control_0[6] | (reg_control_2[7] ^ reg_nt_3[7])) ? reg_nt_3[15:0] : reg_nt_3[0];

		endcase
	end

	reg ppu_addr_12;
	always @ (negedge ppu_rd or posedge ppu_addr[12])
		if(ppu_addr[12])
			ppu_addr_12 = 1'b1;
		else
			ppu_addr_12 = 1'b0;
	
	//write to $C004/$C005/$C002
	wire prescaler_load = m2 & (cpu_rw == 0) & ({cpu_addr[15:12],cpu_addr[2:0]} == 7'b1100_100);
	wire counter_load = m2 & (cpu_rw == 0) & ({cpu_addr[15:12],cpu_addr[2:0]} == 7'b1100_101);
	wire irq_clear = m2 & (cpu_rw == 0) & ({cpu_addr[15:12],cpu_addr[2:0]} == 7'b1100_010);
	reg irq_reset = 1'b0;
	wire irqtotal_load = prescaler_load | counter_load | irq_reset;

	//triggers
	wire m2_clock      = m2           & (reg_irq_mode[1:0] == 2'b00);
	wire ppu_a12_clock = ppu_addr[12] & (reg_irq_mode[1:0] == 2'b01);
	wire ppu_rd_clock  = ~ppu_rd      & (reg_irq_mode[1:0] == 2'b10);
	wire cpu_wr_clock  = m2 & ~cpu_rw & (reg_irq_mode[1:0] == 2'b11);
//	wire prescaler_clock = m2_clock | ppu_a12_clock | ppu_rd_clock | cpu_wr_clock;
	wire prescaler_clock = ppu_addr[12] & (reg_irq_mode[1:0] == 2'b01);
	
	wire irq_count_dn = (reg_irq_mode[7:6] == 2'b10);
	wire irq_count_up = (reg_irq_mode[7:6] == 2'b01);
	wire irq_trigger = prescaler_clock & (reg_irqtotal[15:0] == 16'h0);
	
	wire[7:0] data_next = data[7:0] ^ reg_irq_xor[7:0] ^ (irq_count_up ? 8'hFF : 8'h0);

	//irq prescaler
	always @ (posedge prescaler_clock or posedge irqtotal_load)
	begin
		
		if(irqtotal_load) begin
			if(prescaler_load) begin
				reg_irqtotal[15:0] = reg_irq_mode[2] ? {reg_irqtotal[15:3], data_next[2:0]} : {reg_irqtotal[15:8], data_next[7:0]};
			end
			if(counter_load) begin
				reg_irqtotal[15:0] = reg_irq_mode[2] ? {5'd0, data_next[7:0], reg_irqtotal[2:0]} : {data_next[7:0], reg_irqtotal[7:0]};
			end
		end
		
		else begin
			reg_irqtotal[15:0] = reg_irqtotal[15:0] - 1'b1;
		end

	end
	
	//irq trigger
	always @ (posedge irq_trigger or posedge irq_clear)
	begin
		
		if(irq_clear) begin
			need_irq = 1'b0;
		end
		
		else begin
			need_irq = reg_irq_enable;
		end
	
	end

	always @ (*)
	begin
		begin
			case(reg_control_1[1:0])
				0: mirroring = ppu_addr[10];
				1: mirroring = ppu_addr[11];
				2: mirroring = 1'b0;
				3: mirroring = 1'b1;
			endcase
		end
	end

	wire usentrom = ntctl && ppu_addr[13] && (
		(ppu_addr[11:10] == 2'd0) ? (reg_control_0[6] | (reg_control_2[7] ^ reg_nt_0[7])) :
		(ppu_addr[11:10] == 2'd1) ? (reg_control_0[6] | (reg_control_2[7] ^ reg_nt_1[7])) :
		(ppu_addr[11:10] == 2'd2) ? (reg_control_0[6] | (reg_control_2[7] ^ reg_nt_2[7])) :
		(ppu_addr[11:10] == 2'd3) ? (reg_control_0[6] | (reg_control_2[7] ^ reg_nt_3[7])) :
		1'b0);
	wire ntread = ~ppu_rd & ppu_addr[13];
	wire prgloread = reg_control_0[7] & m2 & cpu_rw & (cpu_addr[15:13]==3'b011);
	wire prghiread = m2 & cpu_rw & cpu_addr[15];
	assign prg_addr[18:12] = {prgloread ? prglo_out[5:0] : prg_out[5:0], cpu_addr[12]};
	assign prg_ce = ~(prghiread | prgloread);

	assign chr_addr[18:10] = usentrom ? nt_out[8:0] : chr_out[8:0];
	assign chr_ce = usentrom ? 1'b0 : ~(~ppu_rd & ~ppu_addr[13]);
	assign vram_ce = usentrom ? 1'b1 : ~ppu_addr[13];
	assign vram_a10 = ntctl ? nt_out[0] : mirroring;
	assign irq = ~need_irq;
	
	wire regread = m2 & cpu_rw & (cpu_addr[15:12]==4'h5);
	
	wire [3:0] read_addr = {cpu_addr[11],cpu_addr[2:0]};

	assign datadir = regread ? 1'b1 : 1'b0;
	assign data = ~regread ? 8'bZZZZZZZZ :
		read_addr == 4'b0000 ? {dip[1:0],6'd0} :
		read_addr == 4'b1000 ? mul_result[7:0] :
		read_addr == 4'b1001 ? mul_result[15:8] :
		read_addr == 4'b1011 ? reg_ram[7:0] :		
		{4'b1111,read_addr};

endmodule
