library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;

entity karabas_128 is
	port(
		-- Clock 14 MHz
		CLK14			: in std_logic;

		-- CPU signals
		CLK_CPU	: out std_logic := '1';
		N_RESET	: in std_logic;
		N_INT		: out std_logic := '1';
		N_RD			: in std_logic;
		N_WR			: in std_logic;
		N_IORQ		: in std_logic;
		N_MREQ		: in std_logic;
		N_M1			: in std_logic;
		A	: in std_logic_vector(7 downto 0); -- partial for port decoding
		A14	: in std_logic;
		A15	: in std_logic;
		D : inout std_logic_vector(7 downto 0) := "ZZZZZZZZ";
		
		-- ZX BUS signals
		BUS_N_IORQGE : in std_logic := '0';
		BUS_N_ROMCS: in std_logic := '0';		

		-- Buffers
		WR_BUF	: out std_logic := '0';
		N_RD_BUF_EN	: out std_logic := '1';
		N_WR_BUF_EN	: out std_logic := '1';
		N_A_GATE_EN	: out std_logic := '1';

		-- Memory signals
		MA		: inout std_logic_vector(13 downto 0) := "ZZZZZZZZZZZZZZ";
		MD		: in std_logic_vector(7 downto 0) := "ZZZZZZZZ";
		N_MRD	: out std_logic := '1';
		N_MWR	: out std_logic := '1';
		RAM_A14 : out std_logic := '0';
		RAM_A15 : out std_logic := '0';
		RAM_A16 : out std_logic := '0';
		RAM_A17 : out std_logic := '0';
		RAM_A18 : out std_logic := '0';

		-- ROM
		N_ROM_CS	: out std_logic := '1';
		ROM_A14 : out std_logic := '0';
		
		-- Video
		VIDEO_SYNC    : out std_logic;
		VIDEO_R       : out std_logic;
		VIDEO_G       : out std_logic;
		VIDEO_B       : out std_logic;
		VIDEO_I       : out std_logic;

		-- Interfaces 
		TAPE_IN 		: in std_logic;
		TAPE_OUT		: out std_logic := '1';
		SPEAKER	: out std_logic := '1';

		-- AY
		AY_CLK	: out std_logic;
		AY_BC1	: out std_logic;
		AY_BDIR	: out std_logic;

		-- Keyboard
		KB	: in std_logic_vector(4 downto 0) := "11111"
	);
end karabas_128;

architecture rtl of karabas_128 is

	signal tick     : std_logic := '0';
	signal invert   : unsigned(4 downto 0) := "00000";

	signal chr_col_cnt : unsigned(2 downto 0) := "000"; -- Character column counter
	signal chr_row_cnt : unsigned(2 downto 0) := "000"; -- Character row counter

	signal hor_cnt  : unsigned(5 downto 0) := "000000"; -- Horizontal counter
	signal ver_cnt  : unsigned(5 downto 0) := "000000"; -- Vertical counter

	signal attr     : std_logic_vector(7 downto 0);
	signal shift    : std_logic_vector(7 downto 0);
	
	signal paper_r  : std_logic;
	signal blank_r  : std_logic;
	signal attr_r   : std_logic_vector(7 downto 0);
	signal shift_r  : std_logic_vector(7 downto 0);
	signal border_attr: std_logic_vector(2 downto 0) := "000";

	signal port_7ffd	: std_logic_vector(7 downto 0);	
	signal ram_ext : std_logic_vector(2 downto 0) := "000";

	signal ay_port	: std_logic := '0';
		
	signal vbus_req		: std_logic := '1';
	signal vbus_ack		: std_logic := '1';
	signal vbus_mode	: std_logic := '1';	
	signal vbus_rdy	: std_logic := '1';
	
	signal vid_rd	: std_logic := '0';
	
	signal paper     : std_logic;

	signal hsync     : std_logic := '1';
	signal vsync     : std_logic := '1';

	signal rom_a	 : std_logic;
	signal vram_acc		: std_logic;
	
	signal n_is_ram     : std_logic := '1';
	signal ram_page	: std_logic_vector(5 downto 0) := "000000";

	signal n_is_rom     : std_logic := '1';
	
	signal sound_out : std_logic := '0';
	signal ear : std_logic := '1';
	signal mic : std_logic := '0';
	signal port_read: std_logic := '0';
	signal port_write: std_logic := '0';
	
	signal fd_port : std_logic;
	signal fd_sel : std_logic;

