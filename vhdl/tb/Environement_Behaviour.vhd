-- ===========================================================================================
-- | ENTITY
-- ===========================================================================================
LIBRARY IEEE;
USE IEEE.STD_LOGIC_1164.all;
USE IEEE.NUMERIC_STD.ALL;

LIBRARY work;
USE work.PackageBridgePCI.ALL;

ENTITY Environement IS
   PORT( 
      -- Signaux systeme
      CLK     : OUT     Def_Bit ;
      CLK_PCI : INOUT   Def_Bit ;
      nRST    : OUT     Def_Bit ;
      -- Signaux Processeur
      ADDR    : OUT     Def_AddrProc ;
      DBus    : INOUT   Def_DBus ;
      nAS     : OUT     Def_Bit ;
      RnW     : OUT     Def_Bit ;
      nCS     : OUT     Def_Bit ;
      nBE     : OUT     Def_Endianness ;
      -- Signaux arbitre PCI
      nGNT    : OUT     Def_Bit ;
      nREQ    : IN      Def_Bit ;
      -- Signaux bus PCI
      AD      : INOUT   Def_Dword ;
      CnBE    : IN      Def_Cmd ;
      PAR     : INOUT   Def_Bit ;
      -- Signaux controle PCI (Maitre)
      IDSEL   : IN      Def_IDSel ;
      nFRAME  : INOUT   Def_Bit ;
      nIRDY   : INOUT   Def_Bit ;
      -- Signaux controle PCI (Esclave)
      nDEVSEL : OUT     Def_Bit ;
      nTRDY   : OUT     Def_Bit ;
      nSTOP   : OUT     Def_Bit ;
      -- Signaux erreur PCI
      nPERR   : INOUT   Def_Bit ;
      nSERR   : OUT     Def_Bit
   );
END ENTITY Environement;

-- ===========================================================================================
-- | ARCHITECTURE
-- ===========================================================================================
LIBRARY IEEE;
USE IEEE.STD_LOGIC_1164.all;
USE IEEE.NUMERIC_STD.ALL;

LIBRARY work;
USE work.PackageBridgePCI.ALL;

ARCHITECTURE Behaviour OF Environement IS
   
   --------------------------------
   -- Signaux internes
   --------------------------------
   SIGNAL IntClkPCI : Def_Bit;
   SIGNAL IntClk    : Def_Bit;
   SIGNAL IntReset  : Def_Bit;
   
   --------------------------------
   -- Composant Eslave sur le bus PCI
   --------------------------------
   COMPONENT Device_PCI IS
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
   END COMPONENT Device_PCI;

BEGIN

----------------------------------------------------------------------------------------------
-- | Affectation sorties
----------------------------------------------------------------------------------------------
   CLK_PCI <= IntClkPCI;
   CLK     <= IntClk;
   nRST    <= IntReset;

----------------------------------------------------------------------------------------------
-- | Pull Up bus PCI
----------------------------------------------------------------------------------------------
   nFRAME  <= 'H';
   nTRDY   <= 'H';
   nIRDY   <= 'H';
   nSTOP   <= 'H';
   nDEVSEL <= 'H';
   nPERR   <= 'H';
   nSERR   <= 'H';

----------------------------------------------------------------------------------------------
CLOCK_PCI_GENERATOR : PROCESS
----------------------------------------------------------------------------------------------
BEGIN
   IntClkPCI <= '0';
   WAIT FOR 15.15 ns;
   IntClkPCI <= '1';
   WAIT FOR 15.15 ns;
END PROCESS CLOCK_PCI_GENERATOR;

----------------------------------------------------------------------------------------------
CLOCK_GENERATOR : PROCESS
----------------------------------------------------------------------------------------------
BEGIN
   IntClk <= '0';
   WAIT FOR 30 ns;
   IntClk <= '1';
   WAIT FOR 30 ns;
END PROCESS CLOCK_GENERATOR;

----------------------------------------------------------------------------------------------
RESET_GENERATOR : PROCESS
----------------------------------------------------------------------------------------------
BEGIN
   IntReset <= '0';
   WAIT FOR 100 ns;
   IntReset <= '1';
   WAIT;
END PROCESS RESET_GENERATOR;

----------------------------------------------------------------------------------------------
ARBITER_PROCESS : PROCESS
----------------------------------------------------------------------------------------------
BEGIN
   nGNT <= '1';
   WAIT FOR 150 ns;
   nGNT <= '0';
   WAIT;
END PROCESS;

