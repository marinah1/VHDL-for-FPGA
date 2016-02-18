library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library work;
use work.lab4_pkg.all; -- types and constants that we will use
                       -- look in lab4_pkg.vhd to see these defns
							  
----------------------------------------------------------------
--
--  This file is the starting point for Lab 4.  This design implements
--  a simple pong game, with a paddle at the bottom and one ball that 
--  bounces around the screen.  When downloaded to an FPGA board, 
--  KEY(0) will move the paddle to right, and KEY(1) will move the 
--  paddle to the left.  KEY(3) will reset the game.  If the ball drops
--  below the bottom of the screen without hitting the paddle, the game
--  will reset.
--
--  This is written in a combined datapath/state machine style as
--  discussed in the second half of Slide Set 8.  It looks like a 
--  state machine, but the datapath operations that will be performed
--  in each state are described within the corresponding WHEN clause
--  of the state machine.  From this style, Quartus II will be able to
--  extract the state machine from the design.
--
--  In Lab 4, you will modify this file as described in the handout.
--
--  This file makes extensive use of types and constants described in
--  lab4_pkg.vhd    Be sure to read and understand that file before
--  trying to understand this one.
-- 
------------------------------------------------------------------------

-- Entity part of the description.  Describes inputs and outputs

entity lab4 is
  port(CLOCK_50            : in  std_logic;  -- Clock pin
       KEY                 : in  std_logic_vector(3 downto 0);  -- push button switches
		 SW						: in  std_logic_vector(17 downto 0);
       VGA_R, VGA_G, VGA_B : out std_logic_vector(9 downto 0);  -- The outs go to VGA controller
       VGA_HS              : out std_logic;
       VGA_VS              : out std_logic;
       VGA_BLANK           : out std_logic;
       VGA_SYNC            : out std_logic;
       VGA_CLK             : out std_logic);
end lab4;

-- Architecture part of the description

architecture rtl of lab4 is

  -- These are signals that will be connected to the VGA adapater.
  -- The VGA adapater was described in the Lab 3 handout.
  
  signal resetn : std_logic;
  signal x      : std_logic_vector(7 downto 0);
  signal y      : std_logic_vector(6 downto 0);
  signal colour : std_logic_vector(2 downto 0);
  signal plot   : std_logic;
  signal draw  : point;

  -- Be sure to see all the constants, types, etc. defined in lab4_pkg.vhd
  
