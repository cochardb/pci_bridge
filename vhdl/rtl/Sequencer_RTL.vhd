-- ===========================================================================================
-- |
-- |                        Brigde PCI
-- | -----------------------------------------------------------------------------------------
-- |
-- | Permet de d'assurer l'interface entre le bus du processeur hote
-- | et le bus PCI. Le bridge peut controler jusqu'a quatre
-- | peripheriques PCI.
-- |
-- | -----------------------------------------------------------------------------------------
-- |
-- | Auteur           : Benjamin COCHARD et DenIS LETOURNEL
-- | Date de creation : 22 Decembre 2017
-- | 
-- | Polytech Nantes - Conception de Circuits (E3)
-- | 
-- | -----------------------------------------------------------------------------------------
-- |
-- | Fait :
-- | - Lecture de la configuration  OK (22 Décembre 2017)
-- | - Generateur de parite paire   OK (23 Démbre 2017)
-- | - Ecriture de la configuration OK (24 Démbre 2017)
-- | - Lecture espace memoire       OK (24 Démbre 2017)
-- | - Ecriture espace memoire      OK (17 Janvier 2018)
-- | - Invalidation Start           OK (17 Janvier 2018)
-- | - Verification de la parité    OK (20 Janvier 2018)
-- |
-- | Reste à faire :
-- | - Interruptions
-- | 
-- ===========================================================================================
LIBRARY IEEE;
USE IEEE.STD_LOGIC_1164.all;
USE IEEE.NUMERIC_STD.ALL;

LIBRARY work;
USE work.PackageBridgePCI.ALL;

ENTITY Sequencer IS
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
END ENTITY Sequencer;

-- ===========================================================================================
-- | ARCHITECTURE
-- ===========================================================================================
LIBRARY IEEE;
USE IEEE.STD_LOGIC_1164.all;
USE IEEE.NUMERIC_STD.ALL;

LIBRARY work;
USE work.PackageBridgePCI.ALL;

ARCHITECTURE RTL OF Sequencer IS

