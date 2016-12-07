`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date:    13:18:39 07/05/2016 
// Design Name: 
// Module Name:    nanjing 
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
module nanjing(
	input					m2,				//cpu m2
	input					cpu_rw,			//cpu r/w
	inout 	[7:0] 	cpu_data,		//cpu data lines
	input		[15:0]	cpu_addr,		//cpu address lines
	input		[13:12]	ppu_addr,		//ppu address lines
	output	[20:15]	prg_addr,		//prg rom addr lines
	output				prg_oe,			//prg rom /ce (/romsel)
	output				ram_ce,			//wram /ce
	output				ram_oe,			//wram /oe
	output				ram_we,			//wram /we
	output				cpu_dir,			//cpu data direction
	input					ppu_rd,			//ppu_rd
	output				vram_a12			//vram banking
);

	reg [5:0] prg = 8'hF;
	reg [7:0] security;
	reg [7:0] strobe;
	reg vramreg;
	reg trigger = 1'b0;

	wire write_reg;
	assign write_reg = (m2 & ~cpu_rw & (cpu_addr[15:12] == 4'h5));

	always @ (negedge write_reg)
	begin

		case(cpu_addr[9:8])

			//$5000
			2'h0: begin
				prg[3:0] = cpu_data[3:0];
				vramreg = cpu_data[7];				
			end

			//$5200
			2'h2: begin
				prg[5:4] = cpu_data[1:0];
			end

			//$5100
			2'h1: begin
				if(cpu_addr[0]) begin
					if(strobe && !cpu_data)
						trigger = ~trigger;
					strobe[7:0] = cpu_data[7:0];
				end
				else begin
					if(cpu_data[7:0] == 8'd6) begin
						prg[5:0] = 4'd3;
					end					
				end
			end
			
			//$5300
			2'h3: begin
				security[7:0] = cpu_data[7:0];
			end

		endcase

	end

	wire romread = m2 & cpu_rw & cpu_addr[15];
	wire regread = m2 & cpu_rw & (cpu_addr[15:12] == 4'h5);
	wire ramread = m2 & cpu_rw & (cpu_addr[15:13] == 3'h3);
	wire ramwrite = m2 & ~cpu_rw & (cpu_addr[15:13] == 3'h3);

	wire [3:0] read_addr = cpu_addr[10:8];
	assign ram_oe = ~ramread;
	assign ram_ce = ~(ramread | ramwrite);
	assign ram_we = ~ramwrite;
	assign prg_oe = ~romread;
	assign cpu_dir = ~romread;
	assign cpu_data = ~regread ? 8'bZZZZZZZZ :
		read_addr == 3'd1 ? security[7:0] :
		read_addr == 3'd5 ? security[7:0] & (trigger ? 8'hFF : 8'h00) :
		read_addr == 3'd0 ? 8'h04 :
		read_addr == 3'd7 ? prg :
		8'hDB;
	assign prg_addr[20:15] = prg[5:0];

	reg ppu_mapper_163_latch;
	reg new_screen_clear, new_screen;
	reg [7:0] ppu_rd_hi_time;
	reg irq_scanline2_clear, irq_scanline2_out;
	reg [8:0] scanline, irq_scanline2_line;
	reg [7:0] ppu_nt_read_count;
	reg irq_scanline2_enabled;

	assign vram_a12 = vramreg ? ppu_mapper_163_latch : ppu_addr[12];
	
// V-blank detector	
	always @ (negedge m2, negedge ppu_rd)
	begin
		if (~ppu_rd) begin
			ppu_rd_hi_time = 0;
			if (new_screen_clear) new_screen = 0;
		end 
		else if (ppu_rd_hi_time < 4'b1111) begin
			ppu_rd_hi_time = ppu_rd_hi_time + 1'b1;
		end 
		else
			new_screen = 1;
	end	
	
	// Scanline counter
	always @ (negedge ppu_rd)
	begin	
		if (irq_scanline2_clear)
			irq_scanline2_out = 0;
		if (~new_screen && new_screen_clear)
			new_screen_clear = 0;
		if (new_screen & ~new_screen_clear) begin
			scanline = 0;			
			new_screen_clear = 1;
			ppu_mapper_163_latch = 0;
		end
		else if (ppu_addr[13:12] == 2'b10) begin
			if (ppu_nt_read_count < 3) begin
				ppu_nt_read_count = ppu_nt_read_count + 1'b1;
			end
			else begin
				scanline = scanline + 1'b1;
				if (irq_scanline2_enabled && scanline == irq_scanline2_line+1)
					irq_scanline2_out = 1;
				if (scanline == 129)
					ppu_mapper_163_latch = 1;
			end
		end
		else
			ppu_nt_read_count = 0;
	end

/*
// V-blank detector	
	always @ (negedge m2, negedge ppu_rd)
	begin
		if (~ppu_rd)
		begin
			ppu_rd_hi_time = 0;
			if (new_screen_clear)
				new_screen = 0;
		end 
		else if (ppu_rd_hi_time < 4'b1111) begin
			ppu_rd_hi_time = ppu_rd_hi_time + 1'b1;
		end
		else
			new_screen = 1;
	end	

	always @ (negedge ppu_rd)
	begin	
		if (irq_scanline2_clear)
			irq_scanline2_out = 0;

		if (~new_screen && new_screen_clear)
			new_screen_clear = 0;

		if (new_screen & ~new_screen_clear)	begin
			scanline = 0;			
			new_screen_clear = 1;
			ppu_mapper_163_latch = 0;
		end

		else if (ppu_addr[13:12] == 2'b10)	begin

			if (ppu_nt_read_count < 3)	begin
				ppu_nt_read_count = ppu_nt_read_count + 1'b1;
			end

			else begin
				scanline = scanline + 1'b1;
				if (irq_scanline2_enabled && scanline == irq_scanline2_line+1)
					irq_scanline2_out = 1;
				if (scanline == 129)
					ppu_mapper_163_latch = 1;
			end

		end

		else
			ppu_nt_read_count = 0;
	end*/

endmodule