----------------------------------------------------------------------------------------------
PROC_PROCESS : PROCESS
----------------------------------------------------------------------------------------------
   -- Signaux internes : Processeur
   VARIABLE pci_Addr  : Def_Addr;
   VARIABLE pci_data  : Def_Dword;
   VARIABLE pci_cmdbe : Def_Word;
   
   --------------------------------
   -- Ecriture 8 bits
   --------------------------------
   PROCEDURE proc_write_8b( address : IN Def_AddrProc; data : IN Def_DBus) IS
   BEGIN
      Addr <= address;
      Dbus <= "00000000" & data(7 downto 0);
      nAS  <= '0';   nCS  <= '0';   RnW  <= '0';   nBE  <= EIGHT_BITS;
   END proc_write_8b;
   
   --------------------------------
   -- Ecriture Big Endian
   --------------------------------
   PROCEDURE proc_write_be( address : IN Def_AddrProc; data : IN Def_DBus) IS
   BEGIN
      Addr <= address;
      Dbus <= data(7 downto 0) & data(15 downto 8);
      nAS  <= '0';   nCS  <= '0';   RnW  <= '0';   nBE  <= BIG_ENDIAN;
   END proc_write_be;
   
   --------------------------------
   -- Ecriture Little Endian
   --------------------------------
   PROCEDURE proc_write_le( address : IN Def_AddrProc; data : IN Def_DBus) IS
   BEGIN
      Addr <= address;
      Dbus <= data;
      nAS  <= '0';   nCS  <= '0';   RnW  <= '0';   nBE <= LIT_ENDIAN;
   END proc_write_le;
   
   --------------------------------
   -- Lecture Big Endian
   --------------------------------
   PROCEDURE proc_read_be( address : IN Def_AddrProc) IS
   BEGIN
      Addr <= address;
      Dbus <= (OTHERS=>'Z');
      nAS  <= '0';   nCS  <= '0';   RnW  <= '1';   nBE  <= BIG_ENDIAN;
   END proc_read_be;

   --------------------------------
   -- Lecture Little Endian
   --------------------------------
   PROCEDURE proc_read_le( address : IN Def_AddrProc) IS
   BEGIN
      Addr <= address;
      Dbus <= (OTHERS=>'Z');
      nAS  <= '0';   nCS  <= '0';   RnW  <= '1';   nBE  <= LIT_ENDIAN;
   END proc_read_le;

   --------------------------------
   -- Lecture 8 bits
   --------------------------------
   PROCEDURE proc_read_8b( address : IN Def_AddrProc) IS
   BEGIN
      Addr <= address;
      Dbus <= (OTHERS=>'Z');
      nAS  <= '0';   nCS  <= '0';   RnW  <= '1';   nBE  <= EIGHT_BITS;
   END proc_read_8b;
   
   --------------------------------
   -- Processeur repos
   --------------------------------
   PROCEDURE proc_idle IS
   BEGIN
      Addr <= (OTHERS=>'0');
      Dbus <= (OTHERS=>'Z');
      nAS  <= '1';   nCS  <= '1';   RnW  <= '1';   nBE <= "11";
   END proc_idle;

