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
		--N_IORQGE	: in std_logic; -- ZX BUS IORQ ULA disable, todo
		N_MREQ		: in std_logic;
		--N_ROMCS1	: in std_logic; -- ZX BUS ROM CS disable, todo
		N_M1			: in std_logic;
		N_RFSH		: in std_logic; -- not used
		N_NMI		: in std_logic; -- not used, todo
		A14	: in std_logic;
		A15	: in std_logic;
		CPU_D		: inout std_logic_vector(4 downto 0) := "ZZZZZ"; -- for port #FE
		CPU_D6		: inout std_logic := 'Z'; -- for port #FE
		A0		: in std_logic; -- for port #FE

		-- Buffers
		WR_BUF	: out std_logic := '0';
		N_RD_BUF_EN	: out std_logic := '1';
		N_WR_BUF_EN	: out std_logic := '1';
		N_A_GATE_EN	: out std_logic := '1';

		-- Memory signals
		MA		: inout std_logic_vector(13 downto 0) := "ZZZZZZZZZZZZZZ";
		MD		: inout std_logic_vector(7 downto 0) := "ZZZZZZZZ";
		N_MRD	: out std_logic := '1';
		N_MWR	: out std_logic := '1';
		RAM_A14 : out std_logic := '0';
		RAM_A15 : out std_logic := '0';
		RAM_A16 : out std_logic := '0';

		-- ROM
		N_ROM_CS	: out std_logic := '1';
		ROM_A14 : out std_logic := '0';
		ROM_A15 : out std_logic := '0';
		
		-- Video
		VIDEO_CSYNC    : out std_logic := '1';     
		VIDEO_HSYNC    : out std_logic := '1';     
		VIDEO_VSYNC    : out std_logic := '1';     
		VIDEO_RED       : out std_logic := '0';
		VIDEO_GREEN       : out std_logic := '0';
		VIDEO_BLUE       : out std_logic := '1';   
		VIDEO_BRIGHT       : out std_logic := '0';     

		-- Interfaces 
		TAPE_IN 		: in std_logic;
		TAPE_OUT		: out std_logic := '1';				
		SPEAKER	: out std_logic := '1';

		-- AY
		AY_CLK	: out std_logic;
		AY_BC1	: out std_logic;
		AY_BDIR	: out std_logic;

		-- Keyboard
		KB	: in std_logic_vector(4 downto 0) := "ZZZZZ";
		SW	: in std_logic_vector(4 downto 0) := "00000"
	);
end karabas_128;

architecture rtl of karabas_128 is

	signal tick     : std_logic := '0';
	signal invert   : unsigned(4 downto 0) := "00000";

	signal chr_col_cnt : unsigned(2 downto 0) := "000";    -- Character column counter
	signal chr_row_cnt : unsigned(2 downto 0) := "000";    -- Character row counter

	signal h_cnt  : unsigned(5 downto 0) := "000000"; -- Horizontal counter
	signal v_cnt  : unsigned(5 downto 0) := "000000"; -- Vertical counter

	signal attr     : std_logic_vector(7 downto 0);
	signal shift    : std_logic_vector(7 downto 0);
    
	signal paper_r  : std_logic;
	signal blank_r  : std_logic;
	signal attr_r   : std_logic_vector(7 downto 0);
	signal shift_r  : std_logic_vector(7 downto 0);

	signal border_attr: std_logic_vector(2 downto 0) := "000";
	signal port_7ffd	: std_logic_vector(5 downto 0);
	signal ay_port	: std_logic := '0';
        
	signal vbus_req		: std_logic := '1';
	signal vbus_ack		: std_logic := '1';
	signal vbus_mode	: std_logic := '1';	
	signal vbus_rdy	: std_logic := '1';
	
	signal vid_rd	: std_logic := '0';
	
	signal paper     : std_logic;
	signal hsync     : std_logic;
	signal vsync1    : std_logic;
	signal vsync2    : std_logic;

	signal rom_a	 : std_logic;
	signal vram_acc		: std_logic;
	
	signal rom_sel	 	: std_logic;
	
	signal RAM     : std_logic := '1';
	signal ram_page	: std_logic_vector(2 downto 0) := "000";

	signal ROM     : std_logic := '1';
	signal rom_page	: std_logic_vector(1 downto 0) := "00";
	
	signal sound_out : std_logic := '0';
	signal ear : std_logic := '1';
	signal mic : std_logic := '0';
	signal port_fe : std_logic := '0';
	