----------------------------------------------------------------------------------------------
   SIGNAL State : Def_State; -- Etat de la machine à ét

   -- Compteur 2 bits, permet de stoper un transfert si aucun périphéque active le 
   -- signal nDEVSEL (dans un délais de 3 coups d'horloge à partir de la phase de donnée)
   SIGNAL CntrDevSel     : Def_CntrDevSel;
   SIGNAL ChkSErr_Filter : std_logic_vector (1 downto 0);
   SIGNAL ChkPErr_Filter : std_logic_vector (1 downto 0);

----------------------------------------------------------------------------------------------
   ALIAS DevNum : Def_DevNum IS ProcToBridge.Addr(15 downto 11);

BEGIN

----------------------------------------------------------------------------------------------
SEQUENCER_PROCESS : PROCESS(CLK_PCI, nRST)
----------------------------------------------------------------------------------------------
  BEGIN
    IF nRST='0' THEN
      -- Signaux Internes
      State          <= Idle;
      CntrDevSel     <= (OTHERS=>'0');
      ChkSErr_Filter <= (OTHERS=>'0');
      ChkPErr_Filter <= (OTHERS=>'0');
      -- Arbitre
      nREQ           <= 'Z';
      -- Signaux PCI
      AD_Master      <= (OTHERS=>'0');
      CnBE_Master    <= (OTHERS=>'0');
      -- Signaux controle PCI (Maitre)
      IDSEL          <= (OTHERS=>'0');
      nFRAME         <= 'Z';
      nIRDY          <= 'Z';
      -- Signaux echange avec Interface_Proc
      ResStart       <= '0';
      BridgeToProc   <= (OTHERS=>'0');
      -- Commande Parity Checker
      ChkPar         <= '0';
      ChkPErr        <= '0';
      ChkSErr        <= '0';
      ResetError     <= '0';
      -- Commande Parity Generator
      GenPar         <= '0';
      -- Commande Buffers
      AD_OE          <= '0';
      CnBE_OE        <= '0';
      -- Status Bits
      TargetAbort    <= '0';
      MasterAbort    <= '0';
      ErrSystem      <= '0';
      Busy           <= '0';
      WaitGrant      <= '0';
      RxDone         <= '0';
      TxDone         <= '0';

    ELSIF CLK_PCI'EVENT AND CLK_PCI='1' THEN
      
      -- Start à été remis à zero par Interface_Proc, le signal ResStart peut être desactivé
      IF AckStart='1' THEN
         ResStart <= '0';
      END IF;
      
      -- Signal ChSErr retardé de 2 cycles CLK_PCI
      ChkSErr           <= ChkSErr_Filter(0);
      ChkSErr_Filter(0) <= ChkSErr_Filter(1);
    
      -- Signal ChPErr retardé de 2 cycles CLK_PCI
      ChkPErr           <= ChkPErr_Filter(0);
      ChkPErr_Filter(0) <= ChkPErr_Filter(1);
      
      CASE State IS
      --======================================================================================
      WHEN Idle =>
      --======================================================================================
         -- Le processeur n'a pas demandé de transfert.
         -- On ne demande pas le bus à l'arbitre.
         IF Start='0' THEN
            nREQ  <= '1';
            State <= Idle;
         
         -- Le processeur demande un transfert sur le bus PCI, mais le bridge n'a pas
         -- l'autorisation d'utiliser le bus. On fait une requete auprès
         -- de l'arbitre.
         ELSIF Start='1' AND nGNT='1' THEN
            nREQ      <= '0';
            WaitGrant <= '1';
            State     <= Idle;
         
         -- Le processeur demande un transfert sur le bus PCI, le bride a l'autorisation
         -- d'utiliser le bus (arbitre PCI a activé nGNT)
         -- Il faut tester le type de transfert à effectuer et vérifier qu'aucun autre maitre
         -- utilise le bus PCI (nFRAME et nIRDY inactifs).
         ELSIF Start='1' AND nGNT='0' AND nFRAME/='0' AND nIRDY/='0' THEN
            
            -- Mise à jour Status Bits
            TargetAbort    <= '0';
            MasterAbort    <= '0';
            ErrSystem      <= '0';
            WaitGrant      <= '0';
            RxDone         <= '0';
            TxDone         <= '0';
            
            -- Mise à jour Start et requete arbitre
            ResStart <= '1';
            nREQ     <= '1';
            
            -- Le transfert demandé est une lecture d'un registre dans
            -- l'espace de configuration d'un périphérique.
            -- On reinitialise les bits de Status, sauf Busy qui devient actif.
            -- La valeur du registre Addr est utilisée pour connaitre : 
            -- le type d'header PCI à utiliser, le bus destinataire, le périphérique
            -- destinataire (IDSEL), ...
            IF ProcToBridge.Cmd = CMD_RD_CFG THEN
               Busy        <= '1';                             -- Status
               ResetError  <= '1';
               AD_Master   <= GenCfgAddr(ProcToBridge.Addr);   -- PCI Signals
               CnBE_Master <= CMD_RD_CFG;
               AD_OE       <= '1';                             -- Buffers
               CnBE_OE     <= '1';
               IDSEL       <= GenIDSel(DevNum);                -- Signaux Master PCI
               nFRAME      <= '0';
               nIRDY       <= '1';
               GenPAR      <= '1';                             -- Parity Generator
               ChkSErr_Filter(1) <= '1';                       -- Parity Checker : SERR
               State       <= ReadConfig_A;                    -- State Sequencer
            
            -- Le transfert demandé est une écriture dans un registre de
            -- l'espace de configuration d'un périphérique PCI
            ELSIF ProcToBridge.Cmd = CMD_WR_CFG THEN
               Busy        <= '1';
               ResetError  <= '1';
               AD_Master   <= GenCfgAddr(ProcToBridge.Addr);
               CnBE_Master <= CMD_WR_CFG;
               AD_OE       <= '1';
               CnBE_OE     <= '1';
               IDSEL       <= GenIDSel(DevNum);
               nFRAME      <= '0';
               nIRDY       <= '1';
               GenPAR      <= '1';
               ChkSErr_Filter(1) <= '1';
               State       <= WriteConfig_A;
            
            -- Le transfert demandé est une lecture d'un registre de
            -- l'espace mémoire d'un périphérique PCI
            ELSIF ProcToBridge.Cmd = CMD_RD_MEM THEN
               Busy        <= '1';
               ResetError  <= '1';
               AD_Master   <= ProcToBridge.Addr;
               CnBE_Master <= CMD_RD_MEM;
               AD_OE       <= '1';
               CnBE_OE     <= '1';
               nFRAME      <= '0';
               nIRDY       <= '1';
               GenPAR      <= '1';
               ChkSErr_Filter(1) <= '1';
               State       <= ReadMem_A;
            
            -- Le transfert demandé est une écriture dans un registre de
            -- l'espace mémoire d'un périphérique PCI
            ELSIF ProcToBridge.Cmd = CMD_WR_MEM THEN
               Busy        <= '1';
               ResetError  <= '1';
               AD_Master   <= ProcToBridge.Addr;
               CnBE_Master <= CMD_WR_MEM;
               AD_OE       <= '1';
               CnBE_OE     <= '1';
               nFRAME      <= '0';
               nIRDY       <= '1';
               GenPAR      <= '1';
               ChkSErr_Filter(1) <= '1';
               State       <= WriteMem_A;
            END IF ;
         END IF;
--++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
-- | LECTURE ESPACE CONFIGURATION
--++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
      --======================================================================================
      WHEN ReadConfig_A =>
      --======================================================================================
         ResetError  <= '0';
         CnBE_Master <= ProcToBridge.ByteEn;
         AD_OE       <= '0';
         CnBE_OE     <= '1';
         IDSEL       <= (OTHERS=>'0');
         nFRAME      <= '1';
         nIRDY       <= '0';
         GenPAR      <= '0';
         ChkSErr_Filter(1) <= '0';
         CntrDevSel  <= (OTHERS=>'0');
         State       <= ReadConfig_D;
      --======================================================================================
      WHEN ReadConfig_D =>
      --======================================================================================
         -- Aucun périphéque n'a répondu à l'adresse au bout de trois coup d'horloge,
         -- On arrete le transfert sur le bus PCI et on signal au processeur
         -- que le Bridge a abandonnée le transefert car aucun périphérique n'a répondu.
         IF CntrDevSel="11" THEN
            Busy        <= '0';
            MasterAbort <= '1';
            CnBE_OE     <= '0';
            nFRAME      <= 'Z';
            nIRDY       <= '1';
            State       <= ReadConfig_TA;

         -- Cas impossible, nTRDY ou nSTOP ne peuvent pas etres actifs si nDEVSEL est inactif
         -- On génère une erreur et on stop le transfert PCI.
         ELSIF nDEVSEL/='0' AND (nTRDY='0' OR nSTOP='0') THEN
            Busy      <= '0';
            ErrSystem <= '1';
            CnBE_OE   <= '0';
            nFRAME    <= 'Z';
            nIRDY     <= '1';
            State     <= ReadConfig_TA;

         -- Aucun periphérique n'est présent, on incrémente le compteur de delais pour la 
         -- réponse des périphériques.
         ELSIF nDEVSEL/='0' AND nTRDY/='0' AND nSTOP/='0' THEN
            CntrDevSel  <= std_logic_vector(unsigned(CntrDevSel) + 1);
            State       <= ReadConfig_D;

         -- Un péphéque est présent et est prêt pour un transfert PCI,
         -- A ce stade ce périphérique à placé une donnée sur le bus AD,
         -- Le Bridge échantillone la donnée et confirme la fin de récéption.
         ELSIF nDEVSEL='0' AND nTRDY='0' AND nSTOP/='0' THEN
            BridgeToProc <= AD_In;
            RxDone       <= '1';
            Busy         <= '0';
            CnBE_OE      <= '0';
            nFRAME       <= 'Z';
            nIRDY        <= '1';
            ChkPar       <= '1';
            State        <= ReadConfig_TA;

         -- Un péphéque est présent mais n'est pas prêt pour un transfert PCI,
         -- Le périphérique n'a pas encore placé la donnée sur le bus AD.
         ELSIF nDEVSEL='0' AND nTRDY/='0' AND nSTOP/='0' THEN
            State <= ReadConfig_D;

         -- Un péphéque est présent,
         -- Il a demandé la fin du transfert en cours : nSTOP avec nTDRY actif,
         -- Il s'agit d'une déconnection avec transfert,
         -- A ce stade ce périphérique à placé une donnée sur le bus AD,
         -- Le Bridge échantillone la donnée et confirme la fin de récéption.
         ELSIF nDEVSEL='0' AND nTRDY='0' AND nSTOP='0' THEN
            BridgeToProc <= AD_In;
            RxDone       <= '1';
            Busy         <= '0';
            CnBE_OE      <= '0';
            nFRAME       <= 'Z';
            nIRDY        <= '1';
            ChkPar       <= '1';
            State        <= ReadConfig_TA;

         -- Un péphéque est présent,
         -- Il a demandé la fin du transfert en cours : nSTOP avec nTDRY inactif,
         -- Il s'agit d'une déconnection sans transfert,
         -- On stop la reception et on signal au processeur que la cible a abandonné
         -- le transfer le transfert sans fournir de donnée.
         ELSIF nDEVSEL='0' AND nTRDY/='0' AND nSTOP='0' THEN
            TargetAbort <= '1';
            Busy        <= '0';
            CnBE_OE     <= '0';
            nFRAME      <= 'Z';
            nIRDY       <= '1';
            State       <= ReadConfig_TA;
         END IF;
      --======================================================================================
      WHEN ReadConfig_TA =>
      --======================================================================================
         nIRDY  <= 'Z';
         ChkPar <= '0';
         State  <= Idle;
--++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
-- | ECRITURE ESPACE CONFIGURATION
--++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
      --======================================================================================
      WHEN WriteConfig_A =>
      --======================================================================================
         ResetError        <= '0';
         AD_Master         <= ProcToBridge.Data;
         CnBE_Master       <= ProcToBridge.ByteEn;
         AD_OE             <= '1';
         CnBE_OE           <= '1';
         IDSEL             <= (OTHERS=>'0');
         nFRAME            <= '1';
         nIRDY             <= '0';
         GenPar            <= '1';
         ChkPErr_Filter(1) <= '1';
         ChkSErr_Filter(1) <= '0';
         CntrDevSel        <= (OTHERS=>'0');
         State             <= WriteConfig_D;
      --======================================================================================
      WHEN WriteConfig_D =>
      --======================================================================================
         -- Aucun périphéque n'a répondu à l'adresse au bout de trois coups d'horloge,
         -- On arrete le transfert sur le bus PCI et on signal au processeur
         -- que le Bridge a abandonnée le transefert car aucun périphérique n'a répondu.
         IF CntrDevSel="11" THEN
            Busy              <= '0';
            MasterAbort       <= '1';
            AD_OE             <= '0';
            CnBE_OE           <= '0';
            nFRAME            <= 'Z';
            nIRDY             <= '1';
            GenPar            <= '0';
            ChkPErr_Filter(1) <= '0';
            State             <= WriteConfig_TA;
           
         -- Cas impossible, nTRDY ou nSTOP ne peuvent pas etres actifs si nDEVSEL est inactif
         -- On génère une erreur et on stop le transfert PCI.
         ELSIF nDEVSEL/='0' AND (nTRDY='0' OR nSTOP='0') THEN
            Busy              <= '0';
            ErrSystem         <= '1';
            AD_OE             <= '0';
            CnBE_OE           <= '0';
            nFRAME            <= 'Z';
            nIRDY             <= '1';
            GenPar            <= '0';
            ChkPErr_Filter(1) <= '0';
            State             <= WriteConfig_TA;
           
         -- Aucun periphérique présent car nDEVSEL=1, on incrémente le compteur de delais 
         -- pour la réponse des périphériques.
         ELSIF nDEVSEL/='0' AND nTRDY/='0' AND nSTOP/='0' THEN
            CntrDevSel <= std_logic_vector(unsigned(CntrDevSel) + 1);
            State      <= WriteConfig_D;
         
         -- Un péphéque est présent et est prêt pour un transfert PCI,
         -- A ce stade ce périphérique échantillonne la donnée sur le bus AD,
         -- Le Bridge confirme la fin de transmission.
         ELSIF nDEVSEL='0' AND nTRDY='0' AND nSTOP/='0' THEN
            TxDone            <= '1';
            Busy              <= '0';
            AD_OE             <= '0';
            CnBE_OE           <= '0';
            nFRAME            <= 'Z';
            nIRDY             <= '1';
            GenPar            <= '0';
            ChkPErr_Filter(1) <= '0';
            State             <= WriteConfig_TA;
               
         -- Un péphéque est présent mais n'est pas prêt pour un transfert PCI,
         -- Le périphérique n'a pas encore placé la donnée sur le bus AD.
         ELSIF nDEVSEL='0' AND nTRDY/='0' AND nSTOP/='0' THEN
            State <= WriteConfig_D;
               
         -- Un péphéque est présent,
         -- Il a demandé la fin du transfert en cours : nSTOP avec nTDRY actif,
         -- Il s'agit d'une déconnection avec transfert,
         -- A ce stade ce périphérique à placé une donnée sur le bus AD,
         -- Le Bridge échantillone la donnée et confirme la fin de récéption.
         ELSIF nDEVSEL='0' AND nTRDY='0' AND nSTOP='0' THEN
            TxDone            <= '1';
            Busy              <= '0';
            AD_OE             <= '0';
            CnBE_OE           <= '0';
            nFRAME            <= 'Z';
            nIRDY             <= '1';
            GenPar            <= '0';
            ChkPErr_Filter(1) <= '0';
            State             <= WriteConfig_TA;
           
         -- Un péphéque est présent,
         -- Il a demandé la fin du transfert en cours : nSTOP avec nTDRY inactif,
         -- Il s'agit d'une déconnection sans transfert,
         -- On stop la reception et on signal au processeur que la cible a abandonné
         -- le transfer le transfert sans fournir de donnée.
         ELSIF nDEVSEL='0' AND nTRDY/='0' AND nSTOP='0' THEN
            TargetAbort       <= '1';
            Busy              <= '0';
            AD_OE             <= '0';
            CnBE_OE           <= '0';
            nFRAME            <= 'Z';
            nIRDY             <= '1';
            GenPar            <= '0';
            ChkPErr_Filter(1) <= '0';
            State             <= WriteConfig_TA;
         END IF;
      --======================================================================================
      WHEN WriteConfig_TA =>
      --======================================================================================
         nIRDY <= 'Z';
         State <= Idle;

--++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
-- | LECTURE ESPACE MEMOIRE
--++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
      --======================================================================================
      WHEN ReadMem_A =>
      --======================================================================================
         ResetError        <= '0';
         CnBE_Master       <= ProcToBridge.ByteEn;
         AD_OE             <= '0';
         nFRAME            <= '1';
         nIRDY             <= '0';
         GenPar            <= '0';
         ChkSErr_Filter(1) <= '0';
         CntrDevSel        <= (OTHERS=>'0');
         State             <= ReadMem_D;
      --======================================================================================
      WHEN ReadMem_D =>
      --======================================================================================
         -- Aucun périphéque n'a répondu à l'adresse au bout de trois coup d'horloge,
         -- On arrete le transfert sur le bus PCI et on signal au processeur
         -- que le Bridge a abandonnée le transefert car aucun périphérique n'a répondu.
         IF CntrDevSel="11" THEN
            Busy        <= '0';
            MasterAbort <= '1';
            CnBE_OE     <= '0';
            nFRAME      <= 'Z';
            nIRDY       <= '1';
            State       <= ReadMem_TA;
            
         -- Cas impossible, nTRDY ou nSTOP ne peuvent pas etres actifs si nDEVSEL est inactif
         -- On génère une erreur et on stop le transfert PCI.
         ELSIF nDEVSEL/='0' AND (nTRDY='0' OR nSTOP='0') THEN
            Busy      <= '0';
            ErrSystem <= '1';
            CnBE_OE   <= '0';
            nFRAME    <= 'Z';
            nIRDY     <= '1';
            State     <= Idle;
         
         -- Aucun periphérique présent, on incrémente le compteur de delais pour la 
         -- réponse des périphériques.
         ELSIF nDEVSEL/='0' AND nTRDY/='0' AND nSTOP/='0' THEN
            CntrDevSel <= std_logic_vector(unsigned(CntrDevSel) + 1);
            State      <= ReadMem_D;
            
         -- Un péphéque est présent et est prêt pour un transfert PCI,
         -- A ce stade ce périphérique à placé une donnée sur le bus AD,
         -- Le Bridge échantillone la donnée et confirme la fin de récéption.
         ELSIF nDEVSEL='0' AND nTRDY='0' AND nSTOP/='0' THEN
            BridgeToProc <= AD_In;
            RxDone       <= '1';
            Busy         <= '0';
            CnBE_OE      <= '0';
            nFRAME       <= 'Z';
            nIRDY        <= '1';
            ChkPar       <= '1';
            State        <= ReadMem_TA;
                
         -- Un péphéque est présent mais n'est pas prêt pour un transfert PCI,
         -- Le périphérique n'a pas encore placé la donnée sur le bus AD.
         ELSIF nDEVSEL='0' AND nTRDY/='0' AND nSTOP/='0' THEN
            State <= ReadMem_D;
                
         -- Un péphéque est présent,
         -- Il a demandé la fin du transfert en cours : nSTOP avec nTDRY actif,
         -- Il s'agit d'une déconnection avec transfert,
         -- A ce stade ce périphérique à placé une donnée sur le bus AD,
         -- Le Bridge échantillone la donnée et confirme la fin de récéption.
         ELSIF nDEVSEL='0' AND nTRDY='0' AND nSTOP='0' THEN
            BridgeToProc <= AD_In;
            RxDone       <= '1';
            Busy         <= '0';
            CnBE_OE      <= '0';
            nFRAME       <= 'Z';
            nIRDY        <= '1';
            ChkPar       <= '1';
            State        <= ReadMem_TA;
            
         -- Un péphéque est présent,
         -- Il a demandé la fin du transfert en cours : nSTOP avec nTDRY inactif,
         -- Il s'agit d'une déconnection sans transfert,
         -- On stop la reception et on signal au processeur que la cible a abandonné
         -- le transfer le transfert sans fournir de donnée.
         ELSIF nDEVSEL='0' AND nTRDY/='0' AND nSTOP='0' THEN
            TargetAbort <= '1';
            Busy        <= '0';
            CnBE_OE     <= '0';
            nFRAME      <= 'Z';
            nIRDY       <= '1';
            State       <= ReadMem_TA;
         END IF;
      --======================================================================================
      WHEN ReadMem_TA =>
      --======================================================================================
         nIRDY  <= 'Z';
         ChkPar <= '0';
         State  <= Idle;

--++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
-- | ECRITURE ESPACE MEMOIRE
--++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
      --======================================================================================
      WHEN WriteMem_A =>
      --======================================================================================
         ResetError        <= '0';
         AD_Master         <= ProcToBridge.Data;
         CnBE_Master       <= ProcToBridge.ByteEn;
         AD_OE             <= '1';
         CnBE_OE           <= '1';
         nFRAME            <= '1';
         nIRDy             <= '0';
         GenPar            <= '1';
         ChkPErr_Filter(1) <= '1';
         ChkSErr_Filter(1) <= '0';
         CntrDevSel        <= (OTHERS=>'0');
         State             <= WriteMem_D;
      --======================================================================================
      WHEN WriteMem_D =>
      --======================================================================================
         -- Aucun périphéque n'a répondu à l'adresse au bout de trois coups d'horloge,
         -- On arrete le transfert sur le bus PCI et on signal au processeur
         -- que le Bridge a abandonnée le transefert car aucun périphérique n'a répondu.
         IF CntrDevSel="11" THEN
            Busy              <= '0';
            MasterAbort       <= '1';
            AD_OE             <= '0';
            CnBE_OE           <= '0';
            nFRAME            <= 'Z';
            nIRDY             <= '1';
            GenPar            <= '0';
            ChkPErr_Filter(1) <= '0';
            State             <= WriteMem_TA;

         -- Cas impossible, nTRDY ou nSTOP ne peuvent pas etres actifs si nDEVSEL est inactif
         -- On génère une erreur et on stop le transfert PCI.
         ELSIF nDEVSEL/='0' AND (nTRDY='0' OR nSTOP='0') THEN
            Busy              <= '0';
            ErrSystem         <= '1';
            AD_OE             <= '0';
            CnBE_OE           <= '0';
            nFRAME            <= 'Z';
            nIRDY             <= '1';
            GenPar            <= '0';
            ChkPErr_Filter(1) <= '0';
            State             <= WriteMem_TA;

         -- Aucun periphérique présent car nDEVSEL=1, on incrémente le compteur de delais 
         -- pour la réponse des périphériques.
         ELSIF nDEVSEL/='0' AND nTRDY/='0' AND nSTOP/='0' THEN
            CntrDevSel <= std_logic_vector(unsigned(CntrDevSel) + 1);
            State      <= WriteMem_D;

         -- Un péphéque est présent et est prêt pour un transfert PCI,
         -- A ce stade ce périphérique échantillonne la donnée sur le bus AD,
         -- Le Bridge confirme la fin de transmission.
         ELSIF nDEVSEL='0' AND nTRDY='0' AND nSTOP/='0' THEN
            TxDone            <= '1';
            Busy              <= '0';
            AD_OE             <= '0';
            CnBE_OE           <= '0';
            nFRAME            <= 'Z';
            nIRDY             <= '1';
            GenPar            <= '0';
            ChkPErr_Filter(1) <= '0';
            State             <= WriteMem_TA;

         -- Un péphéque est présent mais n'est pas prêt pour un transfert PCI,
         -- Le périphérique n'a pas encore placé la donnée sur le bus AD.
         ELSIF nDEVSEL='0' AND nTRDY/='0' AND nSTOP/='0' THEN
            State <= WriteMem_D;

         -- Un péphéque est présent,
         -- Il a demandé la fin du transfert en cours : nSTOP avec nTDRY actif,
         -- Il s'agit d'une déconnection avec transfert,
         -- A ce stade ce périphérique à placé une donnée sur le bus AD,
         -- Le Bridge échantillone la donnée et confirme la fin de récéption.
         ELSIF nDEVSEL='0' AND nTRDY='0' AND nSTOP='0' THEN
            TxDone            <= '1';
            Busy              <= '0';
            AD_OE             <= '0';
            CnBE_OE           <= '0';
            nFRAME            <= 'Z';
            nIRDY             <= '1';
            GenPar            <= '0';
            ChkPErr_Filter(1) <= '0';
            State             <= WriteMem_TA;

         -- Un péphéque est présent,
         -- Il a demandé la fin du transfert en cours : nSTOP avec nTDRY inactif,
         -- Il s'agit d'une déconnection sans transfert,
         -- On stop la reception et on signal au processeur que la cible a abandonné
         -- le transfer le transfert sans fournir de donnée.
         ELSIF nDEVSEL='0' AND nTRDY/='0' AND nSTOP='0' THEN
            TargetAbort       <= '1';
            Busy              <= '0';
            AD_OE             <= '0';
            CnBE_OE           <= '0';
            nFRAME            <= 'Z';
            nIRDY             <= '1';
            GenPar            <= '0';
            ChkPErr_Filter(1) <= '0';
            State             <= WriteMem_TA;
         END IF;
      --======================================================================================
      WHEN WriteMem_TA =>
      --======================================================================================
         nIRDY <= 'Z';
         State <= Idle;
      --======================================================================================
      WHEN OTHERS => NULL; 
      --======================================================================================
      END CASE;
   END IF;
END PROCESS SEQUENCER_PROCESS;

END ARCHITECTURE RTL;