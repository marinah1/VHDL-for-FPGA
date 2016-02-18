library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity ksa_top is
  port(CLOCK_50 : in  std_logic;  -- Clock pin
       KEY : in  std_logic_vector(3 downto 0);  -- push button switches
		 LEDG : out std_logic_vector(7 downto 0));  -- green lights
end ksa_top;


architecture arch of ksa_top is
	constant KEY_LENGTH : positive := 24;

	constant START0 : unsigned(23 downto 0) := to_unsigned(0,KEY_LENGTH);
	constant START1 : unsigned(23 downto 0) := to_unsigned(1048576,KEY_LENGTH);
	constant START2 : unsigned(23 downto 0) := to_unsigned(2097152,KEY_LENGTH);
	constant START3 : unsigned(23 downto 0) := to_unsigned(3145728,KEY_LENGTH);

	constant END0 : unsigned(23 downto 0) := to_unsigned(1048575,KEY_LENGTH);
	constant END1 : unsigned(23 downto 0) := to_unsigned(2097151,KEY_LENGTH);
	constant END2 : unsigned(23 downto 0) := to_unsigned(3145727,KEY_LENGTH);
	constant END3 : unsigned(23 downto 0) := to_unsigned(4194303,KEY_LENGTH);

	component ksa is
	  port(clock : in  std_logic;  -- Clock pin
			 reset : in  std_logic;
			 start_key : in unsigned(23 downto 0);
			 end_key : in unsigned(23 downto 0);
			 stop_search : in std_logic;
			 success : out std_logic);  -- green light
	end component;

	signal success0, success1, success2, success3 : std_logic;
	signal stop_all : std_logic;

begin
	--LEDG(3 downto 0) <= success3 & success2 & success1 & success0;
	LEDG(0) <= success0;
	LEDG(1) <= success1;
	LEDG(2) <= success2;
	LEDG(3) <= success3;
	stop_all <= success0 or success1 or success2 or success3;

	core0: ksa port map(CLOCK_50, KEY(0), START0, END0, stop_all, success0);
	core1: ksa port map(CLOCK_50, KEY(0), START1, END1, stop_all, success1);
	core2: ksa port map(CLOCK_50, KEY(0), START2, END2, stop_all, success2);
	core3: ksa port map(CLOCK_50, KEY(0), START3, END3, stop_all, success3);
end arch;