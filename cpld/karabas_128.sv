module speccy2007_vid (
	input	wire	CLK14,			// 14MHz input clock
	input	wire	N_RESET,		// CPU reset

	// CPU signals
	output	reg 	CLK_CPU = 1,	// CPU clock 3.5 MHz
	input	wire	N_RD,
	input	wire	N_WR,
	input	wire	N_IORQ,
	input	wire	N_MREQ,
	input	wire	N_M1,
	output	wire 	N_INT,

	// buffers
	output	wire	N_A_GATE_EN,
	output	wire 	WR_BUF,
	output	wire 	N_RD_BUF_EN,
	output	wire 	N_WR_BUF_EN,

	// speaker/tape_in
	output	wire	SPEAKER,
	input	reg		TAPE_IN,
	output	reg		TAPE_OUT = 0,

	// RAM/ROM select
	output 	wire	N_ROM_CS,
	output 	wire	ROM_A14,
//	output 	wire	ROM_A15,

	output	wire	N_MRD,
	output	wire	N_MWR,
	output	wire	RAM_A14,
	output	wire	RAM_A15,
	output	wire	RAM_A16,

	// Video
	output	wire	VIDEO_SYNC,
	output wire		VIDEO_HSYNC,
	output wire 	VIDEO_VSYNC,
	output	reg		VIDEO_R = 0,
	output	reg		VIDEO_G = 0,
	output	reg		VIDEO_B = 0,
	output	reg		VIDEO_I = 0,

	// AY
	output	wire	AY_CLK,
	output	wire	AY_BC1,
	output	wire	AY_BDIR,

    // Address/Data Bus
	input	wire	[7:0] MD,		// Data Bus, buffered
	inout	wire	[13:0] MA,		// Address bus, buffered
	input   wire    [7:0] A,		// Address bus, low, direct
	inout   wire    [7:0] D,		// Data Bus, unbuffered
	input	wire	A14,
	input	wire	A15,

	// ZX BUS signals
	input reg 		BUS_N_IORQGE,
	input reg	 	BUS_N_ROMCS,

	// Keyboard port
	input wire 		[4:0] KB
);

//---------------------------------------------------
// pixel/attr fetch (last 3 bits of hcnt, 0-7 states)
	parameter pixel_cnt = 3'b000;
	parameter attr_cnt = 3'b001;
	parameter pixel_shift = attr_cnt - pixel_cnt; // we need to shift pixels to match attributes
//---------------------------------------------------
// CLASSIC

/*	parameter HLineEnd = 447;
	parameter HBorderStart = 256; //X resolution
	parameter HSynStart  = 320;
	parameter HSynEnd  = 347;
	parameter HBlancStart  = 304;
	parameter HBlancEnd  = 399;

	parameter VBorderStart = 192; //Y Resolution
	parameter VBlancStart = 242;
	parameter VBlancEnd = 249;
	parameter VSynStart = 242;
	parameter VSynEnd = 249;
	parameter VLineEnd = 311;

	parameter VIntStart = 246;
	parameter HIntStart  = 320;
	parameter HIntEnd  = 389;
*/

//---------------------------------------------------
//---------------------------------------------------
// PENTAGON

	parameter HLineEnd = 447;
	parameter HBorderStart = 256; //X resolution
	parameter HSynStart  = 320;
	parameter HSynEnd  = 334;//51;
	parameter HBlancStart  = 320;
	parameter HBlancEnd  = 383;

	parameter VBorderStart = 192; //Y Resolution
	parameter VBlancStart = 250;
	parameter VBlancEnd = 265;
	parameter VSynStart = 250;
	parameter VSynEnd = 265;
	parameter VLineEnd = 319;

	parameter VIntStart = 240-1;
	parameter HIntStart  = 320;
	parameter HIntEnd  = 389;

////-----------------------------------------------------
wire CPU_MODE = hcnt[2:0] == pixel_cnt || hcnt[2:0] == attr_cnt ? 1'b0 : 1'b1;
// hcnt[2:0] = (with current parameters)
// 000	(CPU_MODE = 0)	video processing pixels
// 001	(CPU_MODE = 0)	video processing attributes
// 010	(CPU_MODE = 1)	CPU
// 011	(CPU_MODE = 1) 	CPU	//WR_BUF
// 100	(CPU_MODE = 1) 	CPU
// 101	(CPU_MODE = 1) 	CPU	//WR_BUF
// 110	(CPU_MODE = 1)	CPU
// 111	(CPU_MODE = 1) 	CPU	//WR_BUF

