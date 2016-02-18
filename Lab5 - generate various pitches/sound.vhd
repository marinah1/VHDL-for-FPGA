LIBRARY ieee;
USE ieee.std_logic_1164.all;
use ieee.numeric_std.all;

ENTITY sound IS
	PORT (CLOCK_50,AUD_DACLRCK, AUD_ADCLRCK, AUD_BCLK,AUD_ADCDAT			:IN STD_LOGIC;
			CLOCK_27															:IN STD_LOGIC;
			KEY																:IN STD_LOGIC_VECTOR(3 DOWNTO 0);
			SW																	:IN STD_LOGIC_VECTOR(17 downto 0);
			I2C_SDAT															:INOUT STD_LOGIC;
			I2C_SCLK,AUD_DACDAT,AUD_XCK								:OUT STD_LOGIC);
END sound;

ARCHITECTURE Behavior OF sound IS

	   -- CODEC Cores
	
	COMPONENT clock_generator
		PORT(	CLOCK_27														:IN STD_LOGIC;
		    	reset															:IN STD_LOGIC;
				AUD_XCK														:OUT STD_LOGIC);
	END COMPONENT;

	COMPONENT audio_and_video_config
		PORT(	CLOCK_50,reset												:IN STD_LOGIC;
		    	I2C_SDAT														:INOUT STD_LOGIC;
				I2C_SCLK														:OUT STD_LOGIC);
	END COMPONENT;
	
	COMPONENT audio_codec
		PORT(	CLOCK_50,reset,read_s,write_s							:IN STD_LOGIC;
				writedata_left, writedata_right						:IN STD_LOGIC_VECTOR(23 DOWNTO 0);
				AUD_ADCDAT,AUD_BCLK,AUD_ADCLRCK,AUD_DACLRCK		:IN STD_LOGIC;
				read_ready, write_ready									:OUT STD_LOGIC;
				readdata_left, readdata_right							:OUT STD_LOGIC_VECTOR(23 DOWNTO 0);
				AUD_DACDAT													:OUT STD_LOGIC);
	END COMPONENT;

	SIGNAL read_ready, write_ready, read_s, write_s		      :STD_LOGIC;
	SIGNAL writedata_left, writedata_right							:STD_LOGIC_VECTOR(23 DOWNTO 0);	
	SIGNAL readdata_left, readdata_right							:STD_LOGIC_VECTOR(23 DOWNTO 0);	
	SIGNAL reset															:STD_LOGIC;
	
	constant AMP_CONST : integer := 131072;
	type state is (INIT, CALC, LOAD_FIFOS, UNTIL_READY);
	type count_array is array (6 downto 0) of integer range 0 to 127;
	constant count_maxes : count_array := (49,54,61,69,73,82,91);

BEGIN

	reset <= NOT(KEY(0));
	read_s <= '0';

	my_clock_gen: clock_generator PORT MAP (CLOCK_27, reset, AUD_XCK);
	cfg: audio_and_video_config PORT MAP (CLOCK_50, reset, I2C_SDAT, I2C_SCLK);
	codec: audio_codec PORT MAP(CLOCK_50,reset,read_s,write_s,writedata_left, writedata_right,AUD_ADCDAT,
	       AUD_BCLK,AUD_ADCLRCK,AUD_DACLRCK,read_ready, write_ready,readdata_left, readdata_right,AUD_DACDAT);

	process(CLOCK_50, reset)
		variable counts : count_array;
		variable high_flags : std_logic_vector(6 downto 0);
		variable current_state : state;
		variable sum : integer;
	begin
	if(reset = '1') then
		current_state := INIT;
	elsif(rising_edge(CLOCK_50)) then
		case current_state is
		when INIT => counts := (0,0,0,0,0,0,0);
						 high_flags := "1111111";
						 write_s <= '0';
						 current_state := CALC;
						 sum := 0;
						 
		when CALC => write_s <= '0';
		
						 for i in 0 to 6 loop
							 if(counts(i) >= count_maxes(i)) then
								 counts(i) := 0;
								 high_flags(i) := not high_flags(i);
							 end if;
						 end loop;

						 if(write_ready = '1') then
						    current_state := LOAD_FIFOS;
						 else
							 current_state := CALC;
						 end if;
						 
		when LOAD_FIFOS => for i in 0 to 6 loop
									 
									 if(SW(i) = '1') then
										 if(high_flags(i) = '1') then
											 sum := sum + AMP_CONST;		 
										 else
											 sum := sum - AMP_CONST;
										 end if;
									 end if;
									 counts(i) := counts(i) + 1;
								 end loop;
									 
							    writedata_left <= std_logic_vector(to_signed(sum, writedata_left'length));
							    writedata_right <= std_logic_vector(to_signed(sum, writedata_left'length));
								 
								 write_s <= '1';
								 current_state := UNTIL_READY;
								 
		when UNTIL_READY => sum := 0;
		
								  if(write_ready = '0') then
								     current_state := CALC;
								  else
							        current_state := UNTIL_READY;
						        end if;
		when others => current_state := INIT;
		end case;
	end if;
	end process;

END Behavior;