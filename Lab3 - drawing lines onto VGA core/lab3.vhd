library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity lab3 is
  port(CLOCK_50, CLOCK_27  : in  std_logic;
       KEY                 : in  std_logic_vector(3 downto 0);
       SW                  : in  std_logic_vector(17 downto 0);
       VGA_R, VGA_G, VGA_B : out std_logic_vector(9 downto 0);  -- The outs go to VGA controller
       VGA_HS              : out std_logic;
       VGA_VS              : out std_logic;
       VGA_BLANK           : out std_logic;
       VGA_SYNC            : out std_logic;
       VGA_CLK             : out std_logic);
end lab3;

architecture rtl of lab3 is

 --Component from the Verilog file: vga_adapter.v

  component vga_adapter
    generic(RESOLUTION : string);
    port (resetn                                       : in  std_logic;
          clock                                        : in  std_logic;
          colour                                       : in  std_logic_vector(2 downto 0);
          x                                            : in  std_logic_vector(7 downto 0);
          y                                            : in  std_logic_vector(6 downto 0);
          plot                                         : in  std_logic;
          VGA_R, VGA_G, VGA_B                          : out std_logic_vector(9 downto 0);
          VGA_HS, VGA_VS, VGA_BLANK, VGA_SYNC, VGA_CLK : out std_logic);
  end component;

  signal xsig   : std_logic_vector(7 downto 0);
  signal ysig   : std_logic_vector(6 downto 0);
  signal colour : std_logic_vector(2 downto 0);
  signal plot   : std_logic;
  type state is (INIT, XLOOP, YLOOP, START3, STARTERR3, LOOP3, DONE2, DOCOUNT, DONE3);
  signal current_state : state;
  signal INITX, INITY, LOADY, XDONE, YDONE, INIT3, INITERR3, LOAD3, LDONE3, TASK2, INITCOUNT, LOADCOUNT, DONECOUNT : std_logic;
  signal scount50 : unsigned(18 downto 0);
  signal slow_clock : std_logic;

begin

  -- includes the vga adapter, which should be in your project 

  vga_u0 : vga_adapter
    generic map(RESOLUTION => "160x120") 
    port map(resetn    => KEY(3),
             clock     => CLOCK_50,
             colour    => colour,
             x         => xsig,
             y         => ysig,
             plot      => plot,
             VGA_R     => VGA_R,
             VGA_G     => VGA_G,
             VGA_B     => VGA_B,
             VGA_HS    => VGA_HS,
             VGA_VS    => VGA_VS,
             VGA_BLANK => VGA_BLANK,
             VGA_SYNC  => VGA_SYNC,
             VGA_CLK   => VGA_CLK);


  -- rest of your code goes here, as well as possibly additional files
  -- datapath
  --process(CLOCK_50)
  --process(KEY(1))
  process(slow_clock)
    variable Y : unsigned(6 downto 0);
    variable X : unsigned(7 downto 0);
	 variable e2 : signed(11 downto 0);
    variable x1, x0, dx, err : signed(8 downto 0);
    variable y1, y0, dy : signed(7 downto 0);
    --variable sx, sy : signed(1 downto 0);
	 variable sx, sy : std_logic;
	 variable count : unsigned(3 downto 0);
  begin
  --if rising_edge(KEY(1)) then
    --if rising_edge(CLOCK_50) then
	 if rising_edge(slow_clock) then
	 -- task 2
		if(TASK2 = '1') then
			if(INITY = '1') then
			  Y := "0000000";
			elsif(LOADY = '1') then
			  Y := Y + 1;
			end if;
			
			if(INITX = '1') then
			  X := "00000000";       
			else
			  X := X + 1;
			end if;
			
			XDONE <= '0';
			YDONE <= '0';
			
			if(Y = 119) then
			  YDONE <= '1';
			end if;
			if(X = 159) then
			  XDONE <= '1';
			end if;
			
		  colour <= "000";--colour <= std_logic_vector(resize(X mod 8,3));
		  xsig <= std_logic_vector(X);
		  ysig <= std_logic_vector(Y);
		end if;
		
  -- task 3
		if(INITCOUNT = '1') then
		  count := "0001";
		end if;
		if(LOADCOUNT = '1' and LDONE3 = '1') then
		  count := count + 1;
		end if;
		if(count >= "1110") then
		  DONECOUNT <= '1';
		else
		  DONECOUNT <= '0';
		end if;
		


				
      if(INIT3 = '1') then

			
			x0 := to_signed(0,9);
			y0 := to_signed(to_integer(count) * 8, 8);
			x1 := to_signed(159,9);
			y1 := to_signed(120 - to_integer(count) * 8, 8);
			dx := abs(x1-x0);
			dy := abs(y1-y0);
			if(x0 < x1) then
			  --sx := to_signed(1,2);
			  sx := '0';
			else 
			  --sx := to_signed(-1,2);
			  sx := '1';
			end if;
			if(y0 < y1) then
			  --sy := to_signed(1,2);
			  sy := '0';
			else 
			  --sy := to_signed(-1,2);
			  sy := '1';
			end if;
		end if;
    
		if(INITERR3 = '1') then
			err := dx - resize(dy, 9);
		end if;
		
      if(LOAD3 = '1') then
          case count is
			when "0001" => colour <= "100"; --Rgb
		   when "0010" => colour <= "010"; --rGb
			when "0011" => colour <= "001"; --rgB
			when "0100" => colour <= "110"; --RGb
			when "0101" => colour <= "011"; --rGB
			when "0110" => colour <= "111"; --RGB
			when "0111" => colour <= "111"; --RGB
			when "1000" => colour <= "111"; --RGB
			when "1001" => colour <= "111"; --RGB
			when "1010" => colour <= "111"; --RGB
			when "1011" => colour <= "111"; --RGB
			when "1100" => colour <= "111"; --RGB
			when "1101" => colour <= "111"; --RGB
			when "1110" => colour <= "111"; --RGB
			when "0000" => colour <= "101"; --RgB
			when "1111" => colour <= "111"; --RGB
			when others => colour <= "111"; --RGB
			end case;
			
		    xsig <= std_logic_vector(x0(7 downto 0));
		    ysig <= std_logic_vector(y0(6 downto 0));
		    if (x0 = x1 and y0 = y1) then
		      LDONE3 <= '1';
		    else
            LDONE3 <= '0';
            e2 := err * to_signed(2,3);
			 
			   if(x0 /= x1) then
			     if (e2 > -dy) then
				    err := err - resize(dy, 9);
				    --x0 := x0 + resize(sx,9);
					 if(sx = '0') then
					   x0 := x0 + 1;
					 elsif(sx = '1') then
					   x0 := x0 - 1;
					 end if;
				  end if;
			   end if;
			   if(y0 /= y1) then
			     if (e2 < dx) then
				    err := err + dx;
				    --y0 := y0 + resize(sy,8);
					 if(sy = '0') then
					   y0 := y0 + 1;
					 elsif(sy = '1') then
					   y0 := y0 - 1;
					 end if;
				  end if;
				end if;
				--xsig <= std_logic_vector(x0(7 downto 0));
		      --ysig <= std_logic_vector(y0(6 downto 0));
			end if;
		 end if;
	  end if;
  end process;
  
  -- controller state machine
