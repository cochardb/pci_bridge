-- ===========================================================================================
-- | ENTITY
-- ===========================================================================================
LIBRARY IEEE;
USE IEEE.STD_LOGIC_1164.all;
USE IEEE.NUMERIC_STD.ALL;

LIBRARY work;
USE work.PackageBridgePCI.ALL;

ENTITY Interface_Read IS
   PORT( 
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
END ENTITY Interface_Read;

-- ===========================================================================================
-- | ARCHITECTURE
-- ===========================================================================================
LIBRARY IEEE;
USE IEEE.STD_LOGIC_1164.all;
USE IEEE.NUMERIC_STD.ALL;

LIBRARY work;
USE work.PackageBridgePCI.ALL;

ARCHITECTURE RTL OF Interface_Read IS

   ----------------------------------------------------
   -- | Alias
   ----------------------------------------------------
   ALIAS DBus_Byte0 IS Dbus(7 downto 0);
   ALIAS DBus_Byte1 IS Dbus(15 downto 8);
   ALIAS BridgeToProc_Byte0 IS BridgeToProc(7 downto 0);
   ALIAS BridgeToProc_Byte1 IS BridgeToProc(15 downto 8);
   ALIAS BridgeToProc_Byte2 IS BridgeToProc(23 downto 16);
   ALIAS BridgeToProc_Byte3 IS BridgeToProc(31 downto 24);
   ALIAS BridgeToProc_Word0 IS BridgeToProc(15 downto 0);
   ALIAS BridgeToProc_Word1 IS BridgeToProc(31 downto 16);

BEGIN

----------------------------------------------------------------------------------------------
READ_PROCESS : PROCESS(Addr, RnW, nAS, nBE, nCS, nRST, Status, BridgeToProc)
----------------------------------------------------------------------------------------------
BEGIN
   IF nRST='0' THEN
      DBus <= (OTHERS=>'Z');

   ELSIF RnW='1' AND nAS='0' AND nCS='0' THEN
      CASE Addr IS
      -- =====================================================================================
      -- | Registre STATUS (16 bits)
      -- =====================================================================================
      WHEN OFFSET_STAT_0 =>
         CASE nBE IS
            WHEN EIGHT_BITS =>
               DBus_Byte1 <= (OTHERS=>'0');
               DBus_Byte0 <= status_to_vector(Status)(7 downto 0);
            WHEN BIG_ENDIAN =>
               DBus_Byte1 <= status_to_vector(Status)(7 downto 0);
               DBus_Byte0 <= "000000" & status_to_vector(Status)(9 downto 8);
            WHEN OTHERS =>
               DBus_Byte1 <= "000000" & status_to_vector(Status)(9 downto 8);
               DBus_Byte0 <= status_to_vector(Status)(7 downto 0);
         END CASE;

      WHEN OFFSET_STAT_1 =>
         CASE nBE IS
            WHEN EIGHT_BITS =>
               DBus_Byte1 <= (OTHERS=>'0');
               DBus_Byte0 <= "000000" & status_to_vector(Status)(9 downto 8);
            WHEN BIG_ENDIAN =>
               DBus_Byte1 <= status_to_vector(Status)(7 downto 0);
               DBus_Byte0 <= "000000" & status_to_vector(Status)(9 downto 8);
            WHEN OTHERS =>
               DBus_Byte1 <= "000000" & status_to_vector(Status)(9 downto 8);
               DBus_Byte0 <= status_to_vector(Status)(7 downto 0);
         END CASE;

      -- =====================================================================================
      -- | Registre DATA_REC (32 bits)
      -- =====================================================================================
      WHEN OFFSET_DREC_0 =>
         CASE nBE IS
            WHEN EIGHT_BITS => DBus <= "00000000" & BridgeToProc_Byte0;
            WHEN BIG_ENDIAN => DBus <= BridgeToProc_Byte0 & BridgeToProc_Byte1;
            WHEN OTHERS     => DBus <= BridgeToProc_Word0;
         END CASE;

      WHEN OFFSET_DREC_1 =>
         CASE nBE IS
            WHEN EIGHT_BITS => DBus <= "00000000" & BridgeToProc_Byte1;
            WHEN BIG_ENDIAN => DBus <= BridgeToProc_Byte0 & BridgeToProc_Byte1;
            WHEN OTHERS     => DBus <= BridgeToProc_Word0;
         END CASE;

      WHEN OFFSET_DREC_2 =>
         CASE nBE IS
            WHEN EIGHT_BITS => DBus <= "00000000" & BridgeToProc_Byte2;
            WHEN BIG_ENDIAN => DBus <= BridgeToProc_Byte2 & BridgeToProc_Byte3;
            WHEN OTHERS     => DBus <= BridgeToProc_Word1;
         END CASE;

      WHEN OFFSET_DREC_3 =>
         CASE nBE IS
            WHEN EIGHT_BITS => DBus <= "00000000" & BridgeToProc_Byte3;
            WHEN BIG_ENDIAN => DBus <= BridgeToProc_Byte2 & BridgeToProc_Byte3;
            WHEN OTHERS     => DBus <= BridgeToProc_Word1;
         END CASE;

      -- =====================================================================================
      -- | Registre en écriture seule
      -- =====================================================================================
      WHEN OFFSET_ADDR_0 =>   DBus <= (OTHERS=>'0');
      WHEN OFFSET_ADDR_1 =>   DBus <= (OTHERS=>'0');
      WHEN OFFSET_ADDR_2 =>   DBus <= (OTHERS=>'0');
      WHEN OFFSET_ADDR_3 =>   DBus <= (OTHERS=>'0');
      WHEN OFFSET_DATA_0 =>   DBus <= (OTHERS=>'0');
      WHEN OFFSET_DATA_1 =>   DBus <= (OTHERS=>'0');
      WHEN OFFSET_DATA_2 =>   DBus <= (OTHERS=>'0');
      WHEN OFFSET_DATA_3 =>   DBus <= (OTHERS=>'0');
      WHEN OFFSET_CTRL_0 =>   DBus <= (OTHERS=>'0');
      WHEN OFFSET_CTRL_1 =>   DBus <= (OTHERS=>'0');
      WHEN OTHERS        =>   DBus <= (OTHERS=>'0');
      END CASE;

   ELSE
      DBus <= (OTHERS=>'Z');
   END IF;
END PROCESS READ_PROCESS;

END ARCHITECTURE RTL;