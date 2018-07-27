-- ===========================================================================================
-- | ENTITY
-- ===========================================================================================
LIBRARY IEEE;
USE IEEE.STD_LOGIC_1164.all;
USE IEEE.NUMERIC_STD.ALL;

LIBRARY work;
USE work.PackageBridgePCI.ALL;

ENTITY Interface_Proc IS
   PORT( 
      -- Signaux echange avec Interface_PCI
      Start        : OUT    Def_Bit ;
      ResStart     : IN     Def_Bit ;
      AckStart     : OUT    Def_Bit ;
      ProcToBridge : OUT    Def_ProcToBridge ;
      Status       : IN     Def_Status ;
      BridgeToProc : IN     Def_Dword ;
      -- Signaux Systeme
      CLK          : IN     Def_Bit ;
      nRST         : IN     Def_Bit ;
      -- Signaux Processeur
      ADDR         : IN     Def_AddrProc ;
      DBus         : INOUT  Def_DBus ;
      nAS          : IN     Def_Bit ;
      RnW          : IN     Def_Bit ;
      nCS          : IN     Def_Bit ;
      nBE          : IN     Def_Endianness
   );
END ENTITY Interface_Proc;

-- ===========================================================================================
-- | ARCHITECTURE
-- ===========================================================================================
LIBRARY IEEE;
USE IEEE.STD_LOGIC_1164.all;
USE IEEE.NUMERIC_STD.ALL;

LIBRARY work;
USE work.PackageBridgePCI.ALL;

ARCHITECTURE Struct OF Interface_Proc IS

----------------------------------------------------------------------------------------------
   COMPONENT Interface_Write IS
   PORT (
      -- Signaux echange avec Interface_PCI
      Start        : OUT    Def_Bit ;
      ResStart     : IN     Def_Bit ;
      AckStart     : OUT    Def_Bit ;
      ProcToBridge : OUT    Def_ProcToBridge ;
      -- Signaux Systeme
      CLK          : IN     Def_Bit ;
      nRST         : IN     Def_Bit ;
      -- Signaux Processeur
      ADDR         : IN     Def_AddrProc ;
      DBus         : IN     Def_DBus ;
      nAS          : IN     Def_Bit ;
      RnW          : IN     Def_Bit ;
      nCS          : IN     Def_Bit ;
      nBE          : IN     Def_Endianness
   );
   END COMPONENT;

----------------------------------------------------------------------------------------------
   COMPONENT Interface_Read IS
   PORT (
      -- Signaux echange avec Interface_PCI
      Status       : IN     Def_Status ;
      BridgeToProc : IN     Def_Dword ;
      -- Signaux Systeme
      nRST         : IN     Def_Bit ;
      -- Signaux Processeur
      ADDR         : IN     Def_AddrProc ;
      DBus         : OUT    Def_DBus ;
      nAS          : IN     Def_Bit ;
      RnW          : IN     Def_Bit ;
      nCS          : IN     Def_Bit ;
      nBE          : IN     Def_Endianness
   );
   END COMPONENT;

----------------------------------------------------------------------------------------------
   FOR ALL : Interface_Read  USE ENTITY work.Interface_Read;
   FOR ALL : Interface_Write USE ENTITY work.Interface_Write;

BEGIN

----------------------------------------------------------------------------------------------
   Interface_Write_inst : Interface_Write
----------------------------------------------------------------------------------------------
   PORT MAP (
      -- Signaux echange avec Interface_PCI
      Start        =>   Start,
      ResStart     =>   ResStart,
      AckStart     =>   AckStart,
      ProcToBridge =>   ProcToBridge,
      -- Signaux Systeme
      CLK          =>   CLK,
      nRST         =>   nRST,
      -- Signaux Processeur
      ADDR         =>   ADDR,
      DBus         =>   DBus,
      nAS          =>   nAS,
      RnW          =>   RnW,
      nCS          =>   nCS,
      nBE          =>   nBE
   );

----------------------------------------------------------------------------------------------
   Interface_Read_inst : Interface_Read
----------------------------------------------------------------------------------------------
   PORT MAP (
      -- Signaux echange avec Interface_PCI
      Status       =>   Status,
      BridgeToProc =>   BridgeToProc,
      -- Signaux Systeme
      nRST         =>   nRST,
      -- Signaux Processeur
      ADDR         =>   ADDR,
      DBus         =>   DBus,
      nAS          =>   nAS,
      RnW          =>   RnW,
      nCS          =>   nCS,
      nBE          =>   nBE
   );

END ARCHITECTURE Struct;