reg pixel_clock			= 0;			// 7MHz pixel clock
reg [8:0] hcnt			= 9'b000000000;	// Horizontal counter
reg	[8:0] vcnt			= 9'b000000000;	// Vertical counter
reg [7:0] attrs;						// attributes register
reg	[7+pixel_shift:0] pixels;			// pixel data from data bus
reg [2:0] border_attr	= 3'b000;		// border attributes
reg	[5:0] port_7ffd		= 6'b000000;	// port 7FFD data
reg [4:0] flash_cnt		= 0;			// flash counter
reg hsync 				= 1;
reg vsync 				= 1;
reg hblanc 				= 0;
reg vblanc 				= 0;
reg vbord 				= 0;
reg hbord 				= 0;
reg border_r 			= 0;
reg blank_r 			= 0;
reg SOUND_OUT			= 0;
reg port_access 		= 0;

wire ROMADR 			= A15 | A14;
assign N_ROM_CS			= N_MREQ | ROMADR | BUS_N_ROMCS;
wire RAM_CS 			= N_MREQ | ~ROMADR;
wire [1:0] ROM_PAGE;//		= 2'b00;
wire [2:0] RAM_PAGE;//		= 3'b000;

// select AY
reg AY_SEL = 0;
always @(negedge CLK14)
	if( CPU_MODE == 1 )
		AY_SEL <= A15 == 1 && MA[13] == 1 && MA[1:0] == 2'b01;


