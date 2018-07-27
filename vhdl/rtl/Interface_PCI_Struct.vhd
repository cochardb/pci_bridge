-- ===========================================================================================
-- | ENTITY
-- ===========================================================================================
LIBRARY IEEE;
USE IEEE.STD_LOGIC_1164.all;
USE IEEE.NUMERIC_STD.ALL;

LIBRARY work;
USE work.PackageBridgePCI.ALL;

ENTITY Interface_PCI IS
   PORT (
      -- Signaux echange avec Interface_Proc
      Start        : IN     Def_Bit ;
      ResStart     : OUT    Def_Bit ;
      AckStart     : IN     Def_Bit ;
      ProcToBridge : IN     Def_ProcToBridge ;
      Status       : OUT    Def_Status ;
      BridgeToProc : OUT  Def_Dword ;
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
END ENTITY Interface_PCI;

-- ===========================================================================================
-- | ARCHITECTURE
-- ===========================================================================================
LIBRARY IEEE;
USE IEEE.STD_LOGIC_1164.all;
USE IEEE.NUMERIC_STD.ALL;

LIBRARY work;
USE work.PackageBridgePCI.ALL;

ARCHITECTURE Struct OF Interface_PCI IS

----------------------------------------------------------------------------------------------
   -- Buffers
   SIGNAL AD_In       : Def_Dword;
   SIGNAL AD_Master   : Def_Dword;
   SIGNAL AD_OE       : Def_Bit;
   SIGNAL CnBE_Master : Def_Cmd;
   SIGNAL CnBE_OE     : Def_Bit;
   -- Parity Generator
   SIGNAL GenPar      : Def_Bit;
   -- Parity Checker
   SIGNAL ChkPErr     : Def_Bit;
   SIGNAL ChkSErr     : Def_Bit;
   SIGNAL ChkPar      : Def_Bit;
   SIGNAL ResetError  : Def_Bit;
   -- Bits Status Parity Checker
   SIGNAL ErrAddr     : Def_Bit;
   SIGNAL ErrDataIn   : Def_Bit;
   SIGNAL ErrDataOut  : Def_Bit;
   -- Bits Status Sequencer
   SIGNAL TargetAbort : Def_Bit;
   SIGNAL MasterAbort : Def_Bit;
   SIGNAL ErrSystem   : Def_Bit;
   SIGNAL Busy        : Def_Bit;
   SIGNAL WaitGrant   : Def_Bit;
   SIGNAL RxDone      : Def_Bit;
   SIGNAL TxDone      : Def_Bit;

----------------------------------------------------------------------------------------------
   COMPONENT Buffers IS
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
   END COMPONENT Buffers;

----------------------------------------------------------------------------------------------
   COMPONENT Parity_Checker IS
   PORT (
      -- Signaux Systeme
      CLK_PCI      : IN    Def_Bit ;
      nRST         : IN    Def_Bit ;
      -- Signaux pour vérification parité
      AD_In        : IN    Def_Dword ;
      CnBE_Master  : IN    Def_Cmd ;
      -- Commande donnée par Sequencer
      ChkPErr      : IN    Def_Bit ;
      ChkSErr      : IN    Def_Bit ;
      ChkPar       : IN    Def_Bit ;
      ResetError   : IN    Def_Bit ;
      -- Bits de Status d'erreur
      ErrAddr      : OUT   Def_Bit ;
      ErrDataIn    : OUT   Def_Bit ;
      ErrDataOut   : OUT   Def_Bit ;
      -- Signaux PCI
      PAR          : IN    Def_Bit ;
      nPERR        : INOUT Def_Bit ;
      nSERR        : IN    Def_Bit
   );
   END COMPONENT Parity_Checker;

----------------------------------------------------------------------------------------------
   COMPONENT Parity_Generator IS
   PORT (
      -- Signaux Systeme
      CLK_PCI      : IN    Def_Bit ;
      nRST         : IN    Def_Bit ;
      -- Signaux pour vérification parité
      AD_Master    : IN    Def_Dword ;
      CnBE_Master  : IN    Def_Cmd ;
      -- Commande donnée par Sequencer
      GenPar       : IN    Def_Bit ;
      -- Signaux PCI
      PAR          : OUT   Def_Bit
   );
   END COMPONENT Parity_Generator;

----------------------------------------------------------------------------------------------
   COMPONENT Sequencer IS
   PORT (
      -- Signaux Systeme
      CLK_PCI      : IN    Def_Bit ;
      nRST         : IN    Def_Bit ;
      -- Signaux arbitre PCI
      nGNT         : IN    Def_Bit ;
      nREQ         : OUT   Def_Bit ;
      -- Signaux bus PCI
      AD_In        : IN    Def_Dword ;
      AD_Master    : OUT   Def_Dword ;
      CnBE_Master  : OUT   Def_Cmd ;
      -- Signaux controle PCI (Maitre)
      IDSEL        : OUT   Def_IDSel ;
      nFRAME       : INOUT Def_Bit ;
      nIRDY        : INOUT Def_Bit ;
      -- Signaux controle PCI (Esclave)
      nDEVSEL      : IN    Def_Bit ;
      nTRDY        : IN    Def_Bit ;
      nSTOP        : IN    Def_Bit ;
      -- Signaux echange avec Interface_Proc
      Start        : IN    Def_Bit ;
      ResStart     : OUT   Def_Bit ;
      AckStart     : IN    Def_Bit ;
      ProcToBridge : IN    Def_ProcToBridge ;
      BridgeToProc : OUT   Def_Dword ;
      -- Commande Parity Checker
      ChkPar       : OUT   Def_Bit ;
      ChkPErr      : OUT   Def_Bit ;
      ChkSErr      : OUT   Def_Bit ;
      ResetError   : OUT   Def_Bit ;
      -- Commande Parity Generator
      GenPar       : OUT   Def_Bit ;
      -- Commande Buffers
      AD_OE        : OUT   Def_Bit ;
      CnBE_OE      : OUT   Def_Bit ;
      -- Status Bits
      TargetAbort  : OUT   Def_Bit ;
      MasterAbort  : OUT   Def_Bit ;
      ErrSystem    : OUT   Def_Bit ;
      Busy         : OUT   Def_Bit ;
      WaitGrant    : OUT   Def_Bit ;
      RxDone       : OUT   Def_Bit ;
      TxDone       : OUT   Def_Bit
   );
   END COMPONENT Sequencer;

----------------------------------------------------------------------------------------------
   COMPONENT Status_Mapper IS
   PORT (
      -- Status Bits de Parity Checker
      ErrAddr      : IN    Def_Bit ;
      ErrDataIn    : IN    Def_Bit ;
      ErrDataOut   : IN    Def_Bit ;
      -- Status Bits de Sequencer
      TargetAbort  : IN    Def_Bit ;
      MasterAbort  : IN    Def_Bit ;
      ErrSystem    : IN    Def_Bit ;
      Busy         : IN    Def_Bit ;
      WaitGrant    : IN    Def_Bit ;
      RxDone       : IN    Def_Bit ;
      TxDone       : IN    Def_Bit ;
      -- Sortie Status
      Status       : OUT   Def_Status
   );
   END COMPONENT Status_Mapper;

----------------------------------------------------------------------------------------------
   FOR ALL : Buffers          USE ENTITY work.Buffers;
   FOR ALL : Parity_Checker   USE ENTITY work.Parity_Checker;
   FOR ALL : Parity_Generator USE ENTITY work.Parity_Generator;
   FOR ALL : Sequencer        USE ENTITY work.Sequencer;
   FOR ALL : Status_Mapper    USE ENTITY work.Status_Mapper;

BEGIN

----------------------------------------------------------------------------------------------
   Buffers_inst : Buffers
----------------------------------------------------------------------------------------------
   PORT MAP (
      -- Signaux PCI
      AD          => AD,
      CnBE        => CnBE,
      -- Signaux Vers BUS PCI
      AD_Master   => AD_Master,
      CnBE_Master => CnBE_Master,
      -- Enable des buffers
      AD_OE       => AD_OE,
      CnBE_OE     => CnBE_OE,
      -- Signaux provenant du PCI
      AD_In       => AD_In
   );

----------------------------------------------------------------------------------------------
   Parity_Checker_inst : Parity_Checker
----------------------------------------------------------------------------------------------
   PORT MAP (
      -- Signaux Systeme
      CLK_PCI      =>   CLK_PCI,
      nRST         =>   nRST,
      -- Signaux pour vérification parité
      AD_In        =>   AD_In,
      CnBE_Master  =>   CnBE_Master,
      -- Commande donnée par Sequencer
      ChkPErr      =>   ChkPErr,
      ChkSErr      =>   ChkSErr,
      ChkPar       =>   ChkPar,
      ResetError   =>   ResetError,
      -- Bits de Status d'erreur
      ErrAddr      =>   ErrAddr,
      ErrDataIn    =>   ErrDataIn,
      ErrDataOut   =>   ErrDataOut,
      -- Signaux PCI
      PAR          =>   PAR,
      nPERR        =>   nPERR,
      nSERR        =>   nSERR
   );

----------------------------------------------------------------------------------------------
   Parity_Generator_inst : Parity_Generator
----------------------------------------------------------------------------------------------
   PORT MAP (
      -- Signaux Systeme
      CLK_PCI      =>   CLK_PCI,
      nRST         =>   nRST,
      -- Signaux pour vérification parité
      AD_Master    =>   AD_Master,
      CnBE_Master  =>   CnBE_Master,
      -- Commande donnée par Sequencer
      GenPar       =>   GenPar,
      -- Signaux PCI
      PAR          =>   PAR
   );

----------------------------------------------------------------------------------------------
   Sequencer_inst : Sequencer
----------------------------------------------------------------------------------------------
   PORT MAP (
      -- Signaux Systeme
      CLK_PCI      =>   CLK_PCI,
      nRST         =>   nRST,
      -- Signaux arbitre PCI
      nGNT         =>   nGNT,
      nREQ         =>   nREQ,
      -- Signaux bus PCI
      AD_In        =>   AD_In,
      AD_Master    =>   AD_Master,
      CnBE_Master  =>   CnBE_Master,
      -- Signaux controle PCI (Maitre)
      IDSEL        =>   IDSEL,
      nFRAME       =>   nFRAME,
      nIRDY        =>   nIRDY,
      -- Signaux controle PCI (Esclave)
      nDEVSEL      =>   nDEVSEL,
      nTRDY        =>   nTRDY,
      nSTOP        =>   nSTOP,
      -- Signaux echange avec Interface_Proc
      Start        =>   Start,
      ResStart     =>   ResStart,
      AckStart     =>   AckStart,
      ProcToBridge =>   ProcToBridge,
      BridgeToProc =>   BridgeToProc,
      -- Commande Parity Checker
      ChkPar       =>   ChkPar,
      ChkPErr      =>   ChkPErr,
      ChkSErr      =>   ChkSErr,
      ResetError   =>   ResetError,
      -- Commande Parity Generator
      GenPar       =>   GenPar,
      -- Commande Buffers
      AD_OE        =>   AD_OE,
      CnBE_OE      =>   CnBE_OE,
      -- Status Bits
      TargetAbort  =>   TargetAbort,
      MasterAbort  =>   MasterAbort,
      ErrSystem    =>   ErrSystem,
      Busy         =>   Busy,
      WaitGrant    =>   WaitGrant,
      RxDone       =>   RxDone,
      TxDone       =>   TxDone
   );

----------------------------------------------------------------------------------------------
   Status_Mapper_inst : Status_Mapper
----------------------------------------------------------------------------------------------
   PORT MAP (
      -- Status Bits de Parity Checker
      ErrAddr      =>   ErrAddr,
      ErrDataIn    =>   ErrDataIn,
      ErrDataOut   =>   ErrDataOut,
      -- Status Bits de Sequencer
      TargetAbort  =>   TargetAbort,
      MasterAbort  =>   MasterAbort,
      ErrSystem    =>   ErrSystem,
      Busy         =>   Busy,
      WaitGrant    =>   WaitGrant,
      RxDone       =>   RxDone,
      TxDone       =>   TxDone,
      -- Sortie Status
      Status       =>   Status
   );

END ARCHITECTURE Struct;
