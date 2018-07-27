-- ===========================================================================================
-- | ENTITY
-- ===========================================================================================
LIBRARY IEEE;
USE IEEE.STD_LOGIC_1164.all;
USE IEEE.NUMERIC_STD.ALL;

LIBRARY work;
USE work.PackageBridgePCI.ALL;

ENTITY HOST_PCI_Bridge IS
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
END ENTITY HOST_PCI_Bridge;

-- ===========================================================================================
-- | ARCHITECTURE
-- ===========================================================================================
LIBRARY IEEE;
USE IEEE.STD_LOGIC_1164.all;
USE IEEE.NUMERIC_STD.ALL;

LIBRARY work;
USE work.PackageBridgePCI.ALL;

ARCHITECTURE Struct OF HOST_PCI_Bridge IS

----------------------------------------------------------------------------------------------
   -- From proc
   SIGNAL ProcToBridge : Def_ProcToBridge;
   SIGNAL Start        : Def_Bit;
   -- From Bridge
   SIGNAL BridgeToProc : Def_Dword;
   SIGNAL Status       : Def_Status;
   -- Control Start
   SIGNAL ResStart     : Def_Bit;
   SIGNAL AckStart     : Def_Bit;

----------------------------------------------------------------------------------------------
   COMPONENT Interface_PCI
   PORT (
      -- Signaux echange avec Interface_Proc
      Start        : IN     Def_Bit ;
      ResStart     : OUT    Def_Bit ;
      AckStart     : IN     Def_Bit ;
      ProcToBridge : IN     Def_ProcToBridge ;
      Status       : OUT    Def_Status ;
      BridgeToProc : OUT    Def_Dword ;
      -- Signaux Systeme
      CLK_PCI      : IN     Def_Bit ;
      nRST         : IN     Def_Bit ;
      -- Signaux arbitre PCI
      nGNT         : IN     Def_Bit ;
      nREQ         : OUT    Def_Bit ;
      -- Signaux bus PCI
      AD           : INOUT  Def_Dword ;
      CnBE         : OUT    Def_Cmd ;
      PAR          : INOUT  Def_Bit ;
      -- Signaux controle PCI (Maitre)
      IDSEL        : OUT    Def_IDSel ;
      nFRAME       : INOUT  Def_Bit ;
      nIRDY        : INOUT  Def_Bit ;
      -- Signaux controle PCI (Esclave)
      nDEVSEL      : IN     Def_Bit ;
      nTRDY        : IN     Def_Bit ;
      nSTOP        : IN     Def_Bit ;
      -- Signaux erreur PCI
      nPERR        : INOUT  Def_Bit ;
      nSERR        : IN     Def_Bit
   );
   END COMPONENT;
----------------------------------------------------------------------------------------------
   COMPONENT Interface_Proc
   PORT (
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
   END COMPONENT;

----------------------------------------------------------------------------------------------
   FOR ALL : Interface_PCI  USE ENTITY work.Interface_PCI;
   FOR ALL : Interface_Proc USE ENTITY work.Interface_Proc;

BEGIN

----------------------------------------------------------------------------------------------
   Interface_PCI_inst : Interface_PCI
----------------------------------------------------------------------------------------------
   PORT MAP (
      -- Signaux echange avec Interface_Proc
      Start        =>   Start,
      ResStart     =>   ResStart,
      AckStart     =>   AckStart,
      ProcToBridge =>   ProcToBridge,
      Status       =>   Status,
      BridgeToProc =>   BridgeToProc,
      -- Signaux Systeme
      CLK_PCI      =>   CLK_PCI,
      nRST         =>   nRST,
      -- Signaux arbitre PCI
      nGNT         =>   nGNT,
      nREQ         =>   nREQ,
      -- Signaux bus PCI
      AD           =>   AD,
      CnBE         =>   CnBE,
      PAR          =>   PAR,
      -- Signaux controle PCI (Maitre)
      IDSEL        =>   IDSEL,
      nFRAME       =>   nFRAME,
      nIRDY        =>   nIRDY,
      -- Signaux controle PCI (Esclave)
      nDEVSEL      =>   nDEVSEL,
      nTRDY        =>   nTRDY,
      nSTOP        =>   nSTOP,
      -- Signaux erreur PCI
      nPERR        =>   nPERR,
      nSERR        =>   nSERR
   );
----------------------------------------------------------------------------------------------
   Interface_Proc_inst : Interface_Proc
----------------------------------------------------------------------------------------------
   PORT MAP (
      -- Signaux echange avec Interface_PCI
      Start        =>   Start,
      ResStart     =>   ResStart,
      AckStart     =>   AckStart,
      ProcToBridge =>   ProcToBridge,
      Status       =>   Status,
      BridgeToProc =>   BridgeToProc,
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

END ARCHITECTURE Struct;