BEGIN
   -------------------------------------------------------------------------------------------
   -- | 0) T = 0
   -------------------------------------------------------------------------------------------
   proc_idle;
   wait for 110 ns;
   
   -------------------------------------------------------------------------------------------
   -- | 1) Configuration lecture espace config Device 0, Fonction 0, Registre 0
   -------------------------------------------------------------------------------------------
   pci_Addr  := ENABLE & RESERVED & BUS0 & DEV0 & FCT0 & CFG_REG0 & TYPE0;
   pci_cmdbe := "0000" & "000" & START & ALL_BYTES_EN & CMD_RD_CFG;
   
   wait until rising_edge(IntClk);
   proc_write_le(OFFSET_ADDR_0, pci_Addr(15 downto 0));
   
   wait until rising_edge(IntClk);
   proc_write_le(OFFSET_ADDR_2, pci_Addr(31 downto 16));
   
   wait until rising_edge(IntClk);
   proc_write_le(OFFSET_CTRL_0, pci_cmdbe);
   
   wait until rising_edge(IntClk);
   proc_idle;
   
   -------------------------------------------------------------------------------------------
   -- | 2) Configuration écriture espace config Device 0, Fonction 0, Registre 32
   -------------------------------------------------------------------------------------------
   wait for 200 ns;
   pci_Addr  := ENABLE & RESERVED & BUS0 & DEV0 & FCT0 & CFG_REG32 & TYPE0;
   pci_data  := X"12345678";
   pci_cmdbe := "0000" & "000" & START & ALL_BYTES_EN & CMD_WR_CFG;
   
   wait until rising_edge(IntClk);
   proc_write_le(OFFSET_ADDR_0, pci_Addr(15 downto 0));
   
   wait until rising_edge(IntClk);
   proc_write_le(OFFSET_ADDR_2, pci_Addr(31 downto 16));
   
   wait until rising_edge(IntClk);
   proc_write_le(OFFSET_DATA_0, pci_data(15 downto 0));
   
   wait until rising_edge(IntClk);
   proc_write_le(OFFSET_DATA_2, pci_data(31 downto 16));
   
   wait until rising_edge(IntClk);
   proc_write_le(OFFSET_CTRL_0, pci_cmdbe);
   
   wait until rising_edge(IntClk);
   proc_idle;
   
   -------------------------------------------------------------------------------------------
   -- | 3) Configuration écriture espace memoire Device 2, Fonction 0, Registre 1 (32bits)
   -------------------------------------------------------------------------------------------
   wait for 200 ns;
   pci_Addr  := X"00000024" or X"00000003";
   pci_data  := X"55555555";
   pci_cmdbe := "0000" & "000" & START & ALL_BYTES_EN & CMD_WR_MEM;
   
   wait until rising_edge(IntClk);
   proc_write_le(OFFSET_ADDR_0, pci_Addr(15 downto 0));
   
   wait until rising_edge(IntClk);
   proc_write_le(OFFSET_ADDR_2, pci_Addr(31 downto 16));
   
   wait until rising_edge(IntClk);
   proc_write_le(OFFSET_DATA_0, pci_data(15 downto 0));
   
   wait until rising_edge(IntClk);
   proc_write_le(OFFSET_DATA_2, pci_data(31 downto 16));
   
   wait until rising_edge(IntClk);
   proc_write_le(OFFSET_CTRL_0, pci_cmdbe);
   
   wait until rising_edge(IntClk);
   proc_idle;
   
   -------------------------------------------------------------------------------------------
   -- | 4) Configuration lecture espace memoire Device 2, Fonction 0, Registre 1 (32bits)
   -------------------------------------------------------------------------------------------
   wait for 200 ns;
   pci_Addr  := X"00000024" or X"00000003";
   pci_cmdbe := "0000" & "000" & START & ALL_BYTES_EN & CMD_RD_MEM;
   
   wait until rising_edge(IntClk);
   proc_write_le(OFFSET_ADDR_0, pci_Addr(15 downto 0));
   
   wait until rising_edge(IntClk);
   proc_write_le(OFFSET_ADDR_2, pci_Addr(31 downto 16));
   
   wait until rising_edge(IntClk);
   proc_write_le(OFFSET_CTRL_0, pci_cmdbe);
   
   wait until rising_edge(IntClk);
   proc_idle;
   
   -------------------------------------------------------------------------------------------
   -- | 5) Test Ecriture Big Endian
   -------------------------------------------------------------------------------------------
   wait for 200 ns;
   pci_data := X"ABCDEF85";
   
   wait until rising_edge(IntClk);
   proc_write_be(OFFSET_DATA_0, pci_data(15 downto 0));
   
   wait until rising_edge(IntClk);
   proc_write_be(OFFSET_DATA_2, pci_data(31 downto 16));
   
   wait until rising_edge(IntClk);
   proc_idle;
   
   -------------------------------------------------------------------------------------------
   -- | 6) Lecture registre Status du bridge
   -------------------------------------------------------------------------------------------
   wait for 200 ns;
   
   wait until rising_edge(IntClk);
   proc_read_le(OFFSET_STAT_0);
   
   wait until rising_edge(IntClk);
   proc_idle;

   -------------------------------------------------------------------------------------------
   -- | 7) Configuration écriture espace memoire sans device
   -------------------------------------------------------------------------------------------
   wait for 200 ns;
   pci_Addr  := X"00000050";
   pci_data  := X"98765432";
   pci_cmdbe := "0000" & "000" & START & ALL_BYTES_EN & CMD_WR_MEM;
   
   wait until rising_edge(IntClk);
   proc_write_le(OFFSET_ADDR_0, pci_Addr(15 downto 0));
   
   wait until rising_edge(IntClk);
   proc_write_le(OFFSET_ADDR_2, pci_Addr(31 downto 16));
   
   wait until rising_edge(IntClk);
   proc_write_le(OFFSET_DATA_0, pci_data(15 downto 0));
   
   wait until rising_edge(IntClk);
   proc_write_le(OFFSET_DATA_2, pci_data(31 downto 16));
   
   wait until rising_edge(IntClk);
   proc_write_le(OFFSET_CTRL_0, pci_cmdbe);
   
   wait until rising_edge(IntClk);
   proc_idle;
   
   -------------------------------------------------------------------------------------------
   -- | 8) Configuration écriture espace memoire Device 1, Fonction 0, Registre 2 (32bits)
   -------------------------------------------------------------------------------------------
   wait for 200 ns;
   pci_Addr  := X"00000028";
   pci_data  := X"18012018";
   pci_cmdbe := "0000" & "000" & START & ALL_BYTES_EN & CMD_WR_MEM;
   
   wait until rising_edge(IntClk);
   proc_write_le(OFFSET_ADDR_0, pci_Addr(15 downto 0));
   
   wait until rising_edge(IntClk);
   proc_write_le(OFFSET_ADDR_2, pci_Addr(31 downto 16));
   
   wait until rising_edge(IntClk);
   proc_write_le(OFFSET_DATA_0, pci_data(15 downto 0));
   
   wait until rising_edge(IntClk);
   proc_write_le(OFFSET_DATA_2, pci_data(31 downto 16));
   
   wait until rising_edge(IntClk);
   proc_write_le(OFFSET_CTRL_0, pci_cmdbe);
   
   wait until rising_edge(IntClk);
   proc_idle;

   WAIT;
