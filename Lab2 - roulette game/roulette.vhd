LIBRARY IEEE;
USE IEEE.STD_LOGIC_1164.ALL;
USE IEEE.NUMERIC_STD.ALL;
 
LIBRARY WORK;
USE WORK.ALL;

----------------------------------------------------------------------
--
--  This is the top level template for Lab 2.  Use the schematic on Page 3
--  of the lab handout to guide you in creating this structural description.
--  The combinational blocks have already been designed in previous tasks,
--  and the spinwheel block is given to you.  Your task is to combine these
--  blocks, as well as add the various registers shown on the schemetic, and
--  wire them up properly.  The result will be a roulette game you can play
--  on your DE2.
--
-----------------------------------------------------------------------

ENTITY roulette IS
	PORT(   CLOCK_27 : IN STD_LOGIC; -- the fast clock for spinning wheel
		KEY : IN STD_LOGIC_VECTOR(3 downto 0);  -- includes slow_clock and reset
		SW : IN STD_LOGIC_VECTOR(17 downto 0);
		LEDG : OUT STD_LOGIC_VECTOR(3 DOWNTO 0);  -- ledg
		HEX7 : OUT STD_LOGIC_VECTOR(6 DOWNTO 0);  -- digit 7
		HEX6 : OUT STD_LOGIC_VECTOR(6 DOWNTO 0);  -- digit 6
		HEX5 : OUT STD_LOGIC_VECTOR(6 DOWNTO 0);  -- digit 5
		HEX4 : OUT STD_LOGIC_VECTOR(6 DOWNTO 0);  -- digit 4
		HEX3 : OUT STD_LOGIC_VECTOR(6 DOWNTO 0);  -- digit 3
		HEX2 : OUT STD_LOGIC_VECTOR(6 DOWNTO 0);  -- digit 2
		HEX1 : OUT STD_LOGIC_VECTOR(6 DOWNTO 0);  -- digit 1
		HEX0 : OUT STD_LOGIC_VECTOR(6 DOWNTO 0)   -- digit 0
	);
END roulette;


ARCHITECTURE structural OF roulette IS
 
	-- spinwheel
	component spinwheel is
	  port(
			fast_clock: in STD_LOGIC;  -- This will be a 27 Mhz Clock
			resetb: in STD_LOGIC;      -- asynchronous reset
			spin_result: out UNSIGNED(5 downto 0));  -- current value of the wheel
	end component;

	-- 7 segment displays
	component digit7seg IS
	  port(
		 digit : in  UNSIGNED(3 DOWNTO 0);  -- number 0 to 0xF
		 seg7 : out STD_LOGIC_VECTOR(6 DOWNTO 0)  -- one per segment
		);
	end component;

	-- win
	component win is
		port(
		 spin_result_latched : in unsigned(5 downto 0);  -- result of the spin (the winning number)
		 bet1_value : in unsigned(5 downto 0); -- value for bet 1
		 bet2_colour : in std_logic;  -- colour for bet 2
		 bet3_dozen : in unsigned(1 downto 0);  -- dozen for bet 3
		 bet1_wins : out std_logic;  -- whether bet 1 is a winner
		 bet2_wins : out std_logic;  -- whether bet 2 is a winner
		 bet3_wins : out std_logic); -- whether bet 3 is a winner
	end component;
	-- balance calculation
	component new_balance IS
	  port(money : in unsigned(11 downto 0);  -- Current balance before this spin
			 value1 : in unsigned(2 downto 0);  -- Value of bet 1
			 value2 : in unsigned(2 downto 0);  -- Value of bet 2
			 value3 : in unsigned(2 downto 0);  -- Value of bet 3
			 bet1_wins : in std_logic;  -- True if bet 1 is a winner
			 bet2_wins : in std_logic;  -- True if bet 2 is a winner
			 bet3_wins : in std_logic;  -- True if bet 3 is a winner
			 new_money : out unsigned(11 downto 0));  -- balance after adding winning
																	-- bets and subtracting losing bets
	end component;

	signal spin_result, spin_result_latched : unsigned(5 downto 0);
	signal bet3_dozen : unsigned(1 downto 0);
	signal bet2_colour : std_logic;
	signal bet1_value : unsigned(5 downto 0);
	signal bet1_amount, bet2_amount, bet3_amount : unsigned(2 downto 0);
	signal bet1_wins, bet2_wins, bet3_wins : std_logic;
	signal money, new_money : unsigned(11 downto 0);

BEGIN

	-- spinwheel
	wheel: spinwheel port map(CLOCK_27, KEY(1), spin_result);
	-- 7 segment displays
	hex_7: digit7seg port map("00" & spin_result_latched(5 downto 4),HEX7);
	hex_6: digit7seg port map(spin_result_latched(3 downto 0),HEX6);
	hex_2 : digit7seg port map(digit => new_money(11 downto 8), seg7 => HEX2);
	hex_1 : digit7seg port map(digit => new_money(7 downto 4), seg7 => HEX1);
	hex_0 : digit7seg port map(digit => new_money(3 downto 0), seg7 => HEX0);
	-- win detection
	bet_win: win port map(spin_result_latched, bet1_value, bet2_colour, bet3_dozen, bet1_wins, bet2_wins, bet3_wins);
	-- balance calculation
	balance : new_balance port map(money => money, 
											 value1 => bet1_amount,
											 value2 => bet2_amount, 
											 value3 => bet3_amount, 
											 bet1_wins => bet1_wins, 
											 bet2_wins => bet2_wins, 
											 bet3_wins => bet3_wins,
											 new_money => new_money);
	-- win lights
	LEDG(0) <= bet1_wins;
	LEDG(1) <= bet2_wins;
	LEDG(2) <= bet3_wins;

	-- registers and flip flops
	process(KEY(0), KEY(1))
	begin
	  if(KEY(1) = '0') then -- reset
		 spin_result_latched <= (others => '0');
		 bet1_value <= (others => '1');
		 bet2_colour <= '0';
		 bet3_dozen <= (others => '0');
		 bet1_amount <= (others => '0');
		 bet2_amount <= (others => '0');
		 bet3_amount <= (others => '0');
		 money <= to_unsigned(32,12);
	  elsif(rising_edge(KEY(0))) then
		 spin_result_latched <= spin_result;
		 bet1_value <= unsigned(SW(8 downto 3)); 
		 bet2_colour <= SW(12);
		 bet3_dozen <= unsigned(SW(17 downto 16));
		 bet1_amount <= unsigned(SW(2 downto 0));
		 bet2_amount <= unsigned(SW(11 downto 9));
		 bet3_amount <= unsigned(SW(15 downto 13));
		 money <= new_money;
	  end if;
	end process;
  
END;
