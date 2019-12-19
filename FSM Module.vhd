library ieee;
use ieee.std_logic_1164.all;

package LCD_DISP_PACKAGE is
  type LCD_CMDS_T is array(0 to 24) of std_logic_vector(9 downto 0); --user defined type for holding LCD commands
end package;

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.STD_LOGIC_ARITH.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL;
use work.LCD_DISP_PACKAGE.all;
-- Uncomment the following library declaration if using
-- arithmetic functions with Signed or Unsigned values
--use IEEE.NUMERIC_STD.ALL;

-- Uncomment the following library declaration if instantiating
-- any Xilinx leaf cells in this code.
--library UNISIM;
--use UNISIM.VComponents.all;

entity Traffic_Controller is
        Port (
        rst: in std_logic;  --reset controller
        mclk: in std_logic;
        clk: in std_logic;
        East_Car_Det: in std_logic;     --detect car presence on east road left turn lane
        West_Car_Det: in std_logic;     --detect car presence on west road left turn lane
        SE_Car_Det: in std_logic;    --detect car presence on south-east road
        TL : in std_logic_vector (15 downto 0);   --Long timer input from the timer
        TS : in std_logic_vector (15 downto 0);   --Short timer input from the timer
        STs: out std_logic;   --Start short timer upon expiration
        STl: out std_logic;   --Start short timer upon expiration
        LED: out std_logic_vector(14 downto 0);     --Traffic lights 
        LCDInput: out LCD_CMDS_T;
        modevga: out std_logic;  --mode signal to vga
        mode2: out std_logic; --TS change mode
        TLv: out std_logic_vector(15 downto 0);
        TSv: out std_logic_vector(15 downto 0);
        timeremain: out std_logic_vector(15 downto 0); 
        kpinput: in std_logic_vector(7 downto 0);
        SW: in std_logic_vector(1 downto 0)
   );
end Traffic_Controller;

architecture Traffic_FSM of Traffic_Controller is

--  State names for the different traffic states
    
    type state is (s0,s1,s2,s3,s4,s5,s6,s7,s8,s9,s10,s11,s12,s13); --user defined type for holding states
   	signal clkCount: std_logic_vector(15 downto 0):="0000000000000000";
	signal timeCount: std_logic_vector(15 downto 0):="0000000000000000";
	signal TLSet: std_logic:='0';        -- asserted when long timer expires(goes to the timer_Exp input)
    signal TSSet: std_logic:='0';        -- asserted when  short timer expires(goes to the timer_Exp input)
	signal currSt: state;		
    signal nextSt: state; 
    signal LCD_CMD : LCD_CMDS_T;   
    signal STSet:std_logic:='0';
    signal TScount: std_logic_vector(15 downto 0);--:="0000111110100000"; ---TS=4s
    signal TLcount: std_logic_vector(15 downto 0);--:="0001101101011000"; ---TL=7s
    signal TL1: std_logic_vector(15 downto 0);--:="0001101101011000";
    signal TS1: std_logic_vector(15 downto 0); --:="0000111110100000";
    signal timeleft: std_logic_vector(15 downto 0);
    signal vgamode: std_logic:='0';
    signal kpdatatemp: std_logic_vector(7 downto 0):=X"00";
    signal mode2s: std_logic:='0';
    signal mode: std_logic:='0';
    signal keyclk: std_logic; 
   begin
kpdatatemp<=kpinput;


TSSet <= '1' when (TS = TScount) --TS default value is 4 seconds
                             
              else 
            '0';
                    
  STs <= TSSet;

TLSet <= '1' when (TL = TLcount)  --TL default value is 8 seconds
                             
           else '0';
                    
 STl <= TLSet;
 process (TL)
 begin
 if (currSt=s2) then
        timeleft<=TLcount-TL;
     elsif( currSt=s6) then 
        timeleft<= TLcount-TL;
    elsif( currSt=s8) then 
        timeleft<= TLcount-TL;
     else
        timeleft<= TScount-TS;        --Timer count when TS;
     end if;
   timeremain<=timeleft;
end process;

--This process changes the long and short timers on the fly
 process(mode, mclk, kpdatatemp)
