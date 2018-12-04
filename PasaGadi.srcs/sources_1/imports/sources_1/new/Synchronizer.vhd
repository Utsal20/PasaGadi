----------------------------------------------------------------------------------
-- Create Date: 11/26/2018 07:44:12 AM
----------------------------------------------------------------------------------
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;


entity Synchronizer is
  Port ( clk : in STD_LOGIC;
         a : in STD_LOGIC; 
         b : out STD_LOGIC 
       );
end Synchronizer;

architecture Synchronizer of Synchronizer is
begin

    process ( clk, a )
        variable synch_reg : STD_LOGIC;
    begin
        if rising_edge(clk) then
            b <= synch_reg;
            synch_reg := a;
        end if;
    end process;

end Synchronizer;
