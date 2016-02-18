library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

-- Entity part of the description.  Describes inputs and outputs

entity ksa is
  port(clock : in  std_logic;  -- Clock pin
       reset : in  std_logic;
		 start_key : in unsigned(23 downto 0);
		 end_key : in unsigned(23 downto 0);
		 stop_search : in std_logic;
		 success : out std_logic);
end ksa;

-- Architecture part of the description

architecture rtl of ksa is

   -- Declare the component for the ram.  This should match the entity description 
	-- in the entity created by the megawizard. If you followed the instructions in the 
	-- handout exactly, it should match.  If not, look at s_memory.vhd and make the
	-- changes to the component below
	
   COMPONENT s_memory IS
	   PORT (
		   address		: IN STD_LOGIC_VECTOR (7 DOWNTO 0);
		   clock		: IN STD_LOGIC  := '1';
		   data		: IN STD_LOGIC_VECTOR (7 DOWNTO 0);
		   wren		: IN STD_LOGIC ;
		   q		: OUT STD_LOGIC_VECTOR (7 DOWNTO 0));
   END component;
	
	component encrypted_memory
	PORT
	(
		address		: IN STD_LOGIC_VECTOR (4 DOWNTO 0);
		clock		: IN STD_LOGIC  := '1';
		q		: OUT STD_LOGIC_VECTOR (7 DOWNTO 0)
	);
end component;

component decrypted_memory
	PORT
	(
		address		: IN STD_LOGIC_VECTOR (4 DOWNTO 0);
		clock		: IN STD_LOGIC  := '1';
		data		: IN STD_LOGIC_VECTOR (7 DOWNTO 0);
		wren		: IN STD_LOGIC ;
		q		: OUT STD_LOGIC_VECTOR (7 DOWNTO 0)
	);