END PROCESS PROC_PROCESS;

----------------------------------------------------------------------------------------------
   -- PLAN MEMOIRE PCI
   -- ____________
   -- |          | 0x0000_0000
   -- | Device 0 | 0x0000_0004
   -- |          | 0x0000_0008
   -- |__________| 0x0000_000C
   -- |          | 0x0000_0010
   -- | Device 1 | 0x0000_0014
   -- |          | 0x0000_0018
   -- |__________| 0x0000_001C
   -- |          | 0x0000_0020
   -- | Device 2 | 0x0000_0024
   -- |          | 0x0000_0028
   -- |__________| 0x0000_002C
   -- |          | 0x0000_0030
   -- | Device 3 | 0x0000_0034
   -- |          | 0x0000_0038
   -- |__________| 0x0000_003C
   -- |          | 0x0000_0040
   -- | Pas      |
   -- | Utilisé  |
   -- |          |
   -- |          |
   -- |__________| 0xFFFF_FFFC

----------------------------------------------------------------------------------------------
   Device_0_inst : Device_PCI
----------------------------------------------------------------------------------------------
   GENERIC MAP (
      GEN_BAR0 => X"00000000"
   )
   PORT MAP (
      -- Signaux systeme
      CLK_PCI =>  CLK_PCI,
      nRST    =>  IntReset,
      -- Signaux bus PCI
      AD      =>  AD,
      CnBE    =>  CnBE,
      PAR     =>  PAR,
      -- Signaux controle PCI (Maitre)
      IDSEL   =>  IDSEL(0),
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
   Device_1_inst : Device_PCI
----------------------------------------------------------------------------------------------
   GENERIC MAP (
      GEN_BAR0 => X"00000010"
   )
   PORT MAP (
      -- Signaux systeme
      CLK_PCI =>  CLK_PCI,
      nRST    =>  IntReset,
      -- Signaux bus PCI
      AD      =>  AD,
      CnBE    =>  CnBE,
      PAR     =>  PAR,
      -- Signaux controle PCI (Maitre)
      IDSEL   =>  IDSEL(1),
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
   Device_2_inst : Device_PCI
----------------------------------------------------------------------------------------------
   GENERIC MAP (
      GEN_BAR0 => X"00000020"
   )
   PORT MAP (
      -- Signaux systeme
      CLK_PCI =>  CLK_PCI,
      nRST    =>  IntReset,
      -- Signaux bus PCI
      AD      =>  AD,
      CnBE    =>  CnBE,
      PAR     =>  PAR,
      -- Signaux controle PCI (Maitre)
      IDSEL   =>  IDSEL(2),
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
   Device_3_inst : Device_PCI
----------------------------------------------------------------------------------------------
   GENERIC MAP (
      GEN_BAR0 => X"00000030"
   )
   PORT MAP (
      -- Signaux systeme
      CLK_PCI =>  CLK_PCI,
      nRST    =>  IntReset,
      -- Signaux bus PCI
      AD      =>  AD,
      CnBE    =>  CnBE,
      PAR     =>  PAR,
      -- Signaux controle PCI (Maitre)
      IDSEL   =>  IDSEL(3),
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

END ARCHITECTURE Behaviour;