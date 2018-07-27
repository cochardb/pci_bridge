-- ===========================================================================================
-- | ENTITY
-- ===========================================================================================
LIBRARY IEEE;
USE IEEE.STD_LOGIC_1164.all;
USE IEEE.NUMERIC_STD.ALL;

LIBRARY work;
USE work.PackageBridgePCI.ALL;

ENTITY Device_PCI IS
   GENERIC (
      GEN_BAR0 : Def_Dword := (OTHERS=>'0')
   );
   PORT (
      -- Signaux systeme
      CLK_PCI : IN    Def_Bit;
      nRST    : IN    Def_Bit;
      -- Signaux bus PCI
      AD      : INOUT Def_Dword;
      CnBE    : IN    Def_Cmd;
      PAR     : INOUT Def_Bit;
      -- Signaux controle PCI (Maitre)
      IDSEL   : IN    Def_Bit;
      nFRAME  : IN    Def_Bit;
      nIRDY   : IN    Def_Bit;
      -- Signaux controle PCI (Esclave)
      nDEVSEL : OUT   Def_Bit;
      nTRDY   : OUT   Def_Bit;
      nSTOP   : OUT   Def_Bit;
      -- Signaux erreur PCI
      nPERR   : OUT   Def_Bit;
      nSERR   : OUT   Def_Bit
   );
END ENTITY Device_PCI;

-- ===========================================================================================
-- | ARCHITECTURE
-- ===========================================================================================
LIBRARY IEEE;
USE IEEE.STD_LOGIC_1164.all;
USE IEEE.NUMERIC_STD.ALL;

LIBRARY work;
USE work.PackageBridgePCI.ALL;

ARCHITECTURE RTL OF Device_PCI IS

