-- ===========================================================================================
-- | ENTITY
-- ===========================================================================================
LIBRARY IEEE;
USE IEEE.STD_LOGIC_1164.all;
USE IEEE.NUMERIC_STD.ALL;

LIBRARY work;
USE work.PackageBridgePCI.ALL;

ENTITY System_Under_Test IS
END ENTITY System_Under_Test;

-- ===========================================================================================
-- | ARCHITECTURE
-- ===========================================================================================
LIBRARY IEEE;
USE IEEE.STD_LOGIC_1164.all;
USE IEEE.NUMERIC_STD.ALL;

LIBRARY work;
USE work.PackageBridgePCI.ALL;

ARCHITECTURE Struct OF System_Under_Test IS

----------------------------------------------------------------------------------------------
   -- Signaux systeme
   SIGNAL CLK     : Def_Bit;
   SIGNAL CLK_PCI : Def_Bit;
   SIGNAL nRST    : Def_Bit;
   -- Signaux Processeur
   SIGNAL ADDR    : Def_AddrProc;
   SIGNAL DBus    : Def_DBus;
   SIGNAL nAS     : Def_Bit;
   SIGNAL RnW     : Def_Bit;
   SIGNAL nCS     : Def_Bit;
   SIGNAL nBE     : Def_Endianness;
   -- Signaux arbitre PCI
   SIGNAL nGNT    : Def_Bit;
   SIGNAL nREQ    : Def_Bit;
   -- Signaux bus PCI
   SIGNAL AD      : Def_Dword;
   SIGNAL CnBE    : Def_Cmd;
   SIGNAL PAR     : Def_Bit;
   -- Signaux controle PCI (Maitre)
   SIGNAL IDSEL   : Def_IDSel;
   SIGNAL nFRAME  : Def_Bit;
   SIGNAL nIRDY   : Def_Bit;
   -- Signaux controle PCI (Esclave)
   SIGNAL nDEVSEL : Def_Bit;
   SIGNAL nTRDY   : Def_Bit;
   SIGNAL nSTOP   : Def_Bit;
   -- Signaux erreur PCI
   SIGNAL nPERR   : Def_Bit;
   SIGNAL nSERR   : Def_Bit;

----------------------------------------------------------------------------------------------
   COMPONENT HOST_PCI_Bridge IS
   PORT (
      -- Signaux systeme
      CLK     : IN     Def_Bit ;
      CLK_PCI : IN     Def_Bit ;
      nRST    : IN     Def_Bit ;
      -- Signaux Processeur
      ADDR    : IN     Def_AddrProc ;
      DBus    : INOUT  Def_DBus ;
      nAS     : IN     Def_Bit ;
      RnW     : IN     Def_Bit ;
      nCS     : IN     Def_Bit ;
      nBE     : IN     Def_Endianness ;
      -- Signaux arbitre PCI
      nGNT    : IN     Def_Bit ;
      nREQ    : OUT    Def_Bit ;
      -- Signaux bus PCI
      AD      : INOUT  Def_Dword ;
      CnBE    : OUT    Def_Cmd ;
      PAR     : INOUT  Def_Bit ;
      -- Signaux controle PCI (Maitre)
      IDSEL   : OUT    Def_IDSel ;
      nFRAME  : INOUT  Def_Bit ;
      nIRDY   : INOUT  Def_Bit ;
      -- Signaux controle PCI (Esclave)
      nDEVSEL : IN     Def_Bit ;
      nTRDY   : IN     Def_Bit ;
      nSTOP   : IN     Def_Bit ;
      -- Signaux erreur PCI
      nPERR   : INOUT  Def_Bit ;
      nSERR   : IN     Def_Bit
   );
   END COMPONENT HOST_PCI_Bridge;

