`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date:    13:28:02 07/05/2016 
// Design Name: 
// Module Name:    mapper_top 
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
module mapper_top(
	input					m2,				//cpu m2
	input					cpu_rw,			//cpu r/w
	input					romsel_n,
	inout 	[7:0] 	cpu_data,		//cpu data lines
	input		[14:0]	cpu_addr,		//cpu address lines
	input		[13:12]	ppu_addr,		//ppu address lines
	output	[20:15]	prg_addr,		//prg rom addr lines
	output				prg_oe,			//prg rom /oe
	output				ram_ce,			//wram /ce
	output				ram_oe,			//wram /oe
	output				ram_we,			//wram /we
	output				cpu_dir,			//cpu data direction
	input					ppu_rd,			//ppu_rd
	output				vram_a12			//vram banking
);

/*	wire clk_ppu_rd;
	wire clk_m2;
	wire buf_cpu_rw;

	IBUFG b00(.I(ppu_rd), .O(clk_ppu_rd));
	IBUFG b01(.I(m2),     .O(clk_m2));
	IBUF  b02(.I(cpu_rw), .O(buf_cpu_rw));
*/

nanjing mapper(
	.m2				(m2),
	.cpu_rw			(cpu_rw),
	.cpu_data		(cpu_data),
	.cpu_addr		({~romsel_n,cpu_addr[14:0]}),
	.ppu_addr		(ppu_addr),
	.prg_addr		(prg_addr),
	.prg_oe			(prg_oe),
	.ram_ce			(ram_ce),
	.ram_oe			(ram_oe),
	.ram_we			(ram_we),
	.cpu_dir			(cpu_dir),
	.ppu_rd			(ppu_rd),
	.vram_a12		(vram_a12)
);

endmodule