----------------------------------------------------------------------------------------------
   -- CONSTANTE ET REGISTRE DE L'ESPACE DE CONFIGURATION
   -- 
   -- Les registres BAR contiennent les adresses de base de la fonction (ici la fonction 0).
   -- Dans le registre BAR, les bits cablés à '0' signifie qu'on reserve une place.
   -- 
   -- Le nombre de registre reservable est compris entre 16B et 2GB (Doit toujours etre une 
   -- puissance de 2).
   -- 
   -- Pour connaitre la taille totale utilisée, le processeur écrit FFFFFFFFh dans le
   -- registre. Les bits cablés à '0' ne seront pas affecté par la valeur '1'. Ensuite le
   -- processeur vient relire le registre et calculé la taille utilisé par le périphérique.
   --
   -- Exemple : Le périph reserve 16B (donc 4 mots de 32bits).
   --  * 16 Byte reservé, dans le registre BAR on cable en dur les bits [3:0] à '0' (GND).
   --  * Pour connaitre la taille utilisé par le périphérique, le processeur va écrire 
   --    "FFFF_FFFF" dans le registre BAR. Comme les bits [3:0] sont à la masse, la valeur 
   --    final dans le regitre est "FFFF_FFF0".
   --  * Le processeur vient lire la valeur du registre BAR. Il voit "FFFF_FFF0". Pour 
   --    connaitre la taille il inverse tout les bits et ajoute +1 au résultat.
   --  * TAILLE = not(FFFF_FFF0) + 1 = 0000_000F + 1 = 0000_0010
   --  * On obtient la valeur 16 (en décimal) donc 16 octets on été réservé.
   --
   -- Par la suite le processeur peut venir écrire dans les bits non calblés à '0' pour
   -- affecter l'adresse de base du périphérique. Avec l'exemple précédent des adresse de 
   -- base possibles sont : "0000_0000", "0000_0010",  
   -- 
   -- Ici le périphérique : 
   --  * Réserve le minimum de registres (16B -> 4 mots de 32 bits)
   --  * Non prefetchable             : bit [3] = 0
   --  * Adresse des mots sur 32 bits : bits [2:1] = 0
   --  * Dans l'espace mémoire        : bit [0]
   constant BAR0_MASK : Def_Dword := X"FFFFFFF0";

   -- Champs par défaut du Header Type 0
   constant VENDOR_ID              : Def_Word   := X"5678";            -- Obligatoire
   constant DEVICE_ID              : Def_Word   := X"1234";            -- Obligatoire
   constant COMMAND                : Def_Word   := "0000000001000010"; -- Obligatoire
   constant STATUS                 : Def_Word   := "1000000000000000"; -- Obligatoire
   constant REVISION_ID            : Def_Byte   := X"01";              -- Obligatoire
   constant CLASS_CODE             : Def_3Bytes := X"000000";          -- Obligatoire
   constant CACHE_LINE_SIZE        : Def_Byte   := (OTHERS=>'0');
   constant LATENCY_TIMER          : Def_Byte   := (OTHERS=>'0');
   constant HEADER_TYPE            : Def_Byte   := X"00";              -- Obligatoire
   constant BIST                   : Def_Byte   := (OTHERS=>'0');
   constant BAR_0                  : Def_Dword  := GEN_BAR0 AND BAR0_MASK;
   constant BAR_1                  : Def_Dword  := (OTHERS=>'1');
   constant BAR_2                  : Def_Dword  := (OTHERS=>'1');
   constant BAR_3                  : Def_Dword  := (OTHERS=>'1');
   constant BAR_4                  : Def_Dword  := (OTHERS=>'1');
   constant BAR_5                  : Def_Dword  := (OTHERS=>'1');
   constant CARDBUS_CIS_PTR        : Def_Dword  := (OTHERS=>'0');
   constant SUBSYSTEM_VENDOR_ID    : Def_Word   := (OTHERS=>'0');
   constant SUBSYSTEM_ID           : Def_Word   := (OTHERS=>'0');
   constant EXPANSION_ROM_BASE     : Def_Dword  := (OTHERS=>'0');
   constant CAPABILITIES_PTR       : Def_Byte   := (OTHERS=>'0');
   constant RESERVED_0             : Def_3Bytes := (OTHERS=>'0');
   constant RESERVED_1             : Def_Dword  := (OTHERS=>'0');
   constant INTERRUPT_LINE         : Def_Byte   := (OTHERS=>'0');
   constant INTERUPT_PIN           : Def_Byte   := (OTHERS=>'0');
   constant MIN_GNT                : Def_Byte   := (OTHERS=>'0');
   constant MAX_LAT                : Def_Byte   := (OTHERS=>'0');

   -- Registres de l'espace de configuration (Partie Header)
   type Def_ConfigSpace is array (integer range 0 to 63) of Def_Dword;
   constant InitCfgSpace : Def_ConfigSpace := 
      ( DEVICE_ID & VENDOR_ID
      , STATUS & COMMAND
      , CLASS_CODE & REVISION_ID
      , BIST & HEADER_TYPE & LATENCY_TIMER & CACHE_LINE_SIZE
      , BAR_0
      , BAR_1
      , BAR_2
      , BAR_3
      , BAR_4
      , BAR_5
      , CARDBUS_CIS_PTR
      , SUBSYSTEM_ID & SUBSYSTEM_VENDOR_ID
      , EXPANSION_ROM_BASE
      , RESERVED_0 & CAPABILITIES_PTR
      , RESERVED_1
      , MAX_LAT & MIN_GNT & INTERUPT_PIN & INTERRUPT_LINE
      , (OTHERS=>'0'), (OTHERS=>'0'), (OTHERS=>'0'), (OTHERS=>'0')
      , (OTHERS=>'0'), (OTHERS=>'0'), (OTHERS=>'0'), (OTHERS=>'0')
      , (OTHERS=>'0'), (OTHERS=>'0'), (OTHERS=>'0'), (OTHERS=>'0')
      , (OTHERS=>'0'), (OTHERS=>'0'), (OTHERS=>'0'), (OTHERS=>'0')
      , (OTHERS=>'0'), (OTHERS=>'0'), (OTHERS=>'0'), (OTHERS=>'0')
      , (OTHERS=>'0'), (OTHERS=>'0'), (OTHERS=>'0'), (OTHERS=>'0')
      , (OTHERS=>'0'), (OTHERS=>'0'), (OTHERS=>'0'), (OTHERS=>'0')
      , (OTHERS=>'0'), (OTHERS=>'0'), (OTHERS=>'0'), (OTHERS=>'0')
      , (OTHERS=>'0'), (OTHERS=>'0'), (OTHERS=>'0'), (OTHERS=>'0')
      , (OTHERS=>'0'), (OTHERS=>'0'), (OTHERS=>'0'), (OTHERS=>'0')
      , (OTHERS=>'0'), (OTHERS=>'0'), (OTHERS=>'0'), (OTHERS=>'0')
      , (OTHERS=>'0'), (OTHERS=>'0'), (OTHERS=>'0'), (OTHERS=>'0')
      );
      
   -----------------------------
   -- | Champs Header
   -----------------------------
   signal Header      : Def_ConfigSpace;
   signal cfgOffset   : integer range 0 to 63;
   alias  MemSpaceEn  : Def_Bit is Header(1)(1);
   alias  BaseAddress : std_logic_vector(31 downto 4) is Header(4)(31 downto 4);

   -----------------------------
   -- | Espace Mémoire
   -----------------------------
   type     Def_MemSpace is array (integer range 0 to 3) of Def_Dword;
   constant InitMemSpace : Def_MemSpace := (OTHERS=>(OTHERS=>'0'));
   signal   MemSpace     : Def_MemSpace;
   signal   memOffset    : integer range 0 to 3;

   -----------------------------
   -- | Machine à états
   -----------------------------
   type Def_St IS ( Idle
                  , RdConfig_Busy, RdConfig_Data, RdConfig_TA
                  , WrConfig_Data, WrConfig_TA
                  , RdMem_Busy, RdMem_Data, RdMem_TA
                  , WrMem_Data, WrMem_TA );
   signal st : Def_St;
   
      -----------------------------
   -- | Echantillonnage AD PCI
   -----------------------------
   signal addr_pci  : Def_Dword;

   -----------------------------
   -- | Parité et Erreur
   -----------------------------
   signal GenPar     : Def_Bit;
   signal ChkParAddr : Def_Bit;
   signal ChkParData : Def_Bit;
   signal Local_PAR  : Def_Bit;