begin
	rom_a <= '0' when A15 = '0' and A14 = '0' else '1';
	
	n_is_rom <= '0' when N_MREQ = '0' and rom_a = '0' else '1';
	n_is_ram <= '0' when N_MREQ = '0' and rom_a = '1' else '1';

	ROM_A14 <= port_7ffd(4);

	ram_page <=	"000000" when A15 = '0' and A14 = '0' else
				"000101" when A15 = '0' and A14 = '1' else
				"000010" when A15 = '1' and A14 = '0' else
				ram_ext(2 downto 0) & port_7ffd(2 downto 0);

	N_ROM_CS <= n_is_rom or N_RD or BUS_N_ROMCS;

	RAM_A14 <= ram_page(0) when vbus_mode = '0' else '1';
	RAM_A15 <= ram_page(1) when vbus_mode = '0' else port_7ffd(3);
	RAM_A16 <= ram_page(2) when vbus_mode = '0' else '1';
	RAM_A17 <= ram_page(3) when vbus_mode = '0' else '0';
	RAM_A18 <= ram_page(4) when vbus_mode = '0' else '0';
	--RAM_A19 <= ram_page(5) when vbus_mode = '0' else '0';

	vbus_req <= '0' when ( N_MREQ = '0' or N_IORQ = '0' ) and ( N_WR = '0' or N_RD = '0' ) else '1';
	vbus_rdy <= '0' when tick = '0' or chr_col_cnt(0) = '0' else '1';
	N_A_GATE_EN <= vbus_mode;
	
	N_RD_BUF_EN <= '0' when n_is_ram = '0' and N_RD = '0' else '1';	
	N_WR_BUF_EN <= '0' when vbus_mode = '0' and ((n_is_ram = '0' or (N_IORQ = '0' and N_M1 = '1')) and N_WR = '0') else '1';
	
	N_MRD <= '0' when (vbus_mode = '1' and vbus_rdy = '0') or (vbus_mode = '0' and N_RD = '0' and N_MREQ = '0') else '1';  
	N_MWR <= '0' when vbus_mode = '0' and n_is_ram = '0' and N_WR = '0' and chr_col_cnt(0) = '0' else '1';

	paper <= '0' when hor_cnt(5) = '0' and ver_cnt(5) = '0' and ( ver_cnt(4) = '0' or ver_cnt(3) = '0' ) else '1';      

	VIDEO_SYNC <= not (vsync xor hsync);
	
	SPEAKER <= sound_out;
	TAPE_OUT <= mic;
	ear <= TAPE_IN;

	AY_CLK	<= chr_col_cnt(1);
	ay_port <= '1' when A15='1' and A(1) = '0' and fd_port='1' and BUS_N_IORQGE = '0' and N_IORQ = '0' and N_M1 = '1' else '0'; -- #BFFD
	AY_BC1 <= '1' when A14 = '1' and ay_port = '1' else '0';
	AY_BDIR <= '1' when N_WR = '0' and ay_port = '1' else '0';

	WR_BUF <= '1' when vbus_mode = '0' and chr_col_cnt(0) = '0' else '0';

	-- z80 cpu clk
	process( CLK14, tick )
	begin
	-- rising edge of CLK14
		if CLK14'event and CLK14 = '1' then
			if tick = '1' then
				CLK_CPU <= chr_col_cnt(0);
			end if;
		end if;
	end process;
	
	-- sync, counters
	process( CLK14, tick, chr_col_cnt, hor_cnt, chr_row_cnt, ver_cnt)
	begin
		if CLK14'event and CLK14 = '1' then
		
			if tick = '1' then
			
				if chr_col_cnt = 7 then
				
					if hor_cnt = 55 then
						hor_cnt <= (others => '0');
					else
						hor_cnt <= hor_cnt + 1;
					end if;
					
					if hor_cnt = 39 then
						if chr_row_cnt = 7 then
							if ver_cnt = 39 then
								ver_cnt <= (others => '0');
								invert <= invert + 1;
							else
								ver_cnt <= ver_cnt + 1;
							end if;
						end if;
						chr_row_cnt <= chr_row_cnt + 1;
					end if;
				end if;

				-- h/v sync

				if chr_col_cnt = 7 then

					if (hor_cnt(5 downto 2) = "1010") then 
						hsync <= '0';
					else 
						hsync <= '1';
					end if;
					
					if ver_cnt /= 31 then
						vsync <= '1';
					elsif chr_row_cnt = 3 or chr_row_cnt = 4 or ( chr_row_cnt = 5 and ( hor_cnt >= 40 or hor_cnt < 12 ) ) then
						vsync <= '0';
					else 
						vsync <= '1';
					end if;
					
				end if;
			
				-- int
				if chr_col_cnt = 6 and hor_cnt(2 downto 0) = "111" then
					if ver_cnt = 29 and chr_row_cnt = 7 and hor_cnt(5 downto 3) = "100" then
						N_INT <= '0';
					else
						N_INT <= '1';
					end if;
				end if;

				chr_col_cnt <= chr_col_cnt + 1;
			end if;
			tick <= not tick;
		end if;
	end process;

	-- video mem
	process( CLK14, chr_col_cnt, vbus_mode, vid_rd, vbus_req, vbus_ack )
	begin
		if CLK14'event and CLK14 = '1' then 
			if chr_col_cnt(0) = '1' and tick = '0' then
			
				if vbus_mode = '1' then
					if vid_rd = '0' then
						shift <= MD;
					else
						attr  <= MD;
					end if;
				end if;
				
				if vbus_req = '0' and vbus_ack = '1' then
					vbus_mode <= '0';
				else
					vbus_mode <= '1';
					vid_rd <= not vid_rd;
				end if;	
				vbus_ack <= vbus_req;
			end if;
		end if;
	end process;
	
	MA <= ( others => 'Z' ) when vbus_mode = '0' else
		std_logic_vector( "0" & ver_cnt(4 downto 3) & chr_row_cnt & ver_cnt(2 downto 0) & hor_cnt(4 downto 0) ) when vid_rd = '0' else
		std_logic_vector( "0110" & ver_cnt(4 downto 0) & hor_cnt(4 downto 0) );

	-- r/g/b
	process( CLK14, tick, paper_r, shift_r, attr_r, invert, blank_r )
	begin
		if CLK14'event and CLK14 = '1' then
			if tick = '1' then
				if paper_r = '0' then           
					if( shift_r(7) xor ( attr_r(7) and invert(4) ) ) = '1' then
						VIDEO_B <= attr_r(0);
						VIDEO_R <= attr_r(1);
						VIDEO_G <= attr_r(2);
					else
						VIDEO_B <= attr_r(3);
						VIDEO_R <= attr_r(4);
						VIDEO_G <= attr_r(5);
						end if;
				else
					if blank_r = '0' then
						VIDEO_B <= 'Z';
						VIDEO_R <= 'Z';
						VIDEO_G <= 'Z';
						else
						VIDEO_B <= border_attr(0);
						VIDEO_R <= border_attr(1);
						VIDEO_G <= border_attr(2);
					end if;
				end if;
			end if;

		end if;
	end process;

	-- brightness
	process( CLK14, tick, paper_r, attr_r )
	begin
		if CLK14'event and CLK14 = '1' then
			if tick = '1' then
				if paper_r = '0' and attr_r(6) = '1' then
					VIDEO_I <= '1';
				else
					VIDEO_I <= '0';
				end if;
			end if;

		end if;
	end process;

	-- paper, blank
	process( CLK14, tick, chr_col_cnt, hor_cnt, ver_cnt )
	begin
		if CLK14'event and CLK14 = '1' then
			if tick = '1' then
				if chr_col_cnt = 7 then
					attr_r <= attr;
					shift_r <= shift;

					if ((hor_cnt(5 downto 0) > 38 and hor_cnt(5 downto 0) < 48) or ver_cnt(5 downto 1) = 15) then
						blank_r <= '0';
					else 
						blank_r <= '1';
					end if;
					
					paper_r <= paper;
				else
					shift_r(7 downto 1) <= shift_r(6 downto 0);
					shift_r(0) <= '0';
				end if;

			end if;
		end if;
	end process;

	 -- #FD port correction
	 fd_sel <= '0' when vbus_mode='0' and MD(7 downto 4) = "1101" and MD(2 downto 0) = "011" else '1'; -- IN, OUT Z80 Command Latch

	 process(fd_sel, N_M1, N_RESET)
	 begin
			if N_RESET='0' then
				  fd_port <= '1';
			elsif rising_edge(N_M1) then 
				  fd_port <= fd_sel;
			end if;
	 end process;
	
	-- ports, write by CPU
	process( CLK14, N_RESET, tick, A15, A14, MA, D, A(0), port_write )
	begin
		if N_RESET = '0' then
			port_7ffd <= "00000000";
			ram_ext <= "000";
			sound_out <= '0';
			mic <= '0';
			--border_attr <= "000";
		elsif CLK14'event and CLK14 = '1' then 
			if tick = '1' then

				if port_write = '1' then

					 -- port #7FFD                   
					 --if A15 & A14 & MA(13 downto 0) = X"7FFD" and port_7ffd(5) = '0' then
					 if A15='0' and A(1) = '0' then
							port_7ffd <= MD(7 downto 0);
					 end if;
					 
					 -- port #DFFD (ram ext)
					if A15 & A14 & MA(13 downto 0) = X"DFFD" and port_7ffd(5) = '0' and fd_port='1' then
							ram_ext <= MD(2 downto 0);
					end if;
					
					-- port #FE
					if A(0) = '0' then
						border_attr <= MD(2 downto 0); -- border attr
						mic <= MD(3); -- MIC
						sound_out <= MD(4); -- BEEPER
					end if;
				end if;					
			end if;
		end if;
	end process;
	
	port_write <= '1' when N_IORQ = '0' and N_WR = '0' and N_M1 = '1' and vbus_mode = '0' else '0';
	port_read <= '1' when N_IORQ = '0' and N_RD = '0' and N_M1 = '1' and BUS_N_IORQGE = '0' else '0';

	-- read ports by CPU
	D(7 downto 0) <= 
		port_7ffd(7 downto 0) when port_read = '1' and A15='0' and A(1)='0' else -- #7FFD
		'1' & ear & '1' & KB(4 downto 0) when port_read = '1' and A(0) = '0' else -- #FE
		attr_r when port_read = '1' and A(7 downto 0) = "11111111" else -- #FF
		"ZZZZZZZZ";

end;
