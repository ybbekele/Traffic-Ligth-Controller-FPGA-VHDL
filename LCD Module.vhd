library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.STD_LOGIC_ARITH.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL;
use work.LCD_DISP_PACKAGE.all;

entity CLPRefProj is
    Port ( 	rst:	in std_logic;									--reset input
				mclk:	in std_logic;									--clock input
				sw:	in std_logic;									--switch input for turning backlight on and off
				LCDIN: in LCD_CMDS_T;                      --LCD display data from FSM controller
				--lcd input signals
				DB:	out std_logic_vector(7 downto 0);		--output bus, used for data transfer
				RS:	out std_logic;  								--register selection pin
				RW:	out std_logic;									--selects between read/write modes
				E:		out std_logic;									--enable signal for starting the data read/write
				BL:		out std_logic								--backlight control pin
				);		
end CLPRefProj;

architecture Behavioral of CLPRefProj is
			    
------------------------------------------------------------------
--  Component Declarations
------------------------------------------------------------------

------------------------------------------------------------------
--  Local Type Declarations
-----------------------------------------------------------------
--  Symbolic names for all possible states of the state machines.

	--LCD control state machine
	type mstate is (					  
		stFunctionSet,		 				--Initialization states
		stDisplayCtrlSet,
		stDisplayClear,
		stPowerOn_Delay,  				--Delay states
		stFunctionSet_Delay,
		stDisplayCtrlSet_Delay, 	
		stDisplayClear_Delay,
		stInitDne,							--Display charachters and perform standard operations
		stActWr,
		stCharDelay							--Write delay for operations
	);

------------------------------------------------------------------
--  Signal Declarations and Constants
------------------------------------------------------------------
	--These constants are used to initialize the LCD pannel.

	--FunctionSet:
		--Bit 0 and 1 are arbitrary
		--Bit 2:  Displays font type(0=5x8, 1=5x11)
		--Bit 3:  Numbers of display lines (0=1, 1=2)
		--Bit 4:  Data length (0=4 bit, 1=8 bit)
		--Bit 5-7 are set
	--DisplayCtrlSet:
		--Bit 0:  Blinking cursor control (0=off, 1=on)
		--Bit 1:  Cursor (0=off, 1=on)
		--Bit 2:  Display (0=off, 1=on)
		--Bit 3-7 are set
	--DisplayClear:
		--Bit 1-7 are set	
	
	signal clk : std_logic;	
	signal dclk : std_logic;
	signal clkCount:	std_logic_vector (5 downto 0);
	signal dclkCount:	std_logic_vector (15 downto 0);
	signal count:		std_logic_vector (15 downto 0):= "0000000000000000";	--15 bit count variable for timing delays
	signal timeCount:   std_logic_vector (15 downto 0):= "0000000000000000";
	signal delayOK:	std_logic:= '0';							--High when count has reached the right delay time
	signal OneUSClk:	std_logic;									--Signal is treated as a 1.5 MHz clock	
	signal stCur:		mstate:= stPowerOn_Delay;				--LCD control state machine
	signal stNext:		mstate;			  	
	signal writeDone:	std_logic:= '0';							--Command set finish
    signal lcd_cmd_ptr : integer range 0 to 24 := 0; -- points to the index positions 
    signal LCD_CMDS:  LCD_CMDS_T;   --LCD display array from FSM 

	begin