BEGIN

----------------------------------------------------------------------------------------------
   PARITY_CHK_PROCESS : PROCESS(CLK_PCI, nRST)
----------------------------------------------------------------------------------------------
BEGIN
   IF nRST = '0' then
      nSERR <= 'Z';
      nPERR <= 'Z';
      
   ELSIF CLK_PCI'EVENT AND CLK_PCI='1' THEN
      Local_PAR <= xor_reduct(AD & CnBE);
      
      IF ChkParAddr='1' THEN
         IF Local_PAR /= PAR THEN
            nSERR <= '0';
         ELSE
            nSERR <= '1';
         END IF;
      ELSE
         nSERR <= 'Z';
      END IF;
      
      IF ChkParData='1' THEN
         IF Local_PAR /= PAR THEN
            nPERR <= '0';
         ELSE
            nPERR <= '1';
         END IF;
      ELSE
         nPERR <= 'Z';
      END IF;
      
   END IF;
END PROCESS PARITY_CHK_PROCESS;

----------------------------------------------------------------------------------------------
   PARITY_GEN_PROCESS : PROCESS(CLK_PCI, nRST)
----------------------------------------------------------------------------------------------
BEGIN
   IF nRST = '0' then
      PAR <= 'Z';
   ELSIF CLK_PCI'EVENT AND CLK_PCI='1' THEN
      IF GenPar='1' THEN
         PAR <= xor_reduct( AD & CnBE);
      ELSE
         PAR <= 'Z';
      END IF;
   END IF;
END PROCESS PARITY_GEN_PROCESS;