--process(CLOCK_50, KEY(3), KEY(2))
process(slow_clock, KEY(3), KEY(2))
begin
  if(KEY(3) = '0') then
    current_state <= INIT;
  elsif(KEY(2) = '0') then
    current_state <= START3;
  --elsif(rising_edge(KEY(1))) then
  --elsif(rising_edge(CLOCK_50)) then
  --elsif(rising_edge(CLOCK_27)) then
  elsif(rising_edge(slow_clock)) then
    case current_state is
    when INIT => INITX <= '1';
		           INITY <= '1';
                 LOADY <= '1';
					  TASK2 <= '1';
                 plot <= '0';
                 current_state <= XLOOP;
    when XLOOP => INITX <= '0';
                  INITY <= '0';
                  LOADY <= '0';
                  plot <= '1';
                  if(XDONE = '0') then
                    current_state <= XLOOP;
                  elsif(YDONE = '0' and XDONE = '1') then
                    current_state <= YLOOP;
                  elsif(YDONE = '1') then
                    current_state <= DONE2;
                  end if;
    when YLOOP => INITX <= '1';
                  INITY <= '0';
                  LOADY <= '1';
                  plot <= '0';
                  current_state <= XLOOP;
	 -- task 3
	 when DONE2 => current_state <= START3;
	              TASK2 <= '0';
	              LOAD3 <= '0';
                 plot <= '0';
						INIT3 <= '0';
						INITERR3 <= '0';
						LOADCOUNT <= '0';
					  INITCOUNT <= '1';
    when START3 => current_state <= STARTERR3;
						LOADCOUNT <= '0';
                  INIT3 <= '1';
						plot <= '0';
						INITCOUNT <= '0';
    when STARTERR3 => current_state <= LOOP3;
                      INIT3 <= '0'; 
                      INITERR3 <= '1';
							 plot <= '0';
    when LOOP3 => LOAD3 <= '1';
						INITERR3 <= '0';
						plot <= '1';
	               if(LDONE3 = '1' and DONECOUNT = '1') then
                    current_state <= DONE3;
                  elsif(LDONE3 = '1' and DONECOUNT = '0') then
						  current_state <= DOCOUNT;
						else 
						  current_state <= LOOP3;
                  end if; 
	 when DOCOUNT => plot <= '0';
	                 LOAD3 <= '0';
	                 LOADCOUNT <= '1';
	                 current_state <= START3;
	 when DONE3 =>   LOAD3 <= '0';
						  plot <= '0';
						  current_state <= DONE3;
    when others => current_state <= INIT;
    end case;
 end if;
end process;
PROCESS (CLOCK_50)	
 variable count50 : unsigned(18 downto 0) := (others => '0');
 variable add50 : unsigned(7 downto 0);
 BEGIN
	  if rising_edge (CLOCK_50) THEN 
			count50 := count50 + 1;
			add50 := unsigned(SW(9 downto 2));
			count50 := count50 + add50;
			scount50 <= count50;
	  end if;
 END process;
  slow_clock <= scount50(18);   -- the output is the MSB of the counter
end RTL;