LCD_CMDS <= LCDIN;
	
    --generate 50MHz clock 
    process(mclk)
        begin
            if(mclk'Event and mclk='1') then
                    clk <= not clk;
            end if;
        end process;
	--depending on sw 1 it turns the backlight on and off
	BL <= sw; 
	
	--This process counts to 50, and then resets.  It is used to divide the clock signal time.
	--This makes oneUSClock peak aprox. once every 1.5 microsecond
	process (CLK)
    	begin
		if (CLK = '1' and CLK'event) then
			if(clkCount = "100110") then
				clkCount <= "000000";
				oneUSClk <= not oneUSClk;
			else 
				clkCount <= clkCount + 1;
			end if;
		end if;
	end process;
	
	--This process increments the count variable unless delayOK = 1.
	process (oneUSClk, delayOK)
		begin
			if (oneUSClk = '1' and oneUSClk'event) then
				if delayOK = '1' then
					count <= "0000000000000000";
				else
					count <= count + 1;
				end if;
			end if;
		end process;

	--Determines when count has gotten to the right number, depending on the state.
	delayOK <= '1' when ((stCur = stPowerOn_Delay and count = "0011010000010101") or 			--13333 	-> 20 ms  
								(stCur = stFunctionSet_Delay and count = "0000000000011010") or		--26 		-> 40 us
								(stCur = stDisplayCtrlSet_Delay and count = "0000000000011010") or	--26 		-> 40 us
								(stCur = stDisplayClear_Delay and count = "0000010000101010") or		--1066 	-> 1,6 ms
								(stCur = stCharDelay and count = "0000010000101010")) 	--1000 --> 1.6ms -  Delay for character writes
					else '0';

	--writeDone goes high when all commands have been run
	writeDone <= '1' when (lcd_cmd_ptr = LCD_CMDS'HIGH + 1) 
					else '0';

	--Increments the pointer so the statemachine goes through the commands
	process (lcd_cmd_ptr, oneUSClk)
   		begin 
			if (oneUSClk = '1' and oneUSClk'event) then
				if ((stNext = stInitDne or stNext = stDisplayCtrlSet or stNext = stDisplayClear) and writeDone = '0') then 
					lcd_cmd_ptr <= lcd_cmd_ptr + 1;
				elsif (stCur = stPowerOn_Delay or stNext = stPowerOn_Delay) then
					lcd_cmd_ptr <= 0;
		        elsif (writeDone='1') then
                    lcd_cmd_ptr <= 3;
				--else
				--	lcd_cmd_ptr <= lcd_cmd_ptr;
				end if;
			end if;
		  
		end process;
	
	--This process runs the LCD state machine
	process (oneUSClk, rst)
		begin
			if oneUSClk = '1' and oneUSClk'Event then
				if rst = '1' then
					stCur <= stPowerOn_Delay;
				else
					stCur <= stNext;
				end if;
			end if;
		end process;

	
	--This process generates the sequence of outputs needed to initialize and write to the LCD screen
	process (stCur, delayOK, writeDone, lcd_cmd_ptr)
		begin   
			case stCur is
				--Delays the state machine for 20ms which is needed for proper startup.
				when stPowerOn_Delay =>
					if delayOK = '1' then
						stNext <= stFunctionSet;
					else
						stNext <= stPowerOn_Delay;
					end if;
					
				--This issues the function set to the LCD as follows 
				--8 bit data length, 1 lines, font is 5x8.
				when stFunctionSet =>
					stNext <= stFunctionSet_Delay;
				
				--Gives the proper delay of 37us between the function set and
				--the display control set.
				when stFunctionSet_Delay =>
					if delayOK = '1' then
						stNext <= stDisplayCtrlSet;
					else
						stNext <= stFunctionSet_Delay;
					end if;
				
				--Issuse the display control set as follows
				--Display ON,  Cursor OFF, Blinking Cursor OFF.
				when stDisplayCtrlSet =>
					stNext <= stDisplayCtrlSet_Delay;

				--Gives the proper delay of 37us between the display control set
				--and the Display Clear command. 
				when stDisplayCtrlSet_Delay =>
					if delayOK = '1' then
						stNext <= stDisplayClear;
					else
						stNext <= stDisplayCtrlSet_Delay;
					end if;
				
				--Issues the display clear command.
				when stDisplayClear	=>
					stNext <= stDisplayClear_Delay;

				--Gives the proper delay of 1.52ms between the clear command
				--and the state where you are clear to do normal operations.
				when stDisplayClear_Delay =>
					if delayOK = '1' then
						stNext <= stInitDne;
					else
						stNext <= stDisplayClear_Delay;
					end if;
				
				--State for normal operations for displaying characters, changing the
				--Cursor position etc.
				when stInitDne =>		
					stNext <= stActWr;

				when stActWr =>		
					stNext <= stCharDelay;
					
				--Provides a max delay between instructions.
				when stCharDelay =>
					if delayOK = '1' then
						stNext <= stInitDne;
					else
						stNext <= stCharDelay;
					end if;
			end case;	
		end process;					
	
	
		RS <= LCD_CMDS(lcd_cmd_ptr)(9);
		RW <= LCD_CMDS(lcd_cmd_ptr)(8);
		DB <= LCD_CMDS(lcd_cmd_ptr)(7 downto 0);
		E <= '1' when stCur = stFunctionSet or stCur = stDisplayCtrlSet or stCur = stDisplayClear or stCur = stActWr
				else '0';	
						
end Behavioral;