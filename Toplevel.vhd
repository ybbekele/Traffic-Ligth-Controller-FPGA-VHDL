
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

entity Traffic_Light_Top_Module is
    Port ( mclk1 : in STD_LOGIC;
           detect_E1 : in STD_LOGIC;
           detect_W1 : in STD_LOGIC;
           detect_SE1 : in STD_LOGIC;
           rst1 : in STD_LOGIC;
           btn1 : in STD_LOGIC;
           sw1 : in STD_LOGIC_VECTOR(1 downto 0);
           DB1 : out STD_LOGIC_VECTOR (7 downto 0);
           LED1 : out STD_LOGIC_VECTOR (14 downto 0);
           RS1 : out STD_LOGIC;
           RW1 : out STD_LOGIC;
           E1 : out STD_LOGIC;
           BL1 : out STD_LOGIC;
           red, grn, blu : out std_logic_vector(3 downto 0);
           vs, hs: out std_logic;           
           JA1 : inout std_logic_vector (7 downto 0);
           anode    : out std_logic_vector(3 downto 0);
           segOut   : out std_logic_vector(6 downto 0)--System outputs
                   );
end Traffic_Light_Top_Module;

architecture Behavioral of Traffic_Light_Top_Module is

component Traffic_Controller is
        Port (rst: in std_logic;  
                mclk: in std_logic;
                clk: in std_logic;
                East_Car_Det: in std_logic;     --detect car presence on east road left turn lane
                West_Car_Det: in std_logic;     --detect car presence on west road left turn lane
                SE_Car_Det: in std_logic;    --detect car presence on south-east road
                TL : in std_logic_vector (15 downto 0);   --Long timer input from the timer
                TS : in std_logic_vector (15 downto 0);   --Short timer input from the timer
                STs: out std_logic;   --Start short timer upon expiration
                STl: out std_logic;   --Start long timer upon expiration
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
end component;
component TheirVGA
    port(mclk: in std_logic;
        ledvga: in std_logic_vector(14 downto 0);
         modev: in std_logic;
         modev2: in std_logic;
         TLv: in std_logic_vector(15 downto 0);
         TSv: in std_logic_vector(15 downto 0);
        timeremain1: in std_logic_vector(15 downto 0);
		vs, hs: out std_logic;
		red, grn, blu : out std_logic_vector(3 downto 0)
    );
end component;
component PmodKYPD  port ( 
     clk     : in    std_logic;
      JA      : inout std_logic_vector (7 downto 0); -- PmodKYPD is designed to be connected to JA
       Pmodout : out   std_logic_vector (7 downto 0);
       an : out STD_LOGIC_VECTOR (3 downto 0);
      seg : out STD_LOGIC_VECTOR (6 downto 0)
       );
        
  end component; 
component CLPRefProj 
    Port ( 	rst:	in std_logic;									
                 mclk:	in std_logic;									--clock input
                 sw:    in std_logic;                                    --switch input for turning backlight on and off
                 LCDIN: in LCD_CMDS_T;                      --LCD display data from FSM controller
                        --lcd input signals
                 DB:    out std_logic_vector(7 downto 0);        --output bus, used for data transfer
                 RS:    out std_logic;                                  --register selection pin
                 RW:    out std_logic;                                    --selects between read/write modes
                 E:     out std_logic;                                    --enable signal for starting the data read/write
                 BL:    out std_logic                                --backlight control pin							
				);		
end component;
component timer
        Port ( STs,STl, mclk, clr: in std_logic;  --Clock and Set Timer inputs for the timer module
       TL : out std_logic_vector(15 downto 0) ; --Long timer count value
       TS : out std_logic_vector(15 downto 0);  --Short timer count value
       clkout: out std_logic;
       anode  : out std_logic_vector(3 downto 0);
       segOut  : out  STD_LOGIC_VECTOR (6 downto 0);
        SW: in std_logic_vector(1 downto 0)
        );

end component;
component ClockToSec port ( 
      clk         : in std_logic;--set
       sclk        : out std_logic);--set
    end component;
signal STl1: std_logic;
signal STs1: std_logic;
signal LCD_COMM: LCD_CMDS_T;
signal tmpClk: std_logic;
signal TL1: std_logic_vector(15 downto 0);
signal TS1: std_logic_vector(15 downto 0);
signal ledtemp:std_logic_vector(14 downto 0);
signal timeremain2:std_logic_vector(15 downto 0);
signal modevga1: STD_LOGIC ;
signal TLtemp: std_logic_vector(15 downto 0);
signal TStemp: std_logic_vector(15 downto 0);
signal mode2temp: STD_LOGIC ;
signal tPmodout  : std_logic_vector(7 downto 0);
signal tsclk: std_logic;
signal swlcd: std_logic;
signal ps2_new_code: std_logic;
signal key01: std_logic_vector(3 downto 0);
signal key11: std_logic_vector(3 downto 0);
signal kpdata1: std_logic_vector(7 downto 0);
begin
Myclock2sec: ClockToSec port map (
clk=>mclk1, 
sclk=>tsclk); 
    master_controller: Traffic_Controller
    port map( rst => rst1,
                mclk => mclk1,
                clk=> tmpclk,
               -- ps2new=> ps2_new_code,
                East_Car_Det=> detect_E1,      
                West_Car_Det=> detect_W1,     
                SE_Car_Det=>detect_SE1,   
                TL=> TL1,  
                TS=> TS1,
                STs=> STs1,
                STl=>STl1, 
                LED=>LED1,
                LCDInput=>LCD_COMM,
                kpinput => JA1,
                timeremain=>timeremain2,
                modevga=>modevga1,
                mode2=>mode2temp,
                TLv=>TLtemp,
                TSv=>TStemp,
                SW=>sw1
    );
        vgaInstance: TheirVGA
        port map(mclk=>mclk1,
        ledvga=>ledtemp,
        timeremain1=>timeremain2,
        modev=>modevga1,
        modev2=>mode2temp,
        TLv=>TLtemp,
        TSv=>TStemp,       
        vs=>vs,
        hs=>hs,
        red=>red,
        grn=>grn,
        blu=>blu
        );
   MyPmod: PmodKYPD port map(
clk => mclk1, 
JA => JA1 , 
Pmodout => tPmodout,
an=>anode,
seg=>segOut  );

    lcd: CLPRefProj
    port map(rst=>rst1,									
                    mclk=>mclk1,                                   
                    sw=>swlcd,                                    
                    LCDIN=> LCD_COMM,                     
                    DB=>DB1,      
                    RS=>RS1,                                  
                    RW=>RW1,                                    
                    E=>E1,                                    
                    BL=>BL1    
    );
    
    timerInstance: timer
        port map(mclk=>mclk1,
                    clr=> btn1,
                    STs=> STs1,
                    STl=> STl1,
                    clkout =>tmpClk,
                    TL=>TL1,
                    TS=>TS1,
                    anode=> anode,
                    segOut=> segOut,
                    SW=>sw1
        );
 LED1<=ledtemp;

end Behavioral;
