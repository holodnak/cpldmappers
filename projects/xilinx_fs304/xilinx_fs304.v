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
	input 	[7:0] 	cpu_data,		//cpu data lines
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

	fs304 mapper(
		.m2				(m2),
		.cpu_rw			(cpu_rw),
		.cpu_data		(cpu_data),
		.cpu_addr		({~romsel_n,cpu_addr[14:0]}),
		.ppu_addr		(ppu_addr),
		.prg_addr		(prg_addr),
		.prg_oe			(prg_oe),
		.ram_ce			(ram_ce),
		.ram_oe			(ram_oe),
		.ram_we			(ram_we)
	);

	//handle the unused nanjing pins since this shares the same board hardware
	assign cpu_dir = ~(m2 & cpu_rw & ~romsel_n);
	assign vram_a12 = ppu_addr[12];

endmodule
