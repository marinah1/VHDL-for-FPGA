LIBRARY IEEE;
USE IEEE.STD_LOGIC_1164.ALL;
USE IEEE.NUMERIC_STD.ALL;
 
LIBRARY WORK;
USE WORK.ALL;

--------------------------------------------------------------
--
--  This is a skeleton you can use for the win subblock.  This block determines
--  whether each of the 3 bets is a winner.  As described in the lab
--  handout, the first bet is a "straight-up" bet, teh second bet is 
--  a colour bet, and the third bet is a "dozen" bet.
--
--  This should be a purely combinational block.  There is no clock.
--  Remember the rules associated with Pattern 1 in the lectures.
--
---------------------------------------------------------------

ENTITY win IS
	PORT(spin_result_latched : in unsigned(5 downto 0);  -- result of the spin (the winning number)
             bet1_value : in unsigned(5 downto 0); -- value for bet 1
             bet2_colour : in std_logic;  -- colour for bet 2
             bet3_dozen : in unsigned(1 downto 0);  -- dozen for bet 3
             bet1_wins : out std_logic;  -- whether bet 1 is a winner
             bet2_wins : out std_logic;  -- whether bet 2 is a winner
             bet3_wins : out std_logic); -- whether bet 3 is a winner
END win;


ARCHITECTURE behavioural OF win IS
BEGIN

  -- bet 1 win detection logic
  process (all)
  begin
    -- bet 1 win detection
    if (spin_result_latched = bet1_value) then
      bet1_wins <= '1';   --'1' indicates a win
    else
      bet1_wins <= '0';   --'0' indicates a lose
    end if;
    
    -- bet 2 win detection
    if((1 <= spin_result_latched and spin_result_latched <= 10) or (19 <= spin_result_latched and spin_result_latched <= 28) ) then -- in range 1 to 10 or range 19 to 28
      if(spin_result_latched(0) = bet2_colour) then -- even = 0 = black or odd = 1 = red
        bet2_wins <= '1';
      else
        bet2_wins <= '0';
      end if;
    elsif((11 <= spin_result_latched and spin_result_latched <= 18) or (29 <= spin_result_latched and spin_result_latched <= 36) ) then -- in range 11 to 18 or range 29 to 36
      if(spin_result_latched(0) = not bet2_colour) then -- even = 0 = red or odd = 1 = black
        bet2_wins <= '1';
      else
        bet2_wins <= '0';
      end if;
    else
      bet2_wins <= '0';
   	end if;

    -- bet 3 win detection
    if ( spin_result_latched >= 1 and spin_result_latched <= 12 and bet3_dozen = "00") then
      bet3_wins <= '1'; -- if player guesses result is in range [1,12]
    elsif ( spin_result_latched >= 13 and spin_result_latched <= 24 and bet3_dozen = "01") then
      bet3_wins <= '1'; -- if player guesses result is in range [13,24]
    elsif ( spin_result_latched >= 25 and spin_result_latched <= 36 and bet3_dozen = "10") then
      bet3_wins <= '1'; -- if player guesses result is in range [25,36]
    else
      bet3_wins <= '0';
    end if;
  end process;
 
END;