----------------------------------------------------------------------------------------------
   COMPONENT Environement IS
   PORT (
      -- Signaux systeme
      CLK     : OUT     Def_Bit ;
      CLK_PCI : INOUT   Def_Bit ;
      nRST    : OUT     Def_Bit ;
      -- Signaux Processeur
      ADDR    : OUT     Def_AddrProc ;
      DBus    : INOUT  Def_DBus ;
      nAS     : OUT     Def_Bit ;
      RnW     : OUT     Def_Bit ;
      nCS     : OUT     Def_Bit ;
      nBE     : OUT     Def_Endianness ;
      -- Signaux arbitre PCI
      nGNT    : OUT     Def_Bit ;
      nREQ    : IN    Def_Bit ;
      -- Signaux bus PCI
      AD      : INOUT  Def_Dword ;
      CnBE    : IN    Def_Cmd ;
      PAR     : INOUT  Def_Bit ;
      -- Signaux controle PCI (Maitre)
      IDSEL   : IN    Def_IDSel ;
      nFRAME  : INOUT  Def_Bit ;
      nIRDY   : INOUT  Def_Bit ;
      -- Signaux controle PCI (Esclave)
      nDEVSEL : OUT     Def_Bit ;
      nTRDY   : OUT     Def_Bit ;
      nSTOP   : OUT     Def_Bit ;
      -- Signaux erreur PCI
      nPERR   : INOUT  Def_Bit ;
      nSERR   : OUT     Def_Bit
   );
   END COMPONENT Environement;

----------------------------------------------------------------------------------------------
   FOR ALL : HOST_PCI_Bridge USE ENTITY work.HOST_PCI_Bridge;
   FOR ALL : Environement    USE ENTITY work.Environement;

BEGIN

----------------------------------------------------------------------------------------------
   Bridge_inst : HOST_PCI_Bridge
----------------------------------------------------------------------------------------------
   PORT MAP (
      -- Signaux systeme
      CLK     =>  CLK,
      CLK_PCI =>  CLK_PCI,
      nRST    =>  nRST,
      -- Signaux Processeur
      ADDR    =>  ADDR,
      DBus    =>  DBus,
      nAS     =>  nAS,
      RnW     =>  RnW,
      nCS     =>  nCS,
      nBE     =>  nBE,
      -- Signaux arbitre PCI
      nGNT    =>  nGNT,
      nREQ    =>  nREQ,
      -- Signaux bus PCI
      AD      =>  AD,
      CnBE    =>  CnBE,
      PAR     =>  PAR,
      -- Signaux controle PCI (Maitre)
      IDSEL   =>  IDSEL,
      nFRAME  =>  nFRAME,
      nIRDY   =>  nIRDY,
      -- Signaux controle PCI (Esclave)
      nDEVSEL =>  nDEVSEL,
      nTRDY   =>  nTRDY,
      nSTOP   =>  nSTOP,
      -- Signaux erreur PCI
      nPERR   =>  nPERR,
      nSERR   =>  nSERR
   );

----------------------------------------------------------------------------------------------
   Env_inst : Environement
----------------------------------------------------------------------------------------------
   PORT MAP (
      -- Signaux systeme
      CLK     =>  CLK,
      CLK_PCI =>  CLK_PCI,
      nRST    =>  nRST,
      -- Signaux Processeur
      ADDR    =>  ADDR,
      DBus    =>  DBus,
      nAS     =>  nAS,
      RnW     =>  RnW,
      nCS     =>  nCS,
      nBE     =>  nBE,
      -- Signaux arbitre PCI
      nGNT    =>  nGNT,
      nREQ    =>  nREQ,
      -- Signaux bus PCI
      AD      =>  AD,
      CnBE    =>  CnBE,
      PAR     =>  PAR,
      -- Signaux controle PCI (Maitre)
      IDSEL   =>  IDSEL,
      nFRAME  =>  nFRAME,
      nIRDY   =>  nIRDY,
      -- Signaux controle PCI (Esclave)
      nDEVSEL =>  nDEVSEL,
      nTRDY   =>  nTRDY,
      nSTOP   =>  nSTOP,
      -- Signaux erreur PCI
      nPERR   =>  nPERR,
      nSERR   =>  nSERR
   );

END ARCHITECTURE Struct;