end component;


	-- Enumerated type for the state variable.  You will likely be adding extra
	-- state names here as you complete your design
	
	type state_type is (state_brute_init, state_init, state_fill, state_swap_1, state_swap_2, 
							  state_swap_3, state_swap_4, state_swap_5, state_swap_6, 
							  state_decrypt_1, state_decrypt_2, state_decrypt_3, 
							  state_decrypt_4, state_decrypt_5, state_decrypt_6,
							  state_decrypt_7, state_decrypt_8, state_decrypt_9, 
							  state_decrypt_10, state_done);
								
    -- These are signals that are used to connect to the memory
	 signal address : STD_LOGIC_VECTOR (7 DOWNTO 0);	 
	 signal data : STD_LOGIC_VECTOR (7 DOWNTO 0);
	 signal wren : STD_LOGIC;
	 signal q : STD_LOGIC_VECTOR (7 DOWNTO 0);
	 
	 signal decrypted_address, encrypted_address	: STD_LOGIC_VECTOR (4 DOWNTO 0);
	 signal decrypted_data               		   : STD_LOGIC_VECTOR (7 DOWNTO 0);
	 signal decrypted_wren		                  : STD_LOGIC ;
	 signal decrypted_q, encrypted_q		         : STD_LOGIC_VECTOR (7 DOWNTO 0);
	 
	 begin
	 
	    -- Include the S memory structurally
	
       u0: s_memory port map (
	        address, clock, data, wren, q);
  
       -- write your code here.  As described in Slide Set 14, this 
       -- code will drive the address, data, and wren signals to
       -- fill the memory with the values 0...255
         
       -- You will be likely writing this is a state machine. Ensure
       -- that after the memory is filled, you enter a DONE state which
       -- does nothing but loop back to itself.
		 
		 encrypted_msg : encrypted_memory PORT MAP (
							  address	 => encrypted_address,
							  clock	 => clock,
							  q	 => encrypted_q);
							  
		 decrypted_msg : decrypted_memory PORT MAP (
							  address	 => decrypted_address,
							  clock	 => clock,
							  data	 => decrypted_data,
							  wren	 => decrypted_wren,
							  q	 => decrypted_q);

		 
		 -- reset is KEY(0)
		 process(clock, reset, stop_search)
			variable state : state_type := state_brute_init;
			variable i, j, k : integer;
			variable s_temp, s_temp2 : std_logic_vector(7 downto 0);
			variable secret_key : unsigned(23 downto 0);
			variable temp_key : unsigned(7 downto 0);
		 begin
			if reset = '0' then
				i := 0;
				j := 0;
				k := 0;
				state := state_brute_init;
			
			elsif rising_edge(clock) then
				case state is
					when state_brute_init =>
					   secret_key := start_key;
						state := state_init;
						success <= '0';
						
					when state_init =>
						i := 0;
						j := 0;
						k := 0;
						if stop_search = '1' then
							state := state_done;
						else
							state := state_fill;
						end if;
						wren <= '1';
					
					when state_fill =>
						address <= std_logic_vector(to_unsigned(i,8));
						data <= std_logic_vector(to_unsigned(i, 8));
						wren <= '1';
						i := i + 1;
						
						if i = 256 then
							i := 0;
							j := 0;
							state := state_swap_1;
						end if;
					
					when state_swap_1 =>
						-- read s[i]
						address <= std_logic_vector(to_unsigned(i,8));
						wren <= '0';
						state := state_swap_2;
						
					when state_swap_2 =>
						-- wait for s[i] to read
						state := state_swap_3;
					
					when state_swap_3 =>
						-- compute j
						-- s_temp = s[i]
						s_temp := q;
						case (i mod 3) is
							when 0 => temp_key := secret_key(23 downto 16);
							when 1 => temp_key := secret_key(15 downto 8);
							when 2 => temp_key := secret_key(7 downto 0);
							when others => temp_key := (others => '0');
						end case;
						j := (j + to_integer(unsigned(s_temp)) + to_integer(temp_key)) mod 256; 
					
						-- read s[j]
						address <= std_logic_vector(to_unsigned(j,8));
						wren <= '0';
						state := state_swap_4;
						
					when state_swap_4 =>
						-- wait for s[j] to read
						state := state_swap_5;
						
					when state_swap_5 =>
						-- write s[i] = s[j]
						address <= std_logic_vector(to_unsigned(i,8));
						data <= q;
						wren <= '1';
						state := state_swap_6;
						
					when state_swap_6 =>
						-- write s[j] = s_temp
						address <= std_logic_vector(to_unsigned(j,8));
						data <= s_temp;
						wren <= '1';
						
						if i = 255 then
							i := 0;
							j := 0;
							k := 0;
							state := state_decrypt_1;
						else
						   i := i + 1;
							state := state_swap_1;
						end if;

					when state_decrypt_1 =>
						i := (i + 1) mod 256;
						
						-- read s[i]
						address <= std_logic_vector(to_unsigned(i,8));
						wren <= '0';
						state := state_decrypt_2;
						
					when state_decrypt_2 =>
						-- wait for s[i] to read
						state := state_decrypt_3;
					
					when state_decrypt_3 =>
						-- compute j
						-- s_temp = s[i]
						s_temp := q;
						j := (j + to_integer(unsigned(s_temp))) mod 256; 
					
						-- read s[j]
						address <= std_logic_vector(to_unsigned(j,8));
						wren <= '0';
						state := state_decrypt_4;
						
					when state_decrypt_4 =>
						-- wait for s[j] to read
						state := state_decrypt_5;
						
					when state_decrypt_5 =>
						-- write s[i] = s[j]
						address <= std_logic_vector(to_unsigned(i,8));
						data <= q;
						wren <= '1';
						
						-- s_temp2 = s[j]
						s_temp2 := q;
						state := state_decrypt_6;
						
					when state_decrypt_6 =>
						-- write s[j] = s_temp
						address <= std_logic_vector(to_unsigned(j,8));
						data <= s_temp;
						wren <= '1';
						state := state_decrypt_7;
					
					when state_decrypt_7 =>
						-- read s[(s[i]+s[j]) mod 256]
						address <= std_logic_vector(to_unsigned((to_integer((unsigned(s_temp)) + to_integer(unsigned(s_temp2))) mod 256),8));
						wren <= '0';
						
						-- read encrypted_input[k] 
						encrypted_address <= std_logic_vector(to_unsigned(k, encrypted_address'length));
						state := state_decrypt_8;
					
					when state_decrypt_8 =>
					   decrypted_wren <= '0';
						-- wait for s[(s[i]+s[j]) mod 256] to be read
						-- wait for encrypted_input[k]  to be read
						state := state_decrypt_9;
						
					when state_decrypt_9 =>
						-- write to decrypted[k]
						decrypted_address <= std_logic_vector(to_unsigned(k, decrypted_address'length));
						decrypted_data <= q xor encrypted_q;
						state := state_decrypt_10;
						
					when state_decrypt_10 =>
						-- check if decrypted data is in range of [97, 122] or equal to 32
						if (decrypted_data >= std_logic_vector(to_unsigned(97, decrypted_data'length)) 
						and decrypted_data <= std_logic_vector(to_unsigned(122, decrypted_data'length)))
						or (decrypted_data = std_logic_vector(to_unsigned(32, decrypted_data'length))) then
							--write to D (RAM) and keep decrypting with the current key
							decrypted_wren <= '1';

							if k = 31 then
								success <= '1';
								state := state_done;
							else
								k := k + 1;
								state := state_decrypt_1;
							end if;
									
						else
							--increment secret_key and try again
							if to_integer(unsigned(secret_key)) = end_key then
								state := state_done;
							else
								secret_key := secret_key + 1;
								state := state_init;
							end if;
						end if;
						
					when state_done =>						
						-- do nothing
						state := state_done;
					   
					when others =>
						state := state_done;
					
				end case;
			end if;
		end process;
end RTL;


