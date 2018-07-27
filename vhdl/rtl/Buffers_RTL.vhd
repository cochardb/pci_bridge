-- ===========================================================================================
-- | ENTITY
-- ===========================================================================================
LIBRARY IEEE;
USE IEEE.STD_LOGIC_1164.all;
USE IEEE.NUMERIC_STD.ALL;

LIBRARY work;
USE work.PackageBridgePCI.ALL;

ENTITY Buffers IS
   PORT (
      -- Signaux PCI
      AD          : INOUT  Def_Dword ;
      CnBE        : OUT    Def_Cmd ;
      -- Signaux Vers BUS PCI
      AD_Master   : IN     Def_Dword ;
      CnBE_Master : IN     Def_Cmd ;
      -- Enable des buffers
      AD_OE       : IN     Def_Bit ;
      CnBE_OE     : IN     Def_Bit ;
      -- Signaux provenant du PCI
      AD_In       : OUT    Def_Dword
   );
END ENTITY Buffers;

-- ===========================================================================================
-- | ARCHITECTURE
-- ===========================================================================================
LIBRARY IEEE;
USE IEEE.STD_LOGIC_1164.all;
USE IEEE.NUMERIC_STD.ALL;

LIBRARY work;
USE work.PackageBridgePCI.ALL;

ARCHITECTURE RTL OF Buffers IS
BEGIN

----------------------------------------------------------------------------------------------
BUFFERS_PROCESS : PROCESS(AD_Master, AD_OE, CnBE_Master, CnBE_OE, AD) IS
----------------------------------------------------------------------------------------------
BEGIN
   -- Buffer pour le bus AD
   AD_In <= AD;
   IF AD_OE='1' THEN
      AD <= AD_Master;
   ELSE
      AD <= (OTHERS=>'Z');
   END IF;

   -- Buffer pour le bus CnBE 
   IF CnBE_OE='1' THEN
      CnBE <= CnBE_Master;
   ELSE
      CnBE <= (OTHERS=>'Z');
   END IF;
END PROCESS BUFFERS_PROCESS;

END ARCHITECTURE RTL;