----------------------------------------------------------------------------------------------
DEVICE_PROCESS : PROCESS(CLK_PCI, nRST)
----------------------------------------------------------------------------------------------
BEGIN
   IF nRST = '0' then
      GenPar     <= '0';
      ChkParAddr <= '0';
      ChkParData <= '0';
      Header     <= InitCfgSpace;
      cfgOffset  <= 0;
      MemSpace   <= InitMemSpace;
      memOffset  <= 0;
      addr_pci   <= (OTHERS=>'0');
      AD         <= (OTHERS=>'Z');
      nTRDY      <= 'Z';
      nSTOP      <= 'Z';
      nDEVSEL    <= 'Z';
      nPERR      <= 'Z';
      nSERR      <= 'Z';
      st         <= Idle;

   ELSIF CLK_PCI'EVENT AND CLK_PCI='1' THEN
      
      CASE st IS
      --======================================================================================
      WHEN Idle =>
      --======================================================================================
         IF nFRAME='0' THEN
            addr_pci  <= AD;
            cfgOffset <= to_integer(unsigned(AD(7 downto 2)));
            memOffset <= to_integer(unsigned(AD(3 downto 2)));
            
            IF IDSEL='1' AND AD(31)='1' AND AD(10 downto 8)="000" AND AD(1 downto 0)="00" THEN
               if CnBE = CMD_RD_CFG then
                  nTRDY   <= '1';
                  nSTOP   <= '1';
                  nDEVSEL <= '0';
                  ChkParAddr <= '1';
                  st      <= RdConfig_Busy;
               elsif CnBE = CMD_WR_CFG then
                  nTRDY   <= '0';
                  nSTOP   <= '1';
                  nDEVSEL <= '0';
                  ChkParAddr <= '1';
                  st      <= WrConfig_Data;
               end if;
            ELSIF MemSpaceEn='1' AND AD(31 downto 4)=BaseAddress THEN
               if CnBE = CMD_RD_MEM then
                  nTRDY   <= '1';
                  nSTOP   <= '1';
                  nDEVSEL <= '0';
                  ChkParAddr <= '1';
                  st      <= RdMem_Busy;
               elsif CnBE = CMD_WR_MEM then
                  nTRDY   <= '0';
                  nSTOP   <= '1';
                  nDEVSEL <= '0';
                  ChkParAddr <= '1';
                  st      <= WrMem_Data;
               end if;
            END IF;
         END IF;
         
----------------------------------------------------------------------------------------------
      --======================================================================================
      WHEN RdConfig_Busy =>
      --======================================================================================
         ChkParAddr <= '0';
         IF nIRDY='0' THEN
            -- BYTE EN 3
            if CnBE(3)='0' then
               AD(31 downto 24) <= Header(cfgOffset)(31 downto 24);
            else
               AD(31 downto 24) <= (OTHERS=>'0');
            end if;

            -- BYTE EN 2
            if CnBE(2)='0' then
               AD(23 downto 16) <= Header(cfgOffset)(23 downto 16);
            else
               AD(23 downto 16) <= (OTHERS=>'0');
            end if;

            -- BYTE EN 1
            if CnBE(1)='0' then
               AD(15 downto 8) <= Header(cfgOffset)(15 downto 8);
            else
               AD(15 downto 8) <= (OTHERS=>'0');
            end if;

            -- BYTE EN 1
            if CnBE(0)='0' then
               AD(7 downto 0) <= Header(cfgOffset)(7 downto 0);
            else
               AD(7 downto 0) <= (OTHERS=>'0');
            end if;

            nTRDY  <= '0';
            nSTOP  <= '1';
            GenPar <= '1';
            st     <= RdConfig_Data;
         END IF;
      --======================================================================================
      WHEN RdConfig_Data =>
      --======================================================================================
         AD      <= (OTHERS=>'Z');
         nTRDY   <= '1';
         nDEVSEL <= '1';
         nSTOP   <= '1';
         GenPar  <= '0';
         st      <= RdConfig_TA;
      --======================================================================================
      WHEN RdConfig_TA =>
      --======================================================================================
         nTRDY   <= 'Z';
         nDEVSEL <= 'Z';
         nSTOP   <= 'Z';
         st      <= Idle;
         