begin
	rom_a <= '0' when A15 = '0' and A14 = '0' else '1';
	
	ROM <= '0' when N_MREQ = '0' and rom_a = '0' else '1';
	RAM <= '0' when N_MREQ = '0' and rom_a = '1' else '1';

	rom_sel <= port_7ffd(4);

	rom_page <=	"01" when rom_sel = '1' else
				"00";

	ram_page <=	"000" when A15 = '0' and A14 = '0' else
				"101" when A15 = '0' and A14 = '1' else
				"010" when A15 = '1' and A14 = '0' else
				port_7ffd(2 downto 0);

	N_ROM_CS <= ROM;

	-- SW(0), SW(1): remap A14, A15 for 27c512, 28c256, etc
	--ROM_A14 <= rom_page(0) when SW(0) = '0' else '1';
	--ROM_A15 <= rom_page(1) when SW(1) = '0' else '1';
	ROM_A14 <= rom_page(0);
	ROM_A15 <= rom_page(1);

	RAM_A14 <= ram_page(0) when vbus_mode = '0' else '1';
	RAM_A15 <= ram_page(1) when vbus_mode = '0' else port_7ffd(3);
	RAM_A16 <= ram_page(2) when vbus_mode = '0' else '1';

	vbus_req <= '0' when ( N_MREQ = '0' or N_IORQ = '0' ) and ( N_WR = '0' or N_RD = '0' ) else '1';
	vbus_rdy <= '0' when tick = '0' or chr_col_cnt(0) = '0' else '1';
	N_A_GATE_EN <= vbus_mode;
	
	N_RD_BUF_EN <= '0' when RAM = '0' and N_RD = '0' else '1';	
	N_WR_BUF_EN <= '0' when vbus_mode = '0' and ((RAM = '0' or (N_IORQ = '0' and N_M1 = '1')) and N_WR = '0') else '1';
	
	N_MRD <= '0' when (vbus_mode = '1' and vbus_rdy = '0') or (vbus_mode = '0' and N_RD = '0' and N_MREQ = '0') else '1';  
	N_MWR <= '0' when vbus_mode = '0' and RAM = '0' and N_WR = '0' and chr_col_cnt(0) = '0' else '1';

	paper <= '0' when h_cnt(5) = '0' and v_cnt(5) = '0' and ( v_cnt(4) = '0' or v_cnt(3) = '0' ) else '1';      

	hsync <= '0' when h_cnt(5 downto 2) = "1010" else '1';
	vsync1 <= '0' when h_cnt(5 downto 1) = "00110" or h_cnt(5 downto 1) = "10100" else '1';
	vsync2 <= '1' when h_cnt(5 downto 2) = "0010" or h_cnt(5 downto 2) = "1001" else '0';
	
	SPEAKER <= sound_out;
	TAPE_OUT <= mic;
	ear <= TAPE_IN;

	AY_CLK	<= chr_col_cnt(1);
	ay_port	<= '0' when N_WR = '1' and N_RD = '1' else
					'1' when vbus_mode = '0' and MA(1 downto 0) = "01" else
					'0' when vbus_mode = '0' else
					ay_port;
	AY_BC1	<= '1' when ay_port = '1' and N_M1 = '1' and N_IORQ = '0' and A14 = '1' and A15 = '1' else '0';
	AY_BDIR	<= '1' when ay_port = '1' and N_M1 = '1' and N_IORQ = '0' and A15 = '1' and N_WR = '0' else '0';

	WR_BUF <= '1' when vbus_mode = '0' and chr_col_cnt(0) = '0' else '0';
	
	-- generate Z80 CLOCK 3.5 MHz

	process( CLK14 )
	begin
	-- rising edge of CLK14
		if CLK14'event and CLK14 = '1' then
			if tick = '1' then
				if chr_col_cnt(0) = '0' then 
					CLK_CPU <= '0';
				else
					CLK_CPU <= '1';
				end if;
			end if;
		end if;     
	end process;

	process( CLK14 )
	begin
		if CLK14'event and CLK14 = '1' then
        
			if tick = '1' then
            
				if chr_col_cnt = 7 then
                
					if h_cnt = 55 then
						h_cnt <= (others => '0');
					else
						h_cnt <= h_cnt + 1;
					end if;
                    
					if h_cnt = 39 then                    
						if chr_row_cnt = 7 then
							if v_cnt = 39 then
								v_cnt <= (others => '0');
								invert <= invert + 1;
							else
								v_cnt <= v_cnt + 1;
							end if;                         
						end if;                     
						chr_row_cnt <= chr_row_cnt + 1;
					end if;
				end if;
                
				if chr_col_cnt = 7 then
                    
				if not ( v_cnt = 31 ) then
					VIDEO_HSYNC <= hsync;
					VIDEO_CSYNC <= hsync;
				elsif chr_row_cnt = 3 or chr_row_cnt = 4 or ( chr_row_cnt = 5 and ( h_cnt >= 40 or h_cnt < 12 ) ) then
					VIDEO_VSYNC <= vsync2;
					VIDEO_CSYNC <= vsync2;
				else
					VIDEO_VSYNC <= vsync1;
					VIDEO_CSYNC <= vsync1;
				end if;
                    
				end if;
            
				if chr_col_cnt = 6 and h_cnt(2 downto 0) = "111" then
					if v_cnt = 29 and chr_row_cnt = 7 and h_cnt(5 downto 3) = "100" then
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

	process( CLK14 )
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
											std_logic_vector( "0" & v_cnt(4 downto 3) & chr_row_cnt & v_cnt(2 downto 0) & h_cnt(4 downto 0) ) when vid_rd = '0' else
											std_logic_vector( "0110" & v_cnt(4 downto 0) & h_cnt(4 downto 0) );

	process( CLK14 )
	begin
		if CLK14'event and CLK14 = '1' then
			if tick = '1' then
				if paper_r = '0' then           
					if( shift_r(7) xor ( attr_r(7) and invert(4) ) ) = '1' then
						VIDEO_BLUE <= attr_r(0);
						VIDEO_RED <= attr_r(1);
						VIDEO_GREEN <= attr_r(2);
					else
						VIDEO_BLUE <= attr_r(3);
						VIDEO_RED <= attr_r(4);
						VIDEO_GREEN <= attr_r(5);
						end if;
				else
					if blank_r = '0' then
						VIDEO_BLUE <= 'Z';
						VIDEO_RED <= 'Z';
						VIDEO_GREEN <= 'Z';
						else
						VIDEO_BLUE <= border_attr(0);
						VIDEO_RED <= border_attr(1);
						VIDEO_GREEN <= border_attr(2);
					end if;
				end if;
			end if;             

		end if;
	end process;

	process( CLK14 )
	begin
		if CLK14'event and CLK14 = '1' then
			if tick = '1' then
				if paper_r = '0' and attr_r(6) = '1' then
					VIDEO_BRIGHT <= '1';
				else
					VIDEO_BRIGHT <= '0';
				end if;
			end if;			

		end if;
	end process;

	process( CLK14 )
	begin
		if CLK14'event and CLK14 = '1' then
			if tick = '1' then
				if chr_col_cnt = 7 then
					attr_r <= attr;
					shift_r <= shift;

					if ((h_cnt(5 downto 0) > 38) and (h_cnt(5 downto 0) < 48)) or v_cnt(5 downto 1) = 15 then
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

	process( CLK14 )
	begin
		if CLK14'event and CLK14 = '1' then

			if N_RESET = '0' then
				port_7ffd <= "000000";
				sound_out <= '0';
			elsif tick = '1' and chr_col_cnt(0) = '0' and vbus_mode = '0' and N_IORQ = '0' and N_M1 = '1' then

				-- port 7ffd, read				
				if N_WR = '0' and MA(1) = '0' and A15 = '0' and port_7ffd(5) = '0' then
					port_7ffd <= MD(5 downto 0);
				end if;

				-- port #FE, write by CPU (read speaker, mic and border attr)
				if N_WR = '0' and MA(7 downto 0) = "11111110" then
					border_attr <= MD(2 downto 0); -- border attr
					mic <= MD(3); -- MIC
					sound_out <= MD(4); -- BEEPER
				end if;
			end if;             
		end if;
	end process;
	
	port_fe <= '1' when N_IORQ = '0' and N_RD = '0' and N_M1 = '1' and A0 = '0' else '0';
	
	-- port #FE, read by CPU (keyboard, ear)
	CPU_D(4 downto 0) <= KB(4 downto 0) when port_fe = '1' else "ZZZZZ";
	CPU_D6 <= ear when port_fe = '1' else 'Z';

end;