always_comb
begin
	ROM_PAGE = {'b00,port_7ffd[4]};

	case({A14,A15})
		'b00 : RAM_PAGE = 'b000;
		'b10 : RAM_PAGE = 'b101;
		'b01 : RAM_PAGE = 'b010;
		'b11 : RAM_PAGE = port_7ffd[2:0];
	endcase

	ROM_A14 = ROM_PAGE[0];
	//ROM_A15 = ROM_PAGE[1];
	RAM_A14 = CPU_MODE == 1 ? RAM_PAGE[0] : 1'b1;
	RAM_A15 = CPU_MODE == 1 ? RAM_PAGE[1] : port_7ffd[3];
	RAM_A16 = CPU_MODE == 1 ? RAM_PAGE[2] : 1'b1;

	// buffers enable
	N_A_GATE_EN = ~CPU_MODE;
	N_RD_BUF_EN = RAM_CS == 0 && N_RD == 0 ? 1'b0 : 1'b1;
	N_WR_BUF_EN = CPU_MODE == 1 && ((RAM_CS == 0 || (N_IORQ == 0 && N_M1 == 1)) && N_WR == 0) ? 1'b0 : 1'b1;
	WR_BUF = CPU_MODE == 1 && hcnt[0] == 1;
	N_MWR = CPU_MODE == 1 && RAM_CS == 0 && N_WR == 0 ? 1'b0 : 1'b1;

	N_MRD = (CPU_MODE == 1 && N_RD == 0 && N_MREQ == 0 ) || CPU_MODE == 0 ? 1'b0 : 1'b1;

	// Memory address selector, select CPU address (Z-state) or generate address from counters
	case(hcnt[2:0])
		pixel_cnt: MA = {1'b0,vcnt[7:6],vcnt[2:0],vcnt[5:3],hcnt[7:3]}; // pixels
		attr_cnt: MA = {4'b0110,vcnt[7:3],hcnt[7:3]};					// attributes
		default: MA = 14'bZZZZZZZZZZZZZZ;								// Z80 address bus
	endcase

	SPEAKER = SOUND_OUT ^ TAPE_IN;

	// AY
	AY_CLK = hcnt[1];
	AY_BC1 = N_M1 == 1 && N_IORQ == 0 && AY_SEL == 1 && A14 == 1 && RAM_CS == 1 ? 1'b1 : 1'b0;
	AY_BDIR = N_M1 == 1 && N_IORQ == 0 && AY_SEL == 1 && N_WR == 0 && RAM_CS == 1 ? 1'b1 : 1'b0;

	// KB and attr ports
	port_access = N_IORQ == 0 && N_RD == 0 && N_M1 == 1 && BUS_N_IORQGE == 0 ? 1'b1 : 1'b0;

	casex({port_access,A[7:0]})
		'b1XXXXXXX0 : D = {1'b1, TAPE_IN, 1'b1, KB[4:0]};
		'b111111111 : D = attrs;
		default : D = 8'bZZZZZZZZ;
	endcase

end


assign VIDEO_SYNC = ~(hsync ^ vsync);
assign VIDEO_VSYNC = ~vsync;
assign VIDEO_HSYNC = ~hsync;
assign N_INT = vcnt == VIntStart && hcnt >= HIntStart && hcnt <= HIntEnd ? 1'b0 : 1'b1;

//assign D = {port_access,A[7:0]} == 'b1XXXXXXX0 ? {1'b1, TAPE_IN, 1'b1, KB[4:0]} : ({port_access,A[7:0]} == 'b111111111 ? attrs : 8'bZZZZZZZZ);
	
// generate clocks
always @(posedge CLK14)
begin
	// generate 7MHz pixelclock
	pixel_clock <= ~pixel_clock;
	// generate Z80 CLOCK 3.5 MHz
	if(pixel_clock == 1)
		CLK_CPU <= hcnt[0];
end

	
// --------------------------- VIDEO COUNTERS -------------------------------
// horisontal counters
always @(posedge CLK14)
	if( pixel_clock == 0 )
	begin
		// horisontal counter increase or reset
		if(hcnt < HLineEnd)
		begin
			hcnt <= hcnt + 9'd1;
			if(hcnt == HSynEnd)
			begin
				vsync <= vcnt >= VSynStart-1 && vcnt <= VSynEnd-1 ? 1'b1 : 1'b0;
				vbord <= vcnt >= VBorderStart-1 && vcnt < VLineEnd ? 1'b1 : 1'b0;
				vblanc <= vcnt >= VBlancStart-1 && vcnt <= VBlancEnd-1 ? 1'b1 : 1'b0;
			end
		end
		else
		begin
			hcnt <= 9'd0;
			// vertical counter increase or reset
			if( vcnt < VLineEnd )
				vcnt <= vcnt + 9'd1;
			else
			begin
				vcnt <= 9'd0;
				// flash generator
				flash_cnt <= flash_cnt + 1'b1;
			end
		end
		// horisontal signals
		hsync <= hcnt >= HSynStart && hcnt <= HSynEnd ? 1'b1 : 1'b0;
		hbord <= hcnt >= HBorderStart ? 1'b1 : 1'b0;
		hblanc <= hcnt >= HBlancStart && hcnt <= HBlancEnd ? 1'b1 : 1'b0;			
	end
// --------------------------------------------------------------------------

								

// fetch attributes or shift pixel, generate border/blank
always @(negedge CLK14)
	if(pixel_clock == 0)
	begin
		border_r <= hbord | vbord;
		blank_r <= hblanc | vblanc;
		pixels <= pixels << 1;
		case(hcnt[2:0])
			pixel_cnt: pixels[7:0] <= MD;	// get pixels data from video ram
			attr_cnt: attrs <= MD;			// get attributes data from video ram
		endcase
	end


// video out signals generation
always @(posedge CLK14)
	if(pixel_clock == 1)
	begin
		if( border_r == 0 )
		begin
			// show pixels
			if( pixels[7+pixel_shift] ^ ( attrs[7] & flash_cnt[4] ) == 1 )
			begin // pixels output
				VIDEO_B <= attrs[0];
				VIDEO_R <= attrs[1];
				VIDEO_G <= attrs[2];
			end
			else
			begin // attributes output
				VIDEO_B <= attrs[3];
				VIDEO_R <= attrs[4];
				VIDEO_G <= attrs[5];
			end
			VIDEO_I <= attrs[6] == 1  ? 1'b1 : 1'b0;
		end
		else
		begin
			// show border
			if(blank_r == 1 )
			begin // blank output
				VIDEO_B <= 1'bZ;
				VIDEO_R <= 1'bZ;
				VIDEO_G <= 1'bZ;
			end
			else
			begin // border output
				VIDEO_B <= border_attr[0];
				VIDEO_R <= border_attr[1];
				VIDEO_G <= border_attr[2];
			end
			VIDEO_I <= 1'b0;
		end
	end


always @(negedge CLK14 or negedge N_RESET) //posedge pixel_clock
	if( !N_RESET)
	begin
		port_7ffd <= 6'b000000;
		SOUND_OUT <= 0;
		TAPE_OUT <= 0;
	end
	else
	begin
		// ports ----------------------------------
		if(pixel_clock == 1)
		if( N_IORQ == 0 )
		begin
			if( CPU_MODE == 1 && N_M1 == 1 && hcnt[0] == 1 )
			begin
				// Write to ports
				if( N_WR == 0 )
				begin //read ports
					// port #FD & #7FFD (memory manager port)
					if( MA[1] == 0 && A15 == 0 && (MA[13] ^ MA[9]) == 0 && port_7ffd[5] == 0 )
						port_7ffd <= MD[5:0];
					// port #FE (border, speaker, tapeout)
					if( MA[7] == 1 && MA[4:3] == 'b11 && MA[1:0] == 'b10 )
					begin
						border_attr <= MD[2:0];
						TAPE_OUT <= MD[3];
						SOUND_OUT <= MD[4];
					end
				end
			end
		end
		// ----------------------------------------
	end

endmodule