----------------------------------------------------------------------------------------------
      --======================================================================================
      WHEN WrConfig_Data =>
      --======================================================================================
         ChkParAddr <= '0';
         IF nIRDY='0' THEN
            -- BYTE EN 3
            if CnBE(3)='0' then
               Header(cfgOffset)(31 downto 24) <= AD(31 downto 24);
            end if;

            -- BYTE EN 2
            if CnBE(2)='0' then
               Header(cfgOffset)(23 downto 16) <= AD(23 downto 16);
            end if;

            -- BYTE EN 1
            if CnBE(1)='0' then
               Header(cfgOffset)(15 downto 8) <= AD(15 downto 8);
            end if;

            -- BYTE EN 1
            if CnBE(0)='0' then
               Header(cfgOffset)(7 downto 0) <= AD(7 downto 0);
            end if;

            nTRDY   <= '1' ;
            nSTOP   <= '1' ;
            nDEVSEL <= '1' ;
            ChkParData <= '1';
            st      <= WrConfig_TA;
         END IF;
      --======================================================================================
      WHEN WrConfig_TA =>
      --======================================================================================
         nTRDY   <= 'Z' ;
         nDEVSEL <= 'Z' ;
         nSTOP   <= 'Z' ;
         ChkParData <= '0';
         st      <= Idle;
         
----------------------------------------------------------------------------------------------
      --======================================================================================
      WHEN RdMem_Busy =>
      --======================================================================================
         ChkParAddr <= '0';
         IF nIRDY='0' THEN
            -- BYTE EN 3
            if CnBE(3)='0' then
               AD(31 downto 24) <= MemSpace(memOffset)(31 downto 24);
            else
               AD(31 downto 24) <= (OTHERS=>'0');
            end if;

            -- BYTE EN 2
            if CnBE(2)='0' then
               AD(23 downto 16) <= MemSpace(memOffset)(23 downto 16);
            else
               AD(23 downto 16) <= (OTHERS=>'0');
            end if;

            -- BYTE EN 1
            if CnBE(1)='0' then
               AD(15 downto 8) <= MemSpace(memOffset)(15 downto 8);
            else
               AD(15 downto 8) <= (OTHERS=>'0');
            end if;

            -- BYTE EN 1
            if CnBE(0)='0' then
               AD(7 downto 0) <= MemSpace(memOffset)(7 downto 0);
            else
               AD(7 downto 0) <= (OTHERS=>'0');
            end if;

            nTRDY  <= '0' ;
            nSTOP  <= '1' ;
            GenPar <= '1';
            st     <= RdMem_Data;
         END IF;
      --======================================================================================
      WHEN RdMem_Data =>
      --======================================================================================
         AD      <= (OTHERS=>'Z');
         nTRDY   <= '1' ;
         nDEVSEL <= '1' ;
         nSTOP   <= '1' ;
         GenPar  <= '0';
         st      <= RdMem_TA;
      --======================================================================================
      WHEN RdMem_TA =>
      --======================================================================================
         nTRDY   <= 'Z' ;
         nDEVSEL <= 'Z' ;
         nSTOP   <= 'Z' ;
         st      <= Idle;
         
----------------------------------------------------------------------------------------------
      --======================================================================================
      WHEN WrMem_Data =>
      --======================================================================================
         ChkParAddr <= '0';
         IF nIRDY='0' THEN
            -- BYTE EN 3
            if CnBE(3)='0' then
               MemSpace(memOffset)(31 downto 24) <= AD(31 downto 24);
            end if;

            -- BYTE EN 2
            if CnBE(2)='0' then
               MemSpace(memOffset)(23 downto 16) <= AD(23 downto 16);
            end if;

            -- BYTE EN 1
            if CnBE(1)='0' then
               MemSpace(memOffset)(15 downto 8) <= AD(15 downto 8);
            end if;

            -- BYTE EN 1
            if CnBE(0)='0' then
               MemSpace(memOffset)(7 downto 0) <= AD(7 downto 0);
            end if;

            nTRDY   <= '1' ;
            nSTOP   <= '1' ;
            nDEVSEL <= '1' ;
            ChkParData <= '1';
            st      <= WrMem_TA;
         END IF;
      --======================================================================================
      WHEN WrMem_TA =>
      --======================================================================================
         nTRDY   <= 'Z' ;
         nSTOP   <= 'Z' ;
         nDEVSEL <= 'Z' ;
         ChkParData <= '0';
         st <= Idle;
      
      END CASE;
   END IF;
END PROCESS DEVICE_PROCESS;

END ARCHITECTURE RTL;