begin
if (mclk'event and mclk='1') then
if (SW="00") then
mode<='0';
--mode2s<='0';
TLCount<="0001111101000000";
TSCount<="0000111110100000";
--end if;

if (SW="11") then
mode<='0';
mode2s<='0';
if (mode2s='0') then 
if kpdatatemp=X"01" then TL1<= "0000011111010000"; --TL1= 01+1
elsif kpdatatemp=X"02" then TL1<= "0000101110111000";
elsif kpdatatemp=X"03" then TL1<= "0000111110100000";
elsif kpdatatemp=X"04" then TL1<= "0001001110001000";
elsif kpdatatemp=X"05" then TL1<= "0001011101110000";
elsif kpdatatemp=X"06" then TL1<= "0001101101011000";
elsif kpdatatemp=X"07" then TL1<= "0001111101000000";
elsif kpdatatemp=X"08" then TL1<= "0010001100101000";
elsif kpdatatemp=X"09" then TL1<= "0010011100010000";
else
TL1<="0001101101011000";
end if;
if kpdatatemp=X"01" then TS1<= "0000001111101000"; --TS1= 1s
elsif kpdatatemp=X"02" then TS1<= "0000011111010000";
elsif kpdatatemp=X"03" then TS1<= "0000101110111000";
elsif kpdatatemp=X"04" then TS1<= "0000111110100000";
elsif kpdatatemp=X"05" then TS1<= "0001001110001000";
elsif kpdatatemp=X"06" then TS1<= "0001011101110000";
elsif kpdatatemp=X"07" then TS1<= "0001101101011000";
elsif kpdatatemp=X"08" then TS1<= "0001111101000000";
elsif kpdatatemp=X"09" then TS1<= "0010001100101000";
elsif kpdatatemp=X"0A" then TS1<= "0010011100010000";
else
TS1<="0000111110100000";
end if;
end if;
end if;
end if;
end if;
vgamode<=mode;
mode2<=mode2s;
modevga<=vgamode;
TLv<= TLCount;
TSv<=TSCount;
end process; 
                 
  --this process block runs the state machine
   process(clk)
    begin
       if(clk = '1' and clk'event) then
            if(rst= '1')then
                currSt <= s0;
            else
                currSt <= nextSt;
            end if;
       end if;
    end process;
                    
   --Sequence of states 
   process(currSt,TLSet, TSSet, East_Car_Det, West_Car_Det, SE_Car_Det)
    begin
    nextSt <= currSt;
        case currSt is 
            when s0 =>
                if(TSSet = '0') then     --Short timer not expired
                    nextSt <= s0;
                else                        
                    nextSt <= s1;   --Short timer expired
                end if;
                
             when s1 =>
                 if(TSSet = '0') then 
                    nextSt <= s1;  --Short timer not expired
                 else
                    nextSt <= s2;   --Short timer expired
                end if;
             
             when s2 =>
                 if(TLSet = '0') then
                    nextSt <= s2; --Long timer not expired
                 else
                    nextSt <= s3;  --Long timer expired
                 end if;              
             
             when s3 =>
                  if(TSSet = '0') then
                     nextSt <= s3;  --Short timer not expired
                    else
                     nextSt <= s4;  --Short timer expired
                 end if;
               
             when s4 =>
                  if(TSSet = '0') then
                     nextSt <= s4;  --Short timer not expired
                  else
                     nextSt <= s5;   --Short timer expired
                 end if;
             
             when s5 =>
                  if(TSSet = '0') then
                     nextSt <= s5;  --Short timer not expired
                  elsif(TSSet = '1' and East_Car_Det = '1') then     
                     nextSt <= s10;  --Short timer expired and car detected on East road
                  elsif(TSSet = '1' and  West_Car_Det ='1') then     
                     nextSt <= s12;  --Short timer expired and car detected on West road
                  elsif(TSSet = '1' and  West_Car_Det ='0' and East_Car_Det = '0') then     
                     nextSt <= s6;  --Short timer expired and car not detected on east/west roads
                 end if;
                 
             when s6 =>
                if(TLSet = '0') then
                      nextSt <= s6;  --Short timer not expired
                else
                      nextSt <= s7; --Short timer expired
                end if;
                
             when s7 =>
                  if(TSSet = '0') then
                     nextSt <= s7;  --Short timer not expired
                   elsif(TSSet = '1' and SE_Car_Det = '1') then     
                     nextSt <= s8;  --Short timer expired and car detected on South East road
                   elsif(TSSet = '1' and SE_Car_Det = '0') then     
                     nextSt <= s0;  --Short timer expired and no car detected on South East road
                  end if;
            
            when s8 =>
                    if(TLSet = '0') then
                       nextSt <= s8; --Long timer not expired
                    else
                       nextSt <= s9;  --Long timer expired
                    end if;
                    
            when s9 =>
                  if(TSSet = '0') then
                     nextSt <= s9;  --Short timer not expired
                  else
                       nextSt <= s0;  --Short timer expired
                  end if;
                  
            when s10 =>
                  if(TSSet = '0') then
                     nextSt <= s10; --Short timer not expired
                  else
                     nextSt <= s11;  --Short timer expired
                  end if;
                  
            when s11 =>
                  if(TSSet = '0') then
                     nextSt <= s11; --Short timer not expired
                  else
                     nextSt <= s6;  --Short timer expired
                 end if;
                 
            when s12 =>
               if(TSSet = '0') then     
                  nextSt <= s12;  --Short timer not expired
               else        
                  nextSt <= s13; --Short timer expired
               end if;
               
            when s13 =>
              if(TSSet = '0') then
                 nextSt <= s13;  --Short timer not expired
              else
                 nextSt <= s6;    --Short timer expired
              end if;
              
                             
                end case;        
    end process;
    
    
   --this process block sets the outputs in each state
   
   process(currSt)
        begin
            case currSt is 
                when s0 =>
                    led <= "110000000000000";
                                LCD_CMD <= ( 	0 => "00"&X"3C",		--Function Set
                                               1 => "00"&X"0C",        --Display ON, Cursor OFF, Blink OFF
                                               2 => "00"&X"01",        --Clear Display
                                               3 => "00"&X"02",         --return home
                                       
                                                4 => "10"&X"4E",         --N 
                                                                          5 => "10"&X"47",         --G
                                                                                          
                                                                          6 => "10"&X"20",         --blank
                                                                                          
                                                                          7 => "10"&X"53",         --S
                                                                          8 => "10"&X"52",         --R
                                                                                                                      
                                                                          9 => "10"&X"20",        --blank
                                                                                                                      
                                                                          10 => "10"&X"45",         --E
                                                                          11 => "10"&X"52",         --R
                                                                                          
                                                                          12 => "10"&X"20",        --blank
                                                                  
                                                                          13 => "10"&X"57",         --W
                                                                          14 => "10"&X"52",         --R
                                                                  
                                                                          15 => "10"&X"20",         --blank
                                                                  
                                                                          16 => "10"&X"53",         --S
                                                                          17 => "10"&X"45",         --E
                                                                          18 => "10"&X"52",         --R   
                                                                                       
                                                                          19 => "00"&X"C0",               
                                                                  
                                                                          20 => "10"&X"4E",         --N
                                                                          21 => "10"&X"41",          --A 
                                                                          22 => "10"&X"47",         --G
                                                                                          
                                                                          23 => "10"&X"20",         --blank
                                                                                          
                                                                          24 => "00"&X"10");        --no shift
                                     
                                       
                                   when s1 =>
                                       led <= "100000000000000";
                                       LCD_CMD <= (     0 => "00"&X"3C",        --Function Set
                                               1 => "00"&X"0C",        --Display ON, Cursor OFF, Blink OFF
                                               2 => "00"&X"01",        --Clear Display
                                               3 => "00"&X"02",         --return home
                                       
                                                4 => "10"&X"4E",         --N 
                                                                          5 => "10"&X"47",         --G
                                                                                          
                                                                          6 => "10"&X"20",         --blank
                                                                                          
                                                                          7 => "10"&X"53",         --S
                                                                          8 => "10"&X"52",         --R
                                                                                                                      
                                                                          9 => "10"&X"20",        --blank
                                                                                                                      
                                                                          10 => "10"&X"45",         --E
                                                                          11 => "10"&X"52",         --R
                                                                                          
                                                                          12 => "10"&X"20",        --blank
                                                                  
                                                                          13 => "10"&X"57",         --W
                                                                          14 => "10"&X"52",         --R
                                                                  
                                                                          15 => "10"&X"20",               --blank
                                                                  
                                                                          16 => "10"&X"53",         --S
                                                                          17 => "10"&X"45",         --E
                                                                          18 => "10"&X"52",        --R   
                                                                                       
                                                                          19 => "00"&X"C0",         --next line 
                                                                  
                                                                           20 => "10"&X"4E",         --N
                                                                          21 => "10"&X"41",          --A 
                                                                          22 => "10"&X"59",         --Y
                                                                                          
                                                                          23 => "10"&X"20",         --blank
                                                                                          
                                                                                              
                                                                      24 => "00"&X"10");            
                                  
                                       
                                   when s2 =>
                                       led <= "111111000000000";
                                       LCD_CMD <= (     0 => "00"&X"3C",        --Function Set
                                               1 => "00"&X"0C",        --Display ON, Cursor OFF, Blink OFF
                                               2 => "00"&X"01",        --Clear Display
                                               3 => "00"&X"02",         --return home
                                       
                                                4 => "10"&X"4E",         --N 
                                                                         5 => "10"&X"47",         --G
                                                                                         
                                                                         6 => "10"&X"20",         --blank
                                                                                         
                                                                         7 => "10"&X"53",         --S
                                                                         8 => "10"&X"47",         --G
                                                                                                                     
                                                                         9 => "10"&X"20",        --blank
                                                                                                                     
                                                                         10 => "10"&X"45",         --E
                                                                         11 => "10"&X"52",         --R
                                                                                         
                                                                         12 => "10"&X"20",        --blank
                                                                 
                                                                         13 => "10"&X"57",         --W
                                                                         14 => "10"&X"52",         --R
                                                                 
                                                                         15 => "10"&X"20",        --blank
                                                                 
                                                                         16 => "10"&X"53",         --S
                                                                         17 => "10"&X"45",         --E
                                                                         18 => "10"&X"52",        --R   
                                                                                      
                                                                         19 => "00"&X"C0",         --next line 
                                                                 
                                                                         20 => "10"&X"20",         --blank
                                                                         21 => "10"&X"20",         --blank
                                                                                         
                                                                         22 => "10"&X"20",         --blank
                                                                         23 => "10"&X"20",         --blank
                                                                                         
                                                                                           
                                                                        24 => "00"&X"10");            
                                       
                                   when s3 =>
                                       led <= "101111000000000";
                                       LCD_CMD <= (     0 => "00"&X"3C",        --Function Set
                                               1 => "00"&X"0C",        --Display ON, Cursor OFF, Blink OFF
                                               2 => "00"&X"01",        --Clear Display
                                               3 => "00"&X"02",         --return home
                                       
                                                4 => "10"&X"4E",         --N 
                                                                          5 => "10"&X"59",         --Y
                                                                                          
                                                                          6 => "10"&X"20",         --blank
                                                                                          
                                                                          7 => "10"&X"53",         --S
                                                                          8 => "10"&X"47",         --G
                                                                                                                      
                                                                          9 => "10"&X"20",        --blank
                                                                                                                      
                                                                          10 => "10"&X"45",         --E
                                                                          11 => "10"&X"52",         --R
                                                                                          
                                                                          12 => "10"&X"20",        --blank
                                                                  
                                                                          13 => "10"&X"57",         --W
                                                                          14 => "10"&X"52",         --R
                                                                  
                                                                          15 => "10"&X"20",         --blank
                                                                  
                                                                          16 => "10"&X"53",         --S
                                                                          17 => "10"&X"45",         --E
                                                                          18 => "10"&X"52",         --R   
                                                                                       
                                                                          19 => "00"&X"C0",         --next line 
                                                                  
                                                                          20 => "10"&X"20",         --blank
                                                                          21 => "10"&X"20",         --blank
                                                                                          
                                                                          22 => "10"&X"20",         --blank
                                                                          23 => "10"&X"20",         --blank                
                                                                                            
                                                                         24 => "00"&X"10");           
                                   when s4 =>
                                       led <= "000110000000000";
                                       LCD_CMD <= (     0 => "00"&X"3C",        --Function Set
                                               1 => "00"&X"0C",        --Display ON, Cursor OFF, Blink OFF
                                               2 => "00"&X"01",        --Clear Display
                                               3 => "00"&X"02",         --return home
                                       
                                                4 => "10"&X"4E",         --N 
                                                                          5 => "10"&X"52",         --R
                                                                                          
                                                                          6 => "10"&X"20",         --blank
                                                                                          
                                                                          7 => "10"&X"53",         --S
                                                                          8 => "10"&X"47",         --G
                                                                                                                      
                                                                          9 => "10"&X"20",        --blank
                                                                                                                      
                                                                          10 => "10"&X"45",         --E
                                                                          11 => "10"&X"52",         --R
                                                                                          
                                                                          12 => "10"&X"20",        --blank
                                                                  
                                                                          13 => "10"&X"57",         --W
                                                                          14 => "10"&X"52",         --R
                                                                  
                                                                          15 => "10"&X"20",          --blank
                                                                  
                                                                          16 => "10"&X"53",         --S
                                                                          17 => "10"&X"45",         --E
                                                                          18 => "10"&X"52",         --R   
                                                                                       
                                                                          19 => "00"&X"C0",         --next line 
                                                                  
                                                                           20 => "10"&X"53",         --S
                                                                          21 => "10"&X"41",          --A 
                                                                          22 => "10"&X"47",         --G
                                                                                          
                                                                          23 => "10"&X"20",         --blank
                                                                                          
                                                                                            
                                                                         24 => "00"&X"10");            
                                   when s5 =>
                                       led <= "000100000000000";
                                       LCD_CMD <= (     0 => "00"&X"3C",        --Function Set
                                               1 => "00"&X"0C",        --Display ON, Cursor OFF, Blink OFF
                                               2 => "00"&X"01",        --Clear Display
                                               3 => "00"&X"02",         --return home
                                       
                                               4 => "10"&X"4E",         --N 
                                                                          5 => "10"&X"52",         --R
                                                                                          
                                                                          6 => "10"&X"20",         --blank
                                                                                          
                                                                          7 => "10"&X"53",         --S
                                                                          8 => "10"&X"59",         --Y
                                                                                                                      
                                                                          9 => "10"&X"20",        --blank
                                                                                                                      
                                                                          10 => "10"&X"45",         --E
                                                                          11 => "10"&X"52",         --R
                                                                                          
                                                                          12 => "10"&X"20",        --blank
                                                                  
                                                                          13 => "10"&X"57",         --W
                                                                          14 => "10"&X"52",         --R
                                                                  
                                                                          15 => "10"&X"20",         --blank
                                                                  
                                                                          16 => "10"&X"53",         --S
                                                                          17 => "10"&X"45",         --E
                                                                          18 => "10"&X"52",         --R   
                                                                                       
                                                                          19 => "00"&X"C0",         --next line 
                                                                  
                                                                           20 => "10"&X"53",         --S
                                                                          21 => "10"&X"41",          --A 
                                                                          22 => "10"&X"59",         --Y
                                                                                          
                                                                          23 => "10"&X"20",         --blank
                                                                                          
                                                                                            
                                                                         24 => "00"&X"10");            --
                                   when s6 =>
                                       
                                       led <= "000000111111000";
                                       LCD_CMD <= (     0 => "00"&X"3C",        --Function Set
                                               1 => "00"&X"0C",        --Display ON, Cursor OFF, Blink OFF
                                               2 => "00"&X"01",        --Clear Display
                                               3 => "00"&X"02",         --return home
                                       
                                               4 => "10"&X"4E",         --N 
                                                                          5 => "10"&X"52",         --R
                                                                                          
                                                                          6 => "10"&X"20",         --blank
                                                                                          
                                                                          7 => "10"&X"53",         --S
                                                                          8 => "10"&X"52",         --R
                                                                                                                      
                                                                          9 => "10"&X"20",        --blank
                                                                                                                      
                                                                          10 => "10"&X"45",         --E
                                                                          11 => "10"&X"47",         --G
                                                                                          
                                                                          12 => "10"&X"20",        --blank
                                                                  
                                                                          13 => "10"&X"57",         --W
                                                                          14 => "10"&X"47",         --G
                                                                  
                                                                          15 => "10"&X"20",          --blank
                                                                  
                                                                          16 => "10"&X"53",         --S
                                                                          17 => "10"&X"45",         --E
                                                                          18 => "10"&X"52",         --R   
                                                                                       
                                                                          19 => "00"&X"C0",         --next line 
                                                                  
                                                                           20 => "10"&X"20",         --blank
                                                                          21 => "10"&X"20",          --blank 
                                                                          22 => "10"&X"20",         --blank
                                                                                          
                                                                          23 => "10"&X"20",         --blank
                                                                                          
                                                                                            
                                                                         24 => "00"&X"10");            --
                                       
                                   when s7 =>
                                       led <= "000000101101000";
                                       LCD_CMD <= (     0 => "00"&X"3C",        --Function Set
                                               1 => "00"&X"0C",        --Display ON, Cursor OFF, Blink OFF
                                               2 => "00"&X"01",        --Clear Display
                                               3 => "00"&X"02",         --return home
                                       
                                                4 => "10"&X"4E",         --N 
                                                                          5 => "10"&X"52",         --R
                                                                                          
                                                                          6 => "10"&X"20",         --blank
                                                                                          
                                                                          7 => "10"&X"53",         --S
                                                                          8 => "10"&X"52",         --R
                                                                                                                      
                                                                          9 => "10"&X"20",        --blank
                                                                                                                      
                                                                          10 => "10"&X"45",         --E
                                                                          11 => "10"&X"59",         --Y
                                                                                          
                                                                          12 => "10"&X"20",        --blank
                                                                  
                                                                          13 => "10"&X"57",         --W
                                                                          14 => "10"&X"59",         --Y
                                                                  
                                                                          15 => "10"&X"20",         --blank
                                                                  
                                                                          16 => "10"&X"53",         --S
                                                                          17 => "10"&X"45",         --E
                                                                          18 => "10"&X"52",         --R 
                                                                                       
                                                                          19 => "00"&X"C0",         --next line 
                                                                  
                                                                           20 => "10"&X"20",         --blank
                                                                          21 => "10"&X"20",          --blank
                                                                          22 => "10"&X"20",         --blank
                                                                                          
                                                                          23 => "10"&X"20",         --blank
                                                                                          
                                                                                            
                                                                         24 => "00"&X"10");           
                                       
                   
                                   when s8 =>
                                    
                                       led <= "000000000000111";
                                       LCD_CMD <= (     0 => "00"&X"3C",        --Function Set
                                               1 => "00"&X"0C",        --Display ON, Cursor OFF, Blink OFF
                                               2 => "00"&X"01",        --Clear Display
                                               3 => "00"&X"02",         --return home
                                       
                                                4 => "10"&X"4E",         --N 
                                                                          5 => "10"&X"52",         --R
                                                                                          
                                                                          6 => "10"&X"20",         --blank
                                                                                          
                                                                          7 => "10"&X"53",         --S
                                                                          8 => "10"&X"52",         --R
                                                                                                                      
                                                                          9 => "10"&X"20",        --blank
                                                                                                                      
                                                                          10 => "10"&X"45",         --E
                                                                          11 => "10"&X"52",         --R
                                                                                          
                                                                          12 => "10"&X"20",        --blank
                                                                  
                                                                          13 => "10"&X"57",         --W
                                                                          14 => "10"&X"52",         --R
                                                                  
                                                                          15 => "10"&X"20",         --blank
                                                                  
                                                                          16 => "10"&X"53",         --S
                                                                          17 => "10"&X"45",         --E
                                                                          18 => "10"&X"47",         --G   
                                                                                       
                                                                          19 => "00"&X"C0",         --next line 
                                                                  
                                                                           20 => "10"&X"20",         --blank
                                                                          21 => "10"&X"20",          --blank
                                                                          22 => "10"&X"20",         --blank
                                                                                          
                                                                          23 => "10"&X"20",         --blank
                                                                                          
                                                                                            
                                                                         24 => "00"&X"10");            -- 
                                   when s9 =>
                                      
                                       led <= "000000000000010";
                                       LCD_CMD <= (     0 => "00"&X"3C",        --Function Set
                                               1 => "00"&X"0C",        --Display ON, Cursor OFF, Blink OFF
                                               2 => "00"&X"01",        --Clear Display
                                               3 => "00"&X"02",         --return home
                                       
                                               4 => "10"&X"4E",         --N 
                                                                          5 => "10"&X"52",         --R
                                                                                          
                                                                          6 => "10"&X"20",         --blank
                                                                                          
                                                                          7 => "10"&X"53",         --S
                                                                          8 => "10"&X"52",         --R
                                                                                                                      
                                                                          9 => "10"&X"20",        --blank
                                                                                                                      
                                                                          10 => "10"&X"45",         --E
                                                                          11 => "10"&X"52",         --R
                                                                                          
                                                                          12 => "10"&X"20",        --blank
                                                                  
                                                                          13 => "10"&X"57",         --W
                                                                          14 => "10"&X"52",         --R
                                                                  
                                                                          15 => "10"&X"20",         --blank
                                                                  
                                                                          16 => "10"&X"53",         --S
                                                                          17 => "10"&X"45",         --E
                                                                          18 => "10"&X"59",         --Y  
                                                                                       
                                                                          19 => "00"&X"C0",         --next line 
                                                                  
                                                                           20 => "10"&X"20",         --blank
                                                                          21 => "10"&X"20",          --blank
                                                                          22 => "10"&X"20",         --blank
                                                                                          
                                                                          23 => "10"&X"20",         --blank
                                                                                          
                                                                                            
                                                                         24 => "00"&X"10");            --
                                   when s10 =>
                                       
                                       led <= "000000110000000";
                                       LCD_CMD <= (     0 => "00"&X"3C",        --Function Set
                                               1 => "00"&X"0C",        --Display ON, Cursor OFF, Blink OFF
                                               2 => "00"&X"01",        --Clear Display
                                               3 => "00"&X"02",         --return home
                                       
                                              4 => "10"&X"4E",         --N 
                                                                           5 => "10"&X"52",         --R
                                                                                           
                                                                           6 => "10"&X"20",         --blank
                                                                                           
                                                                           7 => "10"&X"53",         --S
                                                                           8 => "10"&X"52",         --R
                                                                                                                       
                                                                           9 => "10"&X"20",        --blank
                                                                                                                       
                                                                           10 => "10"&X"45",         --E
                                                                           11 => "10"&X"47",         --G
                                                                                           
                                                                           12 => "10"&X"20",        --blank
                                                                   
                                                                           13 => "10"&X"57",         --W
                                                                           14 => "10"&X"52",         --R
                                                                   
                                                                           15 => "10"&X"20",         --blank
                                                                   
                                                                           16 => "10"&X"53",         --S
                                                                           17 => "10"&X"45",         --E
                                                                           18 => "10"&X"52",         --R   
                                                                                        
                                                                           19 => "00"&X"C0",         --next line 
                                                                   
                                                                            20 => "10"&X"45",         --E
                                                                           21 => "10"&X"41",          --A 
                                                                           22 => "10"&X"47",         --G
                                                                                           
                                                                           23 => "10"&X"20",         --blank
                                                                                           
                                                                                             
                                                                          24 => "00"&X"10");            --
                   
                                       
                                   when s11 =>
                                      
                                       led <= "000000100000000";
                                       LCD_CMD <= (     0 => "00"&X"3C",        --Function Set
                                               1 => "00"&X"0C",        --Display ON, Cursor OFF, Blink OFF
                                               2 => "00"&X"01",        --Clear Display
                                               3 => "00"&X"02",         --return home
                                       
                                              4 => "10"&X"4E",         --N 
                                                                           5 => "10"&X"52",         --R
                                                                                           
                                                                           6 => "10"&X"20",         --blank
                                                                                           
                                                                           7 => "10"&X"53",         --S
                                                                           8 => "10"&X"52",         --R
                                                                                                                       
                                                                           9 => "10"&X"20",        --blank
                                                                                                                       
                                                                           10 => "10"&X"45",         --E
                                                                           11 => "10"&X"47",         --G
                                                                                           
                                                                           12 => "10"&X"20",        --blank
                                                                   
                                                                           13 => "10"&X"57",         --W
                                                                           14 => "10"&X"52",         --R
                                                                   
                                                                           15 => "10"&X"20",         --blank
                                                                   
                                                                           16 => "10"&X"53",         --S
                                                                           17 => "10"&X"45",         --E
                                                                           18 => "10"&X"52",         --R   
                                                                                        
                                                                           19 => "00"&X"C0",         --next line 
                                                                   
                                                                            20 => "10"&X"45",         --S
                                                                           21 => "10"&X"41",          --A 
                                                                           22 => "10"&X"59",         --Y
                                                                                           
                                                                           23 => "10"&X"20",         --blank
                                                                                           

                                                                                             
                                                                          24 => "00"&X"10");            --
                                       
                                   when s12 =>
                                      

                                       led <= "000000000110000";
                                       LCD_CMD <= (     0 => "00"&X"3C",        --Function Set
                                               1 => "00"&X"0C",        --Display ON, Cursor OFF, Blink OFF
                                               2 => "00"&X"01",        --Clear Display
                                               3 => "00"&X"02",         --return home
                                       
                                                4 => "10"&X"4E",         --N 
                                                                         5 => "10"&X"52",         --R
                                                                                         
                                                                         6 => "10"&X"20",         --blank
                                                                                         
                                                                         7 => "10"&X"53",         --S
                                                                         8 => "10"&X"52",         --R
                                                                                                                     
                                                                         9 => "10"&X"20",        --blank
                                                                                                                     
                                                                         10 => "10"&X"45",         --E
                                                                         11 => "10"&X"52",         --R
                                                                                         
                                                                         12 => "10"&X"20",        --blank
                                                                 
                                                                         13 => "10"&X"57",         --W
                                                                         14 => "10"&X"47",         --G
                                                                 
                                                                         15 => "10"&X"20",         --blank
                                                                 
                                                                         16 => "10"&X"53",         --S
                                                                         17 => "10"&X"45",         --E
                                                                         18 => "10"&X"52",         --R   
                                                                                      
                                                                         19 => "00"&X"C0",         --next line 
                                                                 
                                                                          20 => "10"&X"57",         --W
                                                                         21 => "10"&X"41",          --A
                                                                         22 => "10"&X"47",         --G
                                                                                         
                                                                         23 => "10"&X"20",         --blank
                                                                                         
                                                                                           
                                                                        24 => "00"&X"10");            --
                                   when s13 =>
                                       
                                       led <= "000000000100000";
                                       LCD_CMD <= (     0 => "00"&X"3C",        --Function Set
                                               1 => "00"&X"0C",        --Display ON, Cursor OFF, Blink OFF
                                               2 => "00"&X"01",        --Clear Display
                                               3 => "00"&X"02",         --return home
                                       
                                               4 => "10"&X"4E",         --N 
                                                                          5 => "10"&X"52",         --R
                                                                                          
                                                                          6 => "10"&X"20",         --blank
                                                                                          
                                                                          7 => "10"&X"53",         --S
                                                                          8 => "10"&X"52",         --R
                                                                                                                      
                                                                          9 => "10"&X"20",        --blank
                                                                                                                      
                                                                          10 => "10"&X"45",         --E
                                                                          11 => "10"&X"52",         --R
                                                                                          
                                                                          12 => "10"&X"20",        --blank
                                                                  
                                                                          13 => "10"&X"57",         --W
                                                                          14 => "10"&X"47",         --G
                                                                  
                                                                          15 => "10"&X"20",        --blank
                                                                  
                                                                          16 => "10"&X"53",         --S
                                                                          17 => "10"&X"45",         --E
                                                                          18 => "10"&X"52",         --R   
                                                                                       
                                                                          19 => "00"&X"C0",         --next line 
                                                                  
                                                                           20 => "10"&X"57",         --W
                                                                          21 => "10"&X"41",          --A
                                                                          22 => "10"&X"59",         --Y
                                                                                          
                                                                          23 => "10"&X"20",         --blank
                                                                                          
                                                                                            
                                                                         24 => "00"&X"10");            --
                                       
                                   
                                       
                                      
                   
            end case;
        end process;
        
       LCDInput <= LCD_CMD;
end Traffic_FSM;
