library ieee;
use ieee.std_logic_1164.all;

entity karabas_128_tb is
end karabas_128_tb;

architecture behavior of karabas_128_tb is

    component karabas_128 is
    port(
        -- Clock 14 MHz
        CLK14           : in std_logic;

        -- CPU signals
        CLK_CPU : out std_logic := '1';
        N_RESET : in std_logic;
        N_INT       : out std_logic := '1';
        N_RD            : in std_logic;
        N_WR            : in std_logic;
        N_IORQ      : in std_logic;
        N_MREQ      : in std_logic;
        N_M1            : in std_logic;
        A   : in std_logic_vector(7 downto 0); -- partial for port decoding
        A14 : in std_logic;
        A15 : in std_logic;
        D : inout std_logic_vector(7 downto 0) := "ZZZZZZZZ";
        
        -- ZX BUS signals
        BUS_N_IORQGE : in std_logic := '0';
        BUS_N_ROMCS: in std_logic := '0';

        -- Buffers
        WR_BUF  : out std_logic := '0';
        N_RD_BUF_EN : out std_logic := '1';
        N_WR_BUF_EN : out std_logic := '1';
        N_A_GATE_EN : out std_logic := '1';

        -- Memory signals
        MA      : inout std_logic_vector(13 downto 0) := "ZZZZZZZZZZZZZZ";
        MD      : in std_logic_vector(7 downto 0) := "ZZZZZZZZ";
        N_MRD   : out std_logic := '1';
        N_MWR   : out std_logic := '1';
        RAM_A14 : out std_logic := '0';
        RAM_A15 : out std_logic := '0';
        RAM_A16 : out std_logic := '0';

        -- ROM
        N_ROM_CS    : out std_logic := '1';
        ROM_A14 : out std_logic := '0';
        
        -- Video
        VIDEO_SYNC    : out std_logic := '1';
        VIDEO_HSYNC    : out std_logic := '1';
        VIDEO_VSYNC    : out std_logic := '1';
        VIDEO_R       : out std_logic := '0';
        VIDEO_G       : out std_logic := '0';
        VIDEO_B       : out std_logic := '0';
        VIDEO_I       : out std_logic := '0';

        -- Interfaces 
        TAPE_IN         : in std_logic;
        TAPE_OUT        : out std_logic := '1';
        SPEAKER : out std_logic := '1';

        -- AY
        AY_CLK  : out std_logic;
        AY_BC1  : out std_logic;
        AY_BDIR : out std_logic;

        -- Keyboard
        KB  : in std_logic_vector(4 downto 0) := "11111"
    );
    end component;

    signal clk  : std_logic := '0';
    signal cnt : std_logic := '0';

    signal clk_cpu : std_logic := '0';
    signal n_reset : std_logic := '1';
    signal n_int : std_logic := '1';
    signal n_rd : std_logic := '1';
    signal n_wr : std_logic := '1';
    signal n_iorq : std_logic := '1';
    signal n_mreq : std_logic := '1';
    signal n_m1 : std_logic := '1';
    signal a : std_logic_vector(7 downto 0);
    signal a14 : std_logic;
    signal a15 : std_logic;
    signal d : std_logic_vector(7 downto 0);

    signal BUS_N_IORQGE : std_logic := '0';
    signal BUS_N_ROMCS: std_logic := '0';

    signal WR_BUF  : std_logic := '0';
    signal N_RD_BUF_EN : std_logic := '1';
    signal N_WR_BUF_EN : std_logic := '1';
    signal N_A_GATE_EN : std_logic := '1';

    signal MA      : std_logic_vector(13 downto 0) := "ZZZZZZZZZZZZZZ";
    signal MD      : std_logic_vector(7 downto 0) := "ZZZZZZZZ";
    signal N_MRD   : std_logic := '1';
    signal N_MWR   : std_logic := '1';
    signal RAM_A14 : std_logic := '0';
    signal RAM_A15 : std_logic := '0';
    signal RAM_A16 : std_logic := '0';

    signal N_ROM_CS : std_logic := '1';
    signal ROM_A14 : std_logic := '0';
        
    signal VIDEO_SYNC : std_logic := '1';
    signal VIDEO_HSYNC : std_logic := '1';
    signal VIDEO_VSYNC : std_logic := '1';
    signal VIDEO_R       : std_logic := '0';
    signal VIDEO_G       : std_logic := '0';
    signal VIDEO_B       : std_logic := '0';
    signal VIDEO_I       : std_logic := '0';

    signal TAPE_IN         : std_logic;
    signal TAPE_OUT        : std_logic := '1';
    signal SPEAKER : std_logic := '1';

    signal AY_CLK  : std_logic;
    signal AY_BC1  : std_logic;
    signal AY_BDIR : std_logic;

    signal KB  : std_logic_vector(4 downto 0) := "11111";

begin
    u1: karabas_128 
    port map (
        CLK14 => clk,
        CLK_CPU => clk_cpu,
        N_RESET => n_reset,

        N_INT => n_int,
        N_RD => n_rd,
        N_WR => n_wr,
        N_IORQ => n_iorq,
        N_MREQ => n_mreq,
        N_M1 => n_m1,
        A => a,
        A14 => a14, 
        A15 => a15, 
        D => d,
        
        BUS_N_IORQGE => BUS_N_IORQGE,
        BUS_N_ROMCS => BUS_N_ROMCS,

        WR_BUF => WR_BUF,
        N_RD_BUF_EN => N_RD_BUF_EN,
        N_WR_BUF_EN => N_WR_BUF_EN,
        N_A_GATE_EN => N_A_GATE_EN,

        MA      => MA,
        MD      => MD,
        N_MRD   => N_MRD,
        N_MWR   => N_MWR,
        RAM_A14 => RAM_A14,
        RAM_A15 => RAM_A15,
        RAM_A16 => RAM_A16,

        N_ROM_CS => N_ROM_CS,
        ROM_A14 => ROM_A14,
        
        VIDEO_SYNC => VIDEO_SYNC,
        VIDEO_HSYNC => VIDEO_HSYNC,
        VIDEO_VSYNC => VIDEO_VSYNC,
        VIDEO_R => VIDEO_R,
        VIDEO_G => VIDEO_G,
        VIDEO_B => VIDEO_B,
        VIDEO_I => VIDEO_I,

        TAPE_IN => TAPE_IN,
        TAPE_OUT => TAPE_OUT,
        SPEAKER => SPEAKER,

        AY_CLK => AY_CLK,
        AY_BC1 => AY_BC1,
        AY_BDIR => AY_BDIR,

        KB => KB

    );

    -- simulate reset
    n_reset <=
        '1' after 0 ns,
        '0' after 300 ns,
        '1' after 1000 ns;

    -- simulate clk
    clk <=  '1' after 71 ns when clk = '0' else
        '0' after 71 ns when clk = '1';

    -- simulate adc_data
    -- "11111111" / "00000000"
    --adc_data <= '0' when cnt='0' and adc_cs_n='0' and adc_clk='0' else 
    --            '1' when cnt='1' and adc_cs_n='0' and adc_clk='0' else 
    --            'Z';

    --process (adc_cs_n) 
    --begin
    --    if falling_edge(adc_cs_n) then 
    --        if (cnt = '1') then cnt <= '0'; else cnt <= '1'; end if;
    --    end if;
    --end process;

end;
