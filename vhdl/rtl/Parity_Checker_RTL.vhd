-- ===========================================================================================
-- | ENTITY
-- ===========================================================================================
LIBRARY IEEE;
USE IEEE.STD_LOGIC_1164.all;
USE IEEE.NUMERIC_STD.ALL;

LIBRARY work;
USE work.PackageBridgePCI.ALL;

ENTITY Parity_Checker IS
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
END ENTITY Parity_Checker;

-- ===========================================================================================
-- | ARCHITECTURE
-- ===========================================================================================
LIBRARY IEEE;
USE IEEE.STD_LOGIC_1164.all;
USE IEEE.NUMERIC_STD.ALL;

LIBRARY work;
USE work.PackageBridgePCI.ALL;

ARCHITECTURE RTL OF Parity_Checker IS

   SIGNAL PAR_In   : Def_Bit;

BEGIN

----------------------------------------------------------------------------------------------
PARITY_CHECKER_PROCESS : PROCESS(nRST, CLK_PCI) IS
----------------------------------------------------------------------------------------------
BEGIN
   IF( nRST='0' )THEN
      nPERR      <= 'Z';
      PAR_In     <= '0';
      ErrAddr    <= '0';
      ErrDataIn  <= '0';
      ErrDataOut <= '0';

   ELSIF( CLK_PCI'EVENT AND CLK_PCI='1' )THEN
      PAR_In  <= xor_reduct(AD_In & CnBE_Master);

      -- Vérification parité du device et verification des erreur envoyées par le device
      IF ResetError='1' THEN
         ErrAddr    <= '0';
         ErrDataIn  <= '0';
         ErrDataOut <= '0';

      ELSE

         -- Test de la parité en lecture
         IF ChkPar='1' THEN
            IF PAR/=PAR_In THEN
               ErrDataIn <= '1';
               nPERR     <= '0';
            ELSE
               ErrDataIn <= '0';
               nPERR     <= '1';
            END IF;
         ELSE
            nPERR <='Z';
         END IF;

         -- Test de PERR envoyé par le device
         IF ChkPErr='1' THEN
            IF nPERR='0' THEN
               ErrDataOut <= '1';
            ELSE
               ErrDataOut <= '0';
            END IF;
         END IF;

         -- Test de SERR envoyé par le device
         IF ChkSErr='1' THEN
            IF nSERR='0' THEN
               ErrAddr <= '1';
            ELSE
               ErrAddr <= '0';
            END IF;
         END IF;
      END IF;
   END IF;
END PROCESS PARITY_CHECKER_PROCESS;

END ARCHITECTURE RTL;