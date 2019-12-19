library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.STD_LOGIC_ARITH.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL;

-- Uncomment the following library declaration if using
-- arithmetic functions with Signed or Unsigned values
--use IEEE.NUMERIC_STD.ALL;

-- Uncomment the following library declaration if instantiating
-- any Xilinx leaf cells in this code.
--library UNISIM;
--use UNISIM.VComponents.all;

entity timer is
    Port (STs,STl, clr : in std_logic; 
            rst: in std_logic;  --timer
            mclk: in std_logic;
            clkout: out std_logic;
            TL : out std_logic_vector(15 downto 0) ; --Long timer count value
            TS : out std_logic_vector(15 downto 0);  --Short timer count value
            anode : out std_logic_vector(3 downto 0);
            segOut : out  STD_LOGIC_VECTOR (6 downto 0);
            SW: in std_logic_vector(1 downto 0)
              );
end timer;

architecture Behavioral of timer is
component DisplayController is
        Port (
               DispVal  : in  STD_LOGIC_VECTOR (3 downto 0);
               anode    : out std_logic_vector(3 downto 0);
               segOut   : out  STD_LOGIC_VECTOR (6 downto 0));
    end component;
    
signal clkCount: std_logic_vector(15 downto 0):="0000000000000000";
signal clk : std_logic;
signal countTS: std_logic_vector(15 downto 0):="0000000000000000";  --Count variable to count short timer value
signal countTL: std_logic_vector(15 downto 0):="0000000000000000";  --Count variable to count long timer value
begin

 process (mclk)
       begin
       if (mclk = '1' and mclk'event) then
           if(clkCount = "1100001101001111") then    --49999   
               clkCount <= "0000000000000000";
               clk <= not clk;
           else 
               clkCount <= clkCount + 1;
           end if;
       end if;
   end process;
   
 Main: process(STs,STl, clk)
   begin
       if (clk = '1' and clk'event) then  --Uses the rising clock edge event to start counting
           if (STs = '1') then  --Force clear if asserted clears everything
               countTS <="0000000000000000";
              else
            countTS <= countTS + 1;
           end if;
           end if;
           if (clk = '1' and clk'event) then  --Uses the rising clock edge event to start counting
                if (STl = '1') then  --Force clear if asserted clears everything
                        countTL <="0000000000000000";
                          else
                        countTL <= countTL + 1;
                           end if;    
                           
           
       end if;
   end process;
   TL <= countTL;
   TS <= countTS;
   clkout <= clk;
   end Behavioral;
