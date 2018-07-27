-- ===========================================================================================
-- | ENTITY
-- ===========================================================================================
LIBRARY IEEE;
USE IEEE.STD_LOGIC_1164.all;
USE IEEE.NUMERIC_STD.ALL;

LIBRARY work;
USE work.PackageBridgePCI.ALL;

ENTITY Interface_Write IS
   PORT( 
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
END ENTITY Interface_Write;

-- ===========================================================================================
-- | ARCHITECTURE
-- ===========================================================================================
LIBRARY IEEE;
USE IEEE.STD_LOGIC_1164.all;
USE IEEE.NUMERIC_STD.ALL;

LIBRARY work;
USE work.PackageBridgePCI.ALL;

ARCHITECTURE RTL OF Interface_Write IS

   ----------------------------------------------------
   -- | Alias
   ----------------------------------------------------
   ALIAS Addr_Byte0 IS ProcToBridge.Addr(7 downto 0);
   ALIAS Addr_Byte1 IS ProcToBridge.Addr(15 downto 8);
   ALIAS Addr_Byte2 IS ProcToBridge.Addr(23 downto 16);
   ALIAS Addr_Byte3 IS ProcToBridge.Addr(31 downto 24);
   ALIAS Addr_Word0 IS ProcToBridge.Addr(15 downto 0);
   ALIAS Addr_Word1 IS ProcToBridge.Addr(31 downto 16);
   ALIAS Data_Byte0 IS ProcToBridge.Data(7 downto 0);
   ALIAS Data_Byte1 IS ProcToBridge.Data(15 downto 8);
   ALIAS Data_Byte2 IS ProcToBridge.Data(23 downto 16);
   ALIAS Data_Byte3 IS ProcToBridge.Data(31 downto 24);
   ALIAS Data_Word0 IS ProcToBridge.Data(15 downto 0);
   ALIAS Data_Word1 IS ProcToBridge.Data(31 downto 16);
   ALIAS ByteEn     IS ProcToBridge.ByteEn;
   ALIAS Cmd        IS ProcToBridge.Cmd;
   ALIAS DBus_Byte0 IS Dbus(7 downto 0);
   ALIAS DBus_Byte1 IS Dbus(15 downto 8);

BEGIN

-- =======================================|
-- | Table vérité nBE[0:1]                |
-- =======================================|
-- |BE[1:0]   | Mode                      |
-- |--------------------------------------|
-- | 00       | 8 bits                    |
-- | 01       | 16 bits - little endian   |
-- | 10       | 16 bits - big endian      |
-- | 11       | 16 bits - little endian   |
-- |--------------------------------------|

----------------------------------------------------------------------------------------------
WRITE_PROCESS : PROCESS(CLK, nRST) IS
----------------------------------------------------------------------------------------------
BEGIN
   IF nRST='0' THEN
      ProcToBridge.Addr   <= (OTHERS=>'0');
      ProcToBridge.Data   <= (OTHERS=>'0');
      ProcToBridge.ByteEn <= (OTHERS=>'0');
      ProcToBridge.Cmd    <= (OTHERS=>'0');
      Start               <= '0';
      AckStart            <= '0';

   ELSIF CLK'EVENT AND CLK='1' THEN
      
      -- Remise à zéro de start
      IF ResStart='1' THEN
         Start    <= '0';
         AckStart <= '1';
      ELSE
         AckStart <= '0';
      END IF;
      
      -- Le processeur ecrit une donnée dans un registre
      IF RnW='0' AND nAS='0' AND nCS='0' THEN
         CASE Addr IS
         -- ==================================================================================
         -- | Registre ADDR (32 bits)
         -- ==================================================================================
         WHEN OFFSET_ADDR_0 =>  
            CASE nBE IS
               WHEN EIGHT_BITS => Addr_Byte0 <= DBus_Byte0;
               WHEN BIG_ENDIAN => Addr_Word0 <= DBus_Byte0 & DBus_Byte1;
               WHEN OTHERS     => Addr_Word0 <= DBus;
            END CASE;

         WHEN OFFSET_ADDR_1 =>
            CASE nBE IS
               WHEN EIGHT_BITS => Addr_Byte1 <= DBus_Byte0;
               WHEN BIG_ENDIAN => Addr_Word0 <= DBus_Byte0 & DBus_Byte1;
               WHEN OTHERS     => Addr_Word0 <= DBus;
            END CASE;  

         WHEN OFFSET_ADDR_2 =>
            CASE nBE IS
               WHEN EIGHT_BITS => Addr_Byte2 <= DBus_Byte0;
               WHEN BIG_ENDIAN => Addr_Word1 <= DBus_Byte0 & DBus_Byte1;
               WHEN OTHERS     => Addr_Word1 <= DBus;
            END CASE;

         WHEN OFFSET_ADDR_3 =>
            CASE nBE IS
               WHEN EIGHT_BITS => Addr_Byte3 <= DBus_Byte0;
               WHEN BIG_ENDIAN => Addr_Word1 <= DBus_Byte0 & DBus_Byte1;
               WHEN OTHERS     => Addr_Word1 <= DBus;
            END CASE;

         -- ==================================================================================
         -- | Registre DATA_TO_SEND (32 bits)
         -- ==================================================================================
         WHEN OFFSET_DATA_0 =>
            CASE nBE IS
               WHEN EIGHT_BITS => Data_Byte0 <= DBus_Byte0;
               WHEN BIG_ENDIAN => Data_Word0 <= DBus_Byte0 & DBus_Byte1;
               WHEN OTHERS     => Data_Word0 <= DBus;
            END CASE;

         WHEN OFFSET_DATA_1 =>
            CASE nBE IS
               WHEN EIGHT_BITS => Data_Byte1 <= DBus_Byte0;
               WHEN BIG_ENDIAN => Data_Word0 <= DBus_Byte0 & DBus_Byte1;
               WHEN OTHERS     => Data_Word0 <= DBus;
            END CASE;  

         WHEN OFFSET_DATA_2 =>
            CASE nBE IS
               WHEN EIGHT_BITS => Data_Byte2 <= DBus_Byte0;
               WHEN BIG_ENDIAN => Data_Word1 <= DBus_Byte0 & DBus_Byte1;
               WHEN OTHERS     => Data_Word1 <= DBus;
            END CASE;

         WHEN OFFSET_DATA_3 =>
            CASE nBE IS
               WHEN EIGHT_BITS => Data_Byte3 <= DBus_Byte0;
               WHEN BIG_ENDIAN => Data_Word1 <= DBus_Byte0 & DBus_Byte1;
               WHEN OTHERS     => Data_Word1 <= DBus;
            END CASE;

         -- ==================================================================================
         -- | Registre de configuration (16 bits)
         -- ==================================================================================
         WHEN OFFSET_CTRL_0 =>
            CASE nBE IS
               WHEN EIGHT_BITS =>
                  Cmd    <= DBus(3 downto 0);
                  ByteEn <= Dbus(7 downto 4);
               WHEN BIG_ENDIAN =>
                  Cmd    <= DBus(11 downto 8);
                  ByteEn <= Dbus(15 downto 12);
                  Start  <= DBus(0);
               WHEN OTHERS =>
                  Cmd    <= DBus(3  downto 0);
                  ByteEn <= Dbus(7  downto 4);
                  Start  <= DBus(8);
            END CASE;

         WHEN OFFSET_CTRL_1 =>  
            CASE nBE IS
               WHEN EIGHT_BITS =>
                  Start <= DBus(0);
               WHEN BIG_ENDIAN =>
                  Cmd    <= DBus(11  downto 8);
                  ByteEn <= Dbus(15  downto 12);
                  Start  <= DBus(0);
               WHEN OTHERS =>
                  Cmd    <= DBus(3  downto 0);
                  ByteEn <= Dbus(7  downto 4);
                  Start  <= DBus(8);
            END CASE;

         -- ==================================================================================
         -- | Registre en lecture seule
         -- ==================================================================================
         WHEN OFFSET_STAT_0 =>  -- Read Only
         WHEN OFFSET_STAT_1 =>  -- Read Only
         WHEN OFFSET_DREC_0 =>  -- Read Only
         WHEN OFFSET_DREC_1 =>  -- Read Only
         WHEN OFFSET_DREC_2 =>  -- Read Only
         WHEN OFFSET_DREC_3 =>  -- Read Only
         WHEN OTHERS   =>
         END CASE;
      END IF;
   END IF;
END PROCESS WRITE_PROCESS;

END ARCHITECTURE RTL;