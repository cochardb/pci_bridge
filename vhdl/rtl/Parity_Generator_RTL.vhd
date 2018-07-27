-- ===========================================================================================
-- | ENTITY
-- ===========================================================================================
LIBRARY IEEE;
USE IEEE.STD_LOGIC_1164.all;
USE IEEE.NUMERIC_STD.ALL;

LIBRARY work;
USE work.PackageBridgePCI.ALL;

ENTITY Parity_Generator IS
   PORT( 
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
END ENTITY Parity_Generator;

-- ===========================================================================================
-- | ARCHITECTURE
-- ===========================================================================================
LIBRARY IEEE;
USE IEEE.STD_LOGIC_1164.all;
USE IEEE.NUMERIC_STD.ALL;

LIBRARY work;
USE work.PackageBridgePCI.ALL;

ARCHITECTURE RTL OF Parity_Generator IS

  SIGNAL PAR_Out  : Def_Bit;

BEGIN
----------------------------------------------------------------------------------------------
PARITY_GENERATOR_PROCESS : PROCESS(nRST, CLK_PCI) IS
----------------------------------------------------------------------------------------------
BEGIN
   IF( nRST='0' )THEN
      PAR     <= 'Z';
      PAR_Out <= '0';

   ELSIF( CLK_PCI'EVENT AND CLK_PCI='1' )THEN
      --PAR_Out <= xor_reduct(AD_Master & CnBE_Master);

      -- Géneration de la paritée
      IF GenPar='1' THEN
         PAR <= xor_reduct(AD_Master & CnBE_Master);
      ELSE
         PAR <='Z';
      END IF;
   END IF;
END PROCESS PARITY_GENERATOR_PROCESS;

END ARCHITECTURE RTL;