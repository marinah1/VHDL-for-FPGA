LIBRARY IEEE;
USE IEEE.STD_LOGIC_1164.ALL;
USE IEEE.NUMERIC_STD.ALL;
 
LIBRARY WORK;
USE WORK.ALL;

--------------------------------------------------------------
--
-- Skeleton file for new_balance subblock.  This block is purely
-- combinational (think Pattern 1 in the slides) and calculates the
-- new balance after adding winning bets and subtracting losing bets.
--
---------------------------------------------------------------


ENTITY new_balance IS
  PORT(money : in unsigned(11 downto 0);  -- Current balance before this spin
       value1 : in unsigned(2 downto 0);  -- Value of bet 1
       value2 : in unsigned(2 downto 0);  -- Value of bet 2
       value3 : in unsigned(2 downto 0);  -- Value of bet 3
       bet1_wins : in std_logic;  -- True if bet 1 is a winner
       bet2_wins : in std_logic;  -- True if bet 2 is a winner
       bet3_wins : in std_logic;  -- True if bet 3 is a winner
       new_money : out unsigned(11 downto 0));  -- balance after adding winning
                                                -- bets and subtracting losing bets
END new_balance;


ARCHITECTURE behavioural OF new_balance IS
BEGIN

process(all) 
  variable balance : unsigned(11 downto 0) ;
begin
  balance := money;
  if bet1_wins = '1' then
    balance := balance + to_unsigned(35,9) * value1; -- balance = balance + 35*bet1
  else
    balance := balance - resize(value1,12); -- balance = blance - bet1
  end if;
  
  if bet2_wins = '1' then
    balance := balance + resize(value2,12); -- balance = balance + bet2
  else
    balance := balance - resize(value2,12); -- balance = balance - bet2
  end if;
  
  if bet3_wins = '1' then
    balance := balance + to_unsigned(2,9) * value3; -- balance = balance + 2*bet3
  else
    balance := balance - resize(value3,12); -- balance = balance - bet3
  end if;
  new_money <= balance;
end process;

END;
