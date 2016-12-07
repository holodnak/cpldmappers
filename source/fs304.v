`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company:    Holodnak Electronics
// Engineer:   James Holodnak
// 
// Create Date:    12/07/2016 
// Design Name: 
// Module Name:    fs304 
// Project Name: 
// Target Devices: 
// Tool versions: 
// Description: fs304 mapper (uses nanjing board hardware)
//
// Dependencies: 
//
// Revision: 
// Revision 0.01 - File Created
// Additional Comments: 
//
//////////////////////////////////////////////////////////////////////////////////
module fs304(
	input					m2,				//cpu m2
	input					cpu_rw,			//cpu r/w
	input 	[7:0] 	cpu_data,		//cpu data lines
	input		[15:0]	cpu_addr,		//cpu address lines
	input		[13:12]	ppu_addr,		//ppu address lines
	output	[20:15]	prg_addr,		//prg rom addr lines
	output				prg_oe,			//prg rom /ce (/romsel)
	output				ram_ce,			//wram /ce
	output				ram_oe,			//wram /oe
	output				ram_we			//wram /we
);

	reg [3:0] reg0, reg1, reg2, reg3;
	reg [5:0] prgbank;

	wire write_reg = (m2 & ~cpu_rw & (cpu_addr[15:12] == 4'h5));

	always @ (negedge write_reg)
	begin
		case(cpu_addr[9:8])
			0: reg0 = cpu_data[3:0];
			1: reg1 = cpu_data[3:0];
			2: reg2 = cpu_data[3:0];
			3: reg3 = cpu_data[3:0];
		endcase
	end
	
	always @ (*)
	begin
		case(reg3[2:0])
			0, 2: prgbank = {reg2[3:0], reg0[3:2], reg1[1], 1'b0};
			1, 3: prgbank = {reg2[3:0], reg0[3:2], 2'b0};
			4, 6: prgbank = {reg2[3:0], reg0[3:1], 1'b0, reg1[1]};
			5, 7: prgbank = {reg2[3:0], reg0[3:0]};
		endcase
	end

	wire romread = m2 & cpu_rw & cpu_addr[15];
	wire ramread = m2 & cpu_rw & (cpu_addr[15:13] == 3'h3);
	wire ramwrite = m2 & ~cpu_rw & (cpu_addr[15:13] == 3'h3);

	assign ram_oe = ~ramread;
	assign ram_ce = ~(ramread | ramwrite);
	assign ram_we = ~ramwrite;
	assign prg_oe = ~romread;
	assign prg_addr[20:15] = prgbank[5:0];

endmodule