begin

  -- include the VGA controller structurally.  The VGA controller 
  -- was decribed in Lab 3.  You probably know it in great detail now, but 
  -- if you have forgotten, please go back and review the description of the 
  -- VGA controller in Lab 3 before trying to do this lab.
  
  vga_u0 : vga_adapter
    generic map(RESOLUTION => "160x120") 
    port map(resetn    => SW(0),
             clock     => CLOCK_50,
             colour    => colour,
             x         => x,
             y         => y,
             plot      => plot,
             VGA_R     => VGA_R,
             VGA_G     => VGA_G,
             VGA_B     => VGA_B,
             VGA_HS    => VGA_HS,
             VGA_VS    => VGA_VS,
             VGA_BLANK => VGA_BLANK,
             VGA_SYNC  => VGA_SYNC,
             VGA_CLK   => VGA_CLK);

  -- the x and y lines of the VGA controller will be always
  -- driven by draw.x and draw.y.   The process below will update
  -- signals draw.x and draw.y.
  
  x <= std_logic_vector(draw.x(x'range));
  y <= std_logic_vector(draw.y(y'range));
  
  -- x <= std_logic_vector(draw.x(draw.x'left downto INT_BITS));
  -- y <= std_logic_vector(draw.y(draw.y'left-1 downto INT_BITS));
  
  -- =============================================================================
  
  -- This is the main process.  As described above, it is written in a combined
  -- state machine / datapath style.  It looks like a state machine, but rather
  -- than simply driving control signals in each state, the description describes 
  -- the datapath operations that happen in each state.  From this Quartus II
  -- will figure out a suitable datapath for you.
  
  -- Notice that this is written as a pattern-3 process (sequential with an
  -- asynchronous reset)
  
  controller_state : process(CLOCK_50, KEY)	 
  
    -- This variable will contain the state of our state machine.  The 
	 -- draw_state_type was defined above as an enumerated type	 
    variable state : draw_state_type := START; 
	 
    -- This variable will store the x position of the paddle (left-most pixel of the paddle)
	 variable paddle_x : unsigned(draw.x'range);
	 variable paddle_x2 : unsigned(draw.x'range);
	 
	 -- These variables will store the puck and the puck velocity.
	 -- In this implementation, the puck velocity has two components: an x component
	 -- and a y component.  Each component is always +1 or -1.
    -- variable puck :point;
	 -- variable puck_velocity : velocity;
	 variable puck1 : position;
	 variable puck2 : position;
	 variable puck1_velocity : velocity;
	 variable puck2_velocity : velocity;
	 
	 -- This will be used as a counter variable in the IDLE state
    variable clock_counter : natural := 0;	 
	 variable paddle_shrink_counter : natural := 0;
	 
	 -- This will be used to determine how many pixels to shrink the paddle every 20 seconds
	 variable paddle_shrink_width : natural := 0;
	 
	 -- variable to check if a ball has hit the paddle
	 variable puck_colour1 : unsigned(2 downto 0);
	 variable puck_colour2 : unsigned(2 downto 0);
 begin
 
    -- first see if the reset button has been pressed.  If so, we need to
	 -- reset to state INIT
	 
    if SW(0) = '0' then
           draw <= (x => to_unsigned(0, draw.x'length),
                 y => to_unsigned(0, draw.y'length));			  
           paddle_x := to_unsigned(PADDLE_X_START, paddle_x'length);
			  paddle_x2 := to_unsigned(PADDLE_X2_START, paddle_x'length);
			  
			  paddle_shrink_counter := 0;
			  paddle_shrink_width := 0;

			  /*
			  puck1.x := to_unsigned(FACEOFF_X1, puck1.x'length );
			  puck1.y := to_unsigned(FACEOFF_Y1, puck1.y'length );
			  puck1_velocity.x := to_signed(1, puck1_velocity.x'length );
			  puck1_velocity.y := to_signed(-1, puck1_velocity.y'length );	
			  puck2.x := to_unsigned(FACEOFF_X2, puck2.x'length );
			  puck2.y := to_unsigned(FACEOFF_Y2, puck2.y'length );
			  puck2_velocity.x := to_signed(1, puck2_velocity.x'length );
			  puck2_velocity.y := to_signed(1, puck2_velocity.y'length );
			*/
			  puck_colour1 := unsigned(YELLOW);
			  puck_colour2 := unsigned(CYAN); 
			
			  puck1.x := to_unsigned(FACEOFF_X1, FRAC_BITS) & to_unsigned(0, FRAC_BITS);
			  puck1.y := to_unsigned(FACEOFF_Y1, FRAC_BITS) & to_unsigned(0, FRAC_BITS);
			  puck1_velocity.x := to_signed(0, FRAC_BITS) & "11110110";
			  puck1_velocity.y := 0 - (to_signed(0, FRAC_BITS) & "01000000");
			  puck2.x := to_unsigned(FACEOFF_X2, FRAC_BITS) & to_unsigned(0, FRAC_BITS);
			  puck2.y := to_unsigned(FACEOFF_Y2, FRAC_BITS) & to_unsigned(0, FRAC_BITS);
			  puck2_velocity.x := to_signed(0, FRAC_BITS) & "11011100";
			  puck2_velocity.y := 0 - (to_signed(0, FRAC_BITS) & "10000000");
			
           colour <= BLACK;
			  plot <= '1';

	     state := INIT;
	
    -- Otherwise, see if we are here because of a rising clock edge.  This follows
	 -- the standard pattern for a type-3 process we saw in the lecture slides.
	 
    elsif rising_edge(CLOCK_50) then

      case state is
		
		  -- ============================================================
		  -- The INIT state sets the variables to their default values
		  -- ============================================================
		  
		  when INIT =>
 
           draw <= (x => to_unsigned(0, draw.x'length),
                 y => to_unsigned(0, draw.y'length));			  
           paddle_x := to_unsigned(PADDLE_X_START, paddle_x'length);
			  paddle_x2 := to_unsigned(PADDLE_X2_START, paddle_x'length);
			  
			  paddle_shrink_counter := 0;
			  paddle_shrink_width := 0;
			  
			  puck_colour1 := unsigned(YELLOW);
			  puck_colour2 := unsigned(CYAN); 
			  
			  puck1.x := to_unsigned(FACEOFF_X1, FRAC_BITS) & to_unsigned(0, FRAC_BITS);
			  puck1.y := to_unsigned(FACEOFF_Y1, FRAC_BITS) & to_unsigned(0, FRAC_BITS);
			  puck1_velocity.x := to_signed(0, FRAC_BITS) & "11110110";
			  puck1_velocity.y := 0 - (to_signed(0, FRAC_BITS) & "01000000");
			  puck2.x := to_unsigned(FACEOFF_X2, FRAC_BITS) & to_unsigned(0, FRAC_BITS);
			  puck2.y := to_unsigned(FACEOFF_Y2, FRAC_BITS) & to_unsigned(0, FRAC_BITS);
			  puck2_velocity.x := to_signed(0, FRAC_BITS) & "11011100";
			  puck2_velocity.y := 0 - (to_signed(0, FRAC_BITS) & "10000000");

			  colour <= BLACK;
			  plot <= '1';
			  state := START;  -- next state is START

		  -- ============================================================
        -- the START state is used to clear the screen.  We will spend many cycles
		  -- in this state, because only one pixel can be updated each cycle.  The  
		  -- counters in draw.x and draw.y will be used to keep track of which pixel 
		  -- we are erasing.  
		  -- ============================================================
		  
        when START =>	
		  
		    -- See if we are done erasing the screen		    
          if draw.x = SCREEN_WIDTH-1 then
            if draw.y = SCREEN_HEIGHT-1 then
				
				  -- We are done erasing the screen.  Set the next state 
				  -- to DRAW_TOP_ENTER

              state := DRAW_TOP_ENTER;	
		  
            else
				
				  -- In this cycle we will be erasing a pixel.  Update 
				  -- draw.y so that next time it will erase the next pixel
				  
              draw.y <= draw.y + to_unsigned(1, draw.y'length);
   			  draw.x <= to_unsigned(0, draw.x'length);				  
            end if;
          else	
	
            -- Update draw.x so next time it will erase the next pixel    
			  	
            draw.x <= draw.x + to_unsigned(1, draw.x'length);

          end if;

		  -- ============================================================
        -- The DRAW_TOP_ENTER state draws the first pixel of the bar on
		  -- the top of the screen.  The machine only stays here for
		  -- one cycle; the next cycle it is in DRAW_TOP_LOOP to draw the
		  -- rest of the bar.
		  -- ============================================================
		  
		  when DRAW_TOP_ENTER =>				
			     draw.x <= to_unsigned(LEFT_LINE, draw.x'length);
				  draw.y <= to_unsigned(TOP_LINE, draw.y'length);
				  colour <= WHITE;
				  state := DRAW_TOP_LOOP;
			  
		  -- ============================================================
        -- The DRAW_TOP_LOOP state is used to draw the rest of the bar on 
		  -- the top of the screen.
        -- Since we can only update one pixel per cycle,
        -- this will take multiple cycles
		  -- ============================================================
		  
        when DRAW_TOP_LOOP =>	
		  
           -- See if we have been in this state long enough to have completed the line
    		  if draw.x = RIGHT_LINE then
			     -- if so, the next state is DRAW_RIGHT_ENTER			  
              state := DRAW_RIGHT_ENTER; -- next state is DRAW_RIGHT
            else
				
				  -- Otherwise, update draw.x to point to the next pixel
              draw.y <= to_unsigned(TOP_LINE, draw.y'length);
              draw.x <= draw.x + to_unsigned(1, draw.x'length);
				  
				  -- Do not change the state, since we want to come back to this state
				  -- the next time we come through this process (at the next rising clock
				  -- edge) to finish drawing the line
				  
            end if;

		  -- ============================================================
        -- The DRAW_RIGHT_ENTER state draws the first pixel of the bar on
		  -- the right-side of the screen.  The machine only stays here for
		  -- one cycle; the next cycle it is in DRAW_RIGHT_LOOP to draw the
		  -- rest of the bar.
		  -- ============================================================
		  
		  when DRAW_RIGHT_ENTER =>				
			  draw.y <= to_unsigned(TOP_LINE, draw.x'length);
			  draw.x <= to_unsigned(RIGHT_LINE, draw.x'length);	
		     state := DRAW_RIGHT_LOOP;
   		  
		  -- ============================================================
        -- The DRAW_RIGHT_LOOP state is used to draw the rest of the bar on 
		  -- the right side of the screen.
        -- Since we can only update one pixel per cycle,
        -- this will take multiple cycles
		  -- ============================================================
		  
		  when DRAW_RIGHT_LOOP =>	

		  -- See if we have been in this state long enough to have completed the line
	   	  if draw.y = SCREEN_HEIGHT-1 then
		  
			     -- We are done, so the next state is DRAW_LEFT_ENTER	  
	 
              state := DRAW_LEFT_ENTER;	-- next state is DRAW_LEFT
            else

				  -- Otherwise, update draw.y to point to the next pixel				
              draw.x <= to_unsigned(RIGHT_LINE,draw.x'length);
              draw.y <= draw.y + to_unsigned(1, draw.y'length);
            end if;	

		  -- ============================================================
        -- The DRAW_LEFT_ENTER state draws the first pixel of the bar on
		  -- the left-side of the screen.  The machine only stays here for
		  -- one cycle; the next cycle it is in DRAW_LEFT_LOOP to draw the
		  -- rest of the bar.
		  -- ============================================================
		  
		  when DRAW_LEFT_ENTER =>				
			  draw.y <= to_unsigned(TOP_LINE, draw.x'length);
			  draw.x <= to_unsigned(LEFT_LINE, draw.x'length);	
		     state := DRAW_LEFT_LOOP;
   		  
		  -- ============================================================
        -- The DRAW_LEFT_LOOP state is used to draw the rest of the bar on 
		  -- the left side of the screen.
        -- Since we can only update one pixel per cycle,
        -- this will take multiple cycles
		  -- ============================================================
		  
		  when DRAW_LEFT_LOOP =>

		  -- See if we have been in this state long enough to have completed the line		  
          if draw.y = SCREEN_HEIGHT-1 then

			     -- We are done, so get things set up for the IDLE state, which 
				  -- comes next.  
				  
              state := IDLE;  -- next state is IDLE
				  clock_counter := 0;  -- initialize counter we will use in IDLE  
				  
            else
				
				  -- Otherwise, update draw.y to point to the next pixel					
              draw.x <= to_unsigned(LEFT_LINE, draw.x'length);
              draw.y <= draw.y + to_unsigned(1, draw.y'length);
            end if;	
				  
		  
		  -- ============================================================
        -- The IDLE state is basically a delay state.  If we didn't have this,
		  -- we'd be updating the puck location and paddle far too quickly for the
		  -- the user.  So, this state delays for 1/8 of a second.  Once the delay is
		  -- done, we can go to state ERASE_PADDLE.  Note that we do not try to
		  -- delay using any sort of wait statement: that won't work (not synthesziable).  
		  -- We have to build a counter to count a certain number of clock cycles.
		  -- ============================================================
		  
        when IDLE =>  
		  
		    -- See if we are still counting.  LOOP_SPEED indicates the maximum 
			 -- value of the counter
			 
			 plot <= '0';  -- nothing to draw while we are in this state
			 
          if clock_counter < LOOP_SPEED then
			    clock_counter := clock_counter + 1;
          else 
			 
			     -- otherwise, we are done counting.  So get ready for the 
				  -- next state which is ERASE_PADDLE_ENTER
				  
              clock_counter := 0;
              state := ERASE_PADDLE_ENTER;  -- next state
	  
			 end if;
			 
			 -- The paddle shrinks every 20 seconds. SHRINK_PADDLE_SPEED indicates the 
			 -- maximum value of this counter. 
			 
			 if paddle_shrink_counter < PADDLE_SHRINK_SPEED then
				 paddle_shrink_counter := paddle_shrink_counter + 1;
			 else
				 paddle_shrink_counter := 0;
				 
				 -- if the paddle is larger than PADDLE_WIDTH_MIN then we can shrink
				 -- the paddle further
				 if (paddle_shrink_width < (PADDLE_WIDTH - PADDLE_WIDTH_MIN)) then
					paddle_shrink_width := paddle_shrink_width + 1;
				 end if;
			 end if;

		  -- ============================================================
        -- In the ERASE_PADDLE_ENTER state, we will erase the first pixel of
		  -- the paddle. We will only stay here one cycle; the next cycle we will
		  -- be in ERASE_PADDLE_LOOP which will erase the rest of the pixels
		  -- ============================================================     		 

		  when ERASE_PADDLE_ENTER =>		  
              draw.y <= to_unsigned(PADDLE_ROW, draw.y'length);
		     	  draw.x <= paddle_x;	
              colour <= BLACK;
              plot <= '1';			
              state := ERASE_PADDLE_LOOP;				 
				  
		  -- ============================================================
        -- In the ERASE_PADDLE_LOOP state, we will erase the rest of the paddle. 
		  -- Since the paddle consists of multiple pixels, we will stay in this state for
		  -- multiple cycles.  draw.x will be used as the counter variable that
		  -- cycles through the pixels that make up the paddle.
		  -- ============================================================
		  
		  when ERASE_PADDLE_LOOP =>
		  
		      -- See if we are done erasing the paddle (done with this state)	
				if draw.x = paddle_x+PADDLE_WIDTH-paddle_shrink_width  then	
				  -- If so, the next state is DRAW_PADDLE_ENTER. 
				  
              state := DRAW_PADDLE_ENTER;  -- next state is DRAW_PADDLE 

            else

				  -- we are not done erasing the paddle.  Erase the pixel and update
				  -- draw.x by increasing it by 1
   		     draw.y <= to_unsigned(PADDLE_ROW, draw.y'length);
              draw.x <= draw.x + to_unsigned(1, draw.x'length);
				  
				  -- state stays the same, since we want to come back to this state
				  -- next time through the process (next rising clock edge) until 
				  -- the paddle has been erased
				  
            end if;

		  -- ============================================================
        -- The DRAW_PADDLE_ENTER state will start drawing the paddle.  In 
		  -- this state, the paddle position is updated based on the keys, and
		  -- then the first pixel of the paddle is drawn.  We then immediately
		  -- go to DRAW_PADDLE_LOOP to draw the rest of the pixels of the paddle.
		  -- ============================================================
		  
		  when DRAW_PADDLE_ENTER =>
		  
				  -- We need to figure out the x lcoation of the paddle before the 
				  -- start of DRAW_PADDLE_LOOP.  The x location does not change, unless
				  -- the user has pressed one of the buttons.
				  
				  if (KEY(0) = '0') then 
				  
				     -- If the user has pressed the right button check to make sure we
					  -- are not already at the rightmost position of the screen
					  
				     if paddle_x <= to_unsigned(RIGHT_LINE - PADDLE_WIDTH - 2 + paddle_shrink_width, paddle_x'length) then 

     					   -- add 2 to the paddle position
                  	paddle_x := paddle_x + to_unsigned(2, paddle_x'length) ;
					  end if;
				     -- If the user has pressed the right button check to make sure we
					  -- are not already at the rightmost position of the screen
					  
				  elsif (KEY(1) = '0') then
				  
				     -- If the user has pressed the left button check to make sure we
					  -- are not already at the leftmost position of the screen
				  
				     if paddle_x >= to_unsigned(LEFT_LINE + 2, paddle_x'length) then 				 
					 
					      -- subtract 2 from the paddle position 
   				      paddle_x := paddle_x - to_unsigned(2, paddle_x'length) ;						
					  end if;
				  end if;

              -- In this state, draw the first element of the paddle	
				  
   		     draw.y <= to_unsigned(PADDLE_ROW, draw.y'length);				  
				  draw.x <= paddle_x;  -- get ready for next state			  
              -- colour <= WHITE; -- when we draw the paddle, the colour will be WHITE	
				  colour <= PURPLE;
		        state := DRAW_PADDLE_LOOP;

		  -- ============================================================
        -- The DRAW_PADDLE_LOOP state will draw the rest of the paddle. 
		  -- Again, because we can only update one pixel per cycle, we will 
		  -- spend multiple cycles in this state.  
		  -- ============================================================
		  
		  when DRAW_PADDLE_LOOP =>
		  
		      -- See if we are done drawing the paddle

            if draw.x = paddle_x+PADDLE_WIDTH - paddle_shrink_width then
				
				  -- If we are done drawing the paddle, set up for the next state
				  
              plot  <= '0';  
              state := ERASE_PADDLE_ENTER2;	-- next state is ERASE_PUCK
				else		
				
				  -- Otherwise, update the x counter to the next location in the paddle 
              draw.y <= to_unsigned(PADDLE_ROW, draw.y'length);
              draw.x <= draw.x + to_unsigned(1, draw.x'length);

				  -- state stays the same so we come back to this state until we
				  -- are done drawing the paddle

				end if;

		  -- ============================================================
        -- In the ERASE_PADDLE_ENTER state, we will erase the first pixel of
		  -- the paddle. We will only stay here one cycle; the next cycle we will
		  -- be in ERASE_PADDLE_LOOP which will erase the rest of the pixels
		  -- ============================================================     		 

		  when ERASE_PADDLE_ENTER2 =>		  
              draw.y <= to_unsigned(PADDLE_ROW, draw.y'length);
		     	  draw.x <= paddle_x2;	
              colour <= BLACK;
              plot <= '1';			
              state := ERASE_PADDLE_LOOP2;				 
				  
		  -- ============================================================
        -- In the ERASE_PADDLE_LOOP state, we will erase the rest of the paddle. 
		  -- Since the paddle consists of multiple pixels, we will stay in this state for
		  -- multiple cycles.  draw.x will be used as the counter variable that
		  -- cycles through the pixels that make up the paddle.
		  -- ============================================================
		  
		  when ERASE_PADDLE_LOOP2 =>
		  
		      -- See if we are done erasing the paddle (done with this state)	
				if draw.x = paddle_x2+PADDLE_WIDTH-paddle_shrink_width then	
				  -- If so, the next state is DRAW_PADDLE_ENTER. 
				  
              state := DRAW_PADDLE_ENTER2;  -- next state is DRAW_PADDLE 

            else

				  -- we are not done erasing the paddle.  Erase the pixel and update
				  -- draw.x by increasing it by 1
   		     draw.y <= to_unsigned(PADDLE_ROW, draw.y'length);
              draw.x <= draw.x + to_unsigned(1, draw.x'length);
				  
				  -- state stays the same, since we want to come back to this state
				  -- next time through the process (next rising clock edge) until 
				  -- the paddle has been erased
				  
            end if;

		  -- ============================================================
        -- The DRAW_PADDLE_ENTER state will start drawing the paddle.  In 
		  -- this state, the paddle position is updated based on the keys, and
		  -- then the first pixel of the paddle is drawn.  We then immediately
		  -- go to DRAW_PADDLE_LOOP to draw the rest of the pixels of the paddle.
		  -- ============================================================
		  
		  when DRAW_PADDLE_ENTER2 =>
		  
				  -- We need to figure out the x lcoation of the paddle before the 
				  -- start of DRAW_PADDLE_LOOP.  The x location does not change, unless
				  -- the user has pressed one of the buttons.
				  
				  if (KEY(2) = '0') then 
				  
				     -- If the user has pressed the right button check to make sure we
					  -- are not already at the rightmost position of the screen
					  
				     if paddle_x2 <= to_unsigned(RIGHT_LINE - PADDLE_WIDTH - 2 + paddle_shrink_width, paddle_x2'length) then 

     					   -- add 2 to the paddle position
                  	paddle_x2 := paddle_x2 + to_unsigned(2, paddle_x2'length) ;
					  end if;
				     -- If the user has pressed the right button check to make sure we
					  -- are not already at the rightmost position of the screen
					  
				  elsif (KEY(3) = '0') then
				  
				     -- If the user has pressed the left button check to make sure we
					  -- are not already at the leftmost position of the screen
				  
				     if paddle_x2 >= to_unsigned(LEFT_LINE + 2, paddle_x2'length) then 				 
					 
					      -- subtract 2 from the paddle position 
   				      paddle_x2 := paddle_x2 - to_unsigned(2, paddle_x2'length) ;						
					  end if;
				  end if;

              -- In this state, draw the first element of the paddle	
				  
   		     draw.y <= to_unsigned(PADDLE_ROW, draw.y'length);				  
				  draw.x <= paddle_x2;  -- get ready for next state			  
              -- colour <= WHITE; -- when we draw the paddle, the colour will be WHITE	
				  colour <= GREEN;
		        state := DRAW_PADDLE_LOOP2;

		  -- ============================================================
        -- The DRAW_PADDLE_LOOP state will draw the rest of the paddle. 
		  -- Again, because we can only update one pixel per cycle, we will 
		  -- spend multiple cycles in this state.  
		  -- ============================================================
		  
		  when DRAW_PADDLE_LOOP2 =>
		  
		      -- See if we are done drawing the paddle

            if draw.x = paddle_x2+PADDLE_WIDTH - paddle_shrink_width then
				
				  -- If we are done drawing the paddle, set up for the next state
				  
              plot  <= '0';  
              state := ERASE_PUCK1;	-- next state is ERASE_PUCK
				else		
				
				  -- Otherwise, update the x counter to the next location in the paddle 
              draw.y <= to_unsigned(PADDLE_ROW, draw.y'length);
              draw.x <= draw.x + to_unsigned(1, draw.x'length);

				  -- state stays the same so we come back to this state until we
				  -- are done drawing the paddle

				end if;
				
		  -- ============================================================
        -- The ERASE_PUCK state erases the puck from its old location   
		  -- At also calculates the new location of the puck. Note that since
		  -- the puck is only one pixel, we only need to be here for one cycle.
		  -- ============================================================
		  
        when ERASE_PUCK1 =>
				  colour <= BLACK;  -- erase by setting colour to black
              plot <= '1';
				  --draw <= puck1;  -- the x and y lines are driven by "puck" which 
				                 -- holds the location of the puck
				  draw.x <= puck1.x(puck1.x'left downto INT_BITS);
				  draw.y <= puck1.y(puck1.y'left downto INT_BITS);
				  state := DRAW_PUCK1;  -- next state is DRAW_PUCK.

				  -- update the velocity of the puck (apply gravity)
				  
				  puck1_velocity.y := puck1_velocity.y + gravity;

				  -- update the location of the puck 
				  
				  puck1.x := unsigned( signed(puck1.x) + puck1_velocity.x);
				  puck1.y := unsigned( signed(puck1.y) + puck1_velocity.y);	
				  
				  -- See if we have bounced off the top of the screen
				  if puck1.y(puck1.y'left downto INT_BITS) <= TOP_LINE + 1 then
				     puck1_velocity.y := 0-puck1_velocity.y;
				  end if;

				  -- See if we have bounced off the right or left of the screen
				  if puck1.x(puck1.x'left downto INT_BITS) <= LEFT_LINE + 1 or
				     puck1.x(puck1.x'left downto INT_BITS) >= RIGHT_LINE - 1 then
				     puck1_velocity.x := 0-puck1_velocity.x;
				  end if;				  
		
              -- See if we have bounced of the paddle on the bottom row of
	           -- the screen		
				  
		        if puck1.y(puck1.y'left downto INT_BITS) >= PADDLE_ROW - 1 then
				     if puck1.x(puck1.x'left downto INT_BITS) >= paddle_x 
					   and puck1.x(puck1.x'left downto INT_BITS) <= paddle_x + PADDLE_WIDTH then
					  -- bug 
					  -- if puck.x >= paddle_x and puck.x <= paddle_x then
					  
					     -- we have bounced off the paddle
   				     --puck1_velocity.y := 0-puck1_velocity.y;
						  --puck1_velocity.y := 0 - resize(2*puck1_velocity.y, 16);
						  puck1_velocity.y := 0 - puck1_velocity.y;
						  
						  puck_colour1 := puck_colour1 + 1;
						  if (puck_colour1 = unsigned(BLACK)) then
								puck_colour1 := puck_colour1 + 1;
						  end if;
				     elsif puck1.x(puck1.x'left downto INT_BITS) >= paddle_x2 
					   and puck1.x(puck1.x'left downto INT_BITS) <= paddle_x2 + PADDLE_WIDTH then
					  -- bug 
					  -- if puck.x >= paddle_x and puck.x <= paddle_x then
					  
					     -- we have bounced off the paddle
   				     --puck1_velocity.y := 0-puck1_velocity.y;
						  --puck1_velocity.y := 0 - resize(2*puck1_velocity.y, 16);
						  puck1_velocity.y := 0 - puck1_velocity.y;
						  
						  puck_colour1 := puck_colour1 + 1;
						  if (puck_colour1 = unsigned(BLACK)) then
								puck_colour1 := puck_colour1 + 1;
						  end if;						  
				     else
				        -- we are at the bottom row, but missed the paddle.  Reset game!
					     state := INIT;
					  end if;	  
				  end if;
				  
		  -- ============================================================
        -- The DRAW_PUCK draws the puck.  Note that since
		  -- the puck is only one pixel, we only need to be here for one cycle.					 
		  -- ============================================================
		  
        when DRAW_PUCK1 =>
				  --colour <= WHITE;
				  colour <= std_logic_vector(puck_colour1);
              plot <= '1';
				  draw.x <= puck1.x(puck1.x'left downto INT_BITS);
				  draw.y <= puck1.y(puck1.y'left downto INT_BITS);
				  state := ERASE_PUCK2;	  -- next state is IDLE (which is the delay state)			  

        when ERASE_PUCK2 =>
				  colour <= BLACK;  -- erase by setting colour to black
              plot <= '1';
				  --draw <= puck1;  -- the x and y lines are driven by "puck" which 
				                 -- holds the location of the puck
				  draw.x <= puck2.x(puck2.x'left downto INT_BITS);
				  draw.y <= puck2.y(puck2.y'left downto INT_BITS);
				  state := DRAW_PUCK2;  -- next state is DRAW_PUCK.

				  -- update the velocity of the puck (apply gravity)
				  
				  puck2_velocity.y := puck2_velocity.y + gravity;
				  
				  -- update the location of the puck 
				  
				  puck2.x := unsigned( signed(puck2.x) + puck2_velocity.x);
				  puck2.y := unsigned( signed(puck2.y) + puck2_velocity.y);				  
				  
				  -- See if we have bounced off the top of the screen
				  if puck2.y(puck1.y'left downto INT_BITS) <= TOP_LINE + 1 then
				     puck2_velocity.y := 0-puck2_velocity.y;
				  end if;

				  -- See if we have bounced off the right or left of the screen
				  if puck2.x(puck2.x'left downto INT_BITS) <= LEFT_LINE + 1 or
				     puck2.x(puck2.x'left downto INT_BITS) >= RIGHT_LINE - 1 then
				     puck2_velocity.x := 0-puck2_velocity.x;
				  end if;				  
		
              -- See if we have bounced of the paddle on the bottom row of
	           -- the screen		
				  
		        if puck2.y(puck2.y'left downto INT_BITS) >= PADDLE_ROW - 1 then
				     if puck2.x(puck2.x'left downto INT_BITS) >= paddle_x 
					   and puck2.x(puck2.x'left downto INT_BITS) <= paddle_x + PADDLE_WIDTH then
					  -- bug 
					  -- if puck.x >= paddle_x and puck.x <= paddle_x then
					  
					     -- we have bounced off the paddle
   				     puck2_velocity.y := 0 - puck2_velocity.y;
						  
						  
						  puck_colour2 := puck_colour2 + 1;
						  if (puck_colour2 = unsigned(BLACK)) then
								puck_colour2 := puck_colour2 + 1;
						  end if;
				     elsif puck2.x(puck2.x'left downto INT_BITS) >= paddle_x2 
					   and puck2.x(puck2.x'left downto INT_BITS) <= paddle_x2 + PADDLE_WIDTH then
					  -- bug 
					  -- if puck.x >= paddle_x and puck.x <= paddle_x then
					  
					     -- we have bounced off the paddle
   				     puck2_velocity.y := 0 - puck2_velocity.y;
						  
						  
						  puck_colour2 := puck_colour2 + 1;
						  if (puck_colour2 = unsigned(BLACK)) then
								puck_colour2 := puck_colour2 + 1;
						  end if;					  
				    else
				        -- we are at the bottom row, but missed the paddle.  Reset game!
					     state := INIT;
					 end if;	  
				  end if;
				  
		  -- ============================================================
        -- The DRAW_PUCK draws the puck.  Note that since
		  -- the puck is only one pixel, we only need to be here for one cycle.					 
		  -- ============================================================
		  
        when DRAW_PUCK2 =>
				  -- colour <= WHITE;
				  colour <= std_logic_vector(puck_colour2);
              plot <= '1';
				  draw.x <= puck2.x(puck2.x'left downto INT_BITS);
				  draw.y <= puck2.y(puck2.y'left downto INT_BITS);
				  state := IDLE;	  -- next state is IDLE (which is the delay state)			  

 		  -- ============================================================
        -- We'll never get here, but good practice to include it anyway
		  -- ============================================================
		  
        when others =>
		    state := START;
			 
      end case;
	 end if;
   end process;
end RTL;


