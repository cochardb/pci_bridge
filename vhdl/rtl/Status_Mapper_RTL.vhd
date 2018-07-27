-- ===========================================================================================
-- | ENTITY
-- ===========================================================================================
LIBRARY IEEE;
USE IEEE.STD_LOGIC_1164.all;
USE IEEE.NUMERIC_STD.ALL;

LIBRARY work;
USE work.PackageBridgePCI.ALL;

ENTITY Status_Mapper IS
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
END ENTITY Status_Mapper;

-- ===========================================================================================
-- | ARCHITECTURE
-- ===========================================================================================
LIBRARY IEEE;
USE IEEE.STD_LOGIC_1164.all;
USE IEEE.NUMERIC_STD.ALL;

LIBRARY work;
USE work.PackageBridgePCI.ALL;

ARCHITECTURE RTL OF Status_Mapper IS
BEGIN

   Status.ErrAddr      <= ErrAddr;
   Status.ErrDataIn    <= ErrDataIn;
   Status.ErrDataOut   <= ErrDataOut;
   Status.TargetAbort  <= TargetAbort;
   Status.MasterAbort  <= MasterAbort;
   Status.ErrSystem    <= ErrSystem;
   Status.Busy         <= Busy;
   Status.WaitGrant    <= WaitGrant;
   Status.RxDone       <= RxDone;
   Status.TxDone       <= TxDone;

END ARCHITECTURE RTL;