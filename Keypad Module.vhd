library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.STD_LOGIC_ARITH.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL;

entity PmodKYPD is
    Port ( 
        clk     : in    STD_LOGIC;
    JA      : inout STD_LOGIC_VECTOR (7 downto 0); -- PmodKYPD is designed to be connected to JA
       
        Pmodout : out   STD_LOGIC_VECTOR (7 downto 0):="00000000";
        an : out STD_LOGIC_VECTOR (3 downto 0);
        seg : out STD_LOGIC_VECTOR (6 downto 0)
       );
end PmodKYPD;
architecture Behavioral of PmodKYPD is
signal Decode: STD_LOGIC_VECTOR (3 downto 0);
    component Decoder is
        Port (
            clk         : in    STD_LOGIC;
            Row         : in    STD_LOGIC_VECTOR (3 downto 0);
            Col         : out   STD_LOGIC_VECTOR (3 downto 0);
            DecodeOut   : out   STD_LOGIC_VECTOR (3 downto 0));
    end component;
 component DisplayController is
        Port (
               DispVal : in  STD_LOGIC_VECTOR (3 downto 0);
               anode: out std_logic_vector(3 downto 0);
               segOut : out  STD_LOGIC_VECTOR (6 downto 0));
        end component;   
    
   begin
MyDecoder: Decoder port map (clk=>clk, Row =>JA(7 downto 4),Col=>JA(3 downto 0), DecodeOut=>Decode);
C1: DisplayController port map (DispVal=>Decode, anode=>an, segOut=>seg );
end Behavioral;

