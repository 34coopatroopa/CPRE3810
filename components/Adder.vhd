-------------------------------------------------------------------------
-- Joseph Zambreno
-- Department of Electrical and Computer Engineering
-- Iowa State University
-------------------------------------------------------------------------


-- Adder.vhd
-------------------------------------------------------------------------
-- DESCRIPTION: This file contains an implementation of a behavioral 
-- signed adder operating on std_logic_vector inputs. 
--
--
-- NOTES: For simplicity, we cast to signed values before operating and cast back.
-- This design does not handle overflow.


-- 8/19/09 by JAZ::Design created.
-- 1/16/25 by CWS::Switched from integer to std_logic_vector and numeric_std.
-------------------------------------------------------------------------

library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;

entity Adder is

  generic(A_WIDTH : integer := 32;
          B_WIDTH : integer := 32;
          C_WIDTH : integer := 32);

  port(iCLK             : in std_logic;
       iA               : in std_logic_vector(A_WIDTH-1 downto 0);
       iB               : in std_logic_vector(B_WIDTH-1 downto 0);
       oC               : out std_logic_vector(C_WIDTH-1 downto 0));

end Adder;

architecture behavior of Adder is
begin

  process(iCLK, iA, iB)
  begin
    if rising_edge(iCLK) then
	   oC <= std_logic_vector(resize(signed(iA) + signed(iB), 32));
    end if;
  end process;
  
end behavior;
