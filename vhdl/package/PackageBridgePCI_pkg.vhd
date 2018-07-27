-- ===========================================================================================
-- | PACKAGE
-- ===========================================================================================
LIBRARY IEEE;
USE IEEE.STD_LOGIC_1164.all;
USE IEEE.NUMERIC_STD.ALL;

PACKAGE PackageBridgePCI IS

----------------------------------------------------------------------------------------------
-- | CONSTANTES TAILLE DES BUS
----------------------------------------------------------------------------------------------
   CONSTANT AddrSize       : integer := 32;
   CONSTANT DwordSize      : integer := 32;
   CONSTANT ByteEnSize     : integer := 4;
   CONSTANT CmdSize        : integer := 4;
   CONSTANT NbDeviceMax    : integer := 4;
   CONSTANT CntrDevSelSize : integer := 2;
   CONSTANT AddrProcSize   : integer := 4;
   CONSTANT DBusSize       : integer := 16;
   CONSTANT EndiannessSize : integer := 2;

----------------------------------------------------------------------------------------------
-- | TYPES DES ENTREES / SORTIES DU STYSTEME
----------------------------------------------------------------------------------------------
   SUBTYPE Def_Bit        IS std_logic ;
   SUBTYPE Def_Addr       IS std_logic_vector(AddrSize-1       DOWNTO 0);
   SUBTYPE Def_Dword      IS std_logic_vector(DwordSize-1      DOWNTO 0);
   SUBTYPE Def_Cmd        IS std_logic_vector(CmdSize-1        DOWNTO 0);
   SUBTYPE Def_ByteEn     IS std_logic_vector(ByteEnSize-1     DOWNTO 0);
   SUBTYPE Def_IDSel      IS std_logic_vector(NbDeviceMax-1    DOWNTO 0);
   SUBTYPE Def_CntrDevSel IS std_logic_vector(CntrDevSelSize-1 DOWNTO 0);
   SUBTYPE Def_AddrProc   IS std_logic_vector(AddrProcSize-1   DOWNTO 0);
   SUBTYPE Def_DBus       IS std_logic_vector(DBusSize-1       DOWNTO 0);
   SUBTYPE Def_Endianness IS std_logic_vector(EndiannessSize-1 DOWNTO 0);

----------------------------------------------------------------------------------------------
-- | TYPE REGISTRES INTERNES
----------------------------------------------------------------------------------------------
   TYPE Def_ProcToBridge IS RECORD
      Addr    : Def_Addr;
      Data    : Def_Dword;
      Cmd     : Def_Cmd;
      ByteEn  : Def_ByteEn;
   END RECORD Def_ProcToBridge;

----------------------------------------------------------------------------------------------
-- | TYPE DU STATUS
----------------------------------------------------------------------------------------------
   TYPE Def_Status IS RECORD
      TargetAbort : Def_Bit;
      MasterAbort : Def_Bit;
      ErrAddr     : Def_Bit;
      ErrDataIn   : Def_Bit;
      ErrDataOut  : Def_Bit;
      ErrSystem   : Def_Bit;
      Busy        : Def_Bit;
      WaitGrant   : Def_Bit;
      RxDone      : Def_Bit;
      TxDone      : Def_Bit;
   END RECORD Def_Status;

----------------------------------------------------------------------------------------------
-- | TYPES DE L'ADRESSE DE CONFIG SPACE
----------------------------------------------------------------------------------------------
   SUBTYPE Def_Word   IS std_logic_vector(15 downto 0);
   SUBTYPE Def_Byte   IS std_logic_vector(7 downto 0);
   SUBTYPE Def_3Bytes IS std_logic_vector(23 downto 0);
   SUBTYPE Def_BusNum IS std_logic_vector(23 downto 16);
   SUBTYPE Def_DevNum IS std_logic_vector(15 downto 11);
   SUBTYPE Def_FctNum IS std_logic_vector(10 downto 8);
   SUBTYPE Def_RegNum IS std_logic_vector(7 downto 2);
   SUBTYPE Def_HdType IS std_logic_vector(1 downto 0);
   SUBTYPE Def_Reserved IS std_logic_vector(30 downto 24);

----------------------------------------------------------------------------------------------
-- | ETAT DU SEQUENCER
----------------------------------------------------------------------------------------------
   TYPE Def_State IS ( Idle, ReadConfig_A, ReadConfig_D, ReadConfig_TA
                     , WriteConfig_A, WriteConfig_D, WriteConfig_TA
                     , ReadMem_A, ReadMem_D, ReadMem_TA
                     , WriteMem_A, WriteMem_D, WriteMem_TA );

----------------------------------------------------------------------------------------------
-- | ADRESSES DES REGISTRE DU BridgePCI
----------------------------------------------------------------------------------------------
   CONSTANT OFFSET_ADDR_0 : Def_AddrProc := X"0";
   CONSTANT OFFSET_ADDR_1 : Def_AddrProc := X"1";
   CONSTANT OFFSET_ADDR_2 : Def_AddrProc := X"2";
   CONSTANT OFFSET_ADDR_3 : Def_AddrProc := X"3";
   CONSTANT OFFSET_DATA_0 : Def_AddrProc := X"4";
   CONSTANT OFFSET_DATA_1 : Def_AddrProc := X"5";
   CONSTANT OFFSET_DATA_2 : Def_AddrProc := X"6";
   CONSTANT OFFSET_DATA_3 : Def_AddrProc := X"7";
   CONSTANT OFFSET_CTRL_0 : Def_AddrProc := X"8";
   CONSTANT OFFSET_CTRL_1 : Def_AddrProc := X"9";
   CONSTANT OFFSET_STAT_0 : Def_AddrProc := X"A";
   CONSTANT OFFSET_STAT_1 : Def_AddrProc := X"B";
   CONSTANT OFFSET_DREC_0 : Def_AddrProc := X"C";
   CONSTANT OFFSET_DREC_1 : Def_AddrProc := X"D";
   CONSTANT OFFSET_DREC_2 : Def_AddrProc := X"E";
   CONSTANT OFFSET_DREC_3 : Def_AddrProc := X"F";

----------------------------------------------------------------------------------------------
-- | CONSTANTES DES MODES DE TRANSFERT PCI
----------------------------------------------------------------------------------------------
   CONSTANT CMD_RD_MEM : std_logic_vector(CmdSize-1 downto 0) := "0110";
   CONSTANT CMD_WR_MEM : std_logic_vector(CmdSize-1 downto 0) := "0111";
   CONSTANT CMD_RD_CFG : std_logic_vector(CmdSize-1 downto 0) := "1010";
   CONSTANT CMD_WR_CFG : std_logic_vector(CmdSize-1 downto 0) := "1011";

----------------------------------------------------------------------------------------------
-- | CONSTANTES DES MODES ENDIAN DU PROCESSEUR
----------------------------------------------------------------------------------------------
   CONSTANT BIG_ENDIAN : std_logic_vector(EndiannessSize-1 downto 0) := "01";
   CONSTANT LIT_ENDIAN : std_logic_vector(EndiannessSize-1 downto 0) := "10";
   CONSTANT EIGHT_BITS : std_logic_vector(EndiannessSize-1 downto 0) := "00";

----------------------------------------------------------------------------------------------
-- | FONCTION xor_reduct()
-- | -> retourne le resultat d'un XOR sur l'ensemble des bits d'un vecteur
----------------------------------------------------------------------------------------------
   FUNCTION xor_reduct(slv : IN std_logic_vector) RETURN Def_Bit;

----------------------------------------------------------------------------------------------
-- | FONCTION GenIDSel()
-- | -> Convertion d'un numero de peripherique en Chip Select
----------------------------------------------------------------------------------------------
   FUNCTION GenIDSel(DevNum : IN Def_DevNum) RETURN Def_IDSel;

----------------------------------------------------------------------------------------------
-- | FONCTION GenCfgAddr()
-- | -> Convertion d'une adresse dans l'espace de configuration en Type0 ou Type1
----------------------------------------------------------------------------------------------
   FUNCTION GenCfgAddr(A : IN Def_Addr) RETURN Def_Addr;

----------------------------------------------------------------------------------------------
-- | FONCTION status_to_vector()
-- | -> Convertion le record Def_Status en std_logic_vector
----------------------------------------------------------------------------------------------
   FUNCTION status_to_vector(s : Def_Status) RETURN std_logic_vector;

----------------------------------------------------------------------------------------------
-- | CONSTANTES ENVIRONEMENT DE TEST
----------------------------------------------------------------------------------------------
   CONSTANT START    : std_logic := '1';
   CONSTANT ALL_BYTES_EN : std_logic_vector(3 downto 0) := "0000";

   -- Config Address Enable
   CONSTANT ENABLE : Def_Bit := '1';

   -- Bus Num
   CONSTANT RESERVED : Def_Reserved := std_logic_vector(to_unsigned(0,7));

   -- Bus Num
   CONSTANT BUS0 : Def_BusNum := std_logic_vector(to_unsigned(0,8));

   -- Dev Num
   CONSTANT DEV0 : Def_DevNum := std_logic_vector(to_unsigned(0,5));
   CONSTANT DEV1 : Def_DevNum := std_logic_vector(to_unsigned(1,5));
   CONSTANT DEV2 : Def_DevNum := std_logic_vector(to_unsigned(2,5));
   CONSTANT DEV3 : Def_DevNum := std_logic_vector(to_unsigned(3,5));

   -- Fct Num
   CONSTANT FCT0 : Def_FctNum := std_logic_vector(to_unsigned(0,3));
   CONSTANT FCT1 : Def_FctNum := std_logic_vector(to_unsigned(1,3));
   CONSTANT FCT2 : Def_FctNum := std_logic_vector(to_unsigned(2,3));
   CONSTANT FCT3 : Def_FctNum := std_logic_vector(to_unsigned(3,3));
   CONSTANT FCT4 : Def_FctNum := std_logic_vector(to_unsigned(4,3));
   CONSTANT FCT5 : Def_FctNum := std_logic_vector(to_unsigned(5,3));
   CONSTANT FCT6 : Def_FctNum := std_logic_vector(to_unsigned(6,3));
   CONSTANT FCT7 : Def_FctNum := std_logic_vector(to_unsigned(7,3));

   -- Reg Num
   CONSTANT CFG_REG0  : Def_RegNum := std_logic_vector(to_unsigned(0,6));
   CONSTANT CFG_REG1  : Def_RegNum := std_logic_vector(to_unsigned(1,6));
   CONSTANT CFG_REG2  : Def_RegNum := std_logic_vector(to_unsigned(2,6));
   CONSTANT CFG_REG3  : Def_RegNum := std_logic_vector(to_unsigned(3,6));
   CONSTANT CFG_REG4  : Def_RegNum := std_logic_vector(to_unsigned(4,6));
   CONSTANT CFG_REG5  : Def_RegNum := std_logic_vector(to_unsigned(5,6));
   CONSTANT CFG_REG6  : Def_RegNum := std_logic_vector(to_unsigned(6,6));
   CONSTANT CFG_REG7  : Def_RegNum := std_logic_vector(to_unsigned(7,6));
   CONSTANT CFG_REG8  : Def_RegNum := std_logic_vector(to_unsigned(8,6));
   CONSTANT CFG_REG9  : Def_RegNum := std_logic_vector(to_unsigned(9,6));
   CONSTANT CFG_REG10 : Def_RegNum := std_logic_vector(to_unsigned(10,6));
   CONSTANT CFG_REG11 : Def_RegNum := std_logic_vector(to_unsigned(11,6));
   CONSTANT CFG_REG12 : Def_RegNum := std_logic_vector(to_unsigned(12,6));
   CONSTANT CFG_REG13 : Def_RegNum := std_logic_vector(to_unsigned(13,6));
   CONSTANT CFG_REG14 : Def_RegNum := std_logic_vector(to_unsigned(14,6));
   CONSTANT CFG_REG15 : Def_RegNum := std_logic_vector(to_unsigned(15,6));
   CONSTANT CFG_REG16 : Def_RegNum := std_logic_vector(to_unsigned(16,6));
   CONSTANT CFG_REG17 : Def_RegNum := std_logic_vector(to_unsigned(17,6));
   CONSTANT CFG_REG18 : Def_RegNum := std_logic_vector(to_unsigned(18,6));
   CONSTANT CFG_REG19 : Def_RegNum := std_logic_vector(to_unsigned(19,6));
   CONSTANT CFG_REG20 : Def_RegNum := std_logic_vector(to_unsigned(20,6));
   CONSTANT CFG_REG21 : Def_RegNum := std_logic_vector(to_unsigned(21,6));
   CONSTANT CFG_REG22 : Def_RegNum := std_logic_vector(to_unsigned(22,6));
   CONSTANT CFG_REG23 : Def_RegNum := std_logic_vector(to_unsigned(23,6));
   CONSTANT CFG_REG24 : Def_RegNum := std_logic_vector(to_unsigned(24,6));
   CONSTANT CFG_REG25 : Def_RegNum := std_logic_vector(to_unsigned(25,6));
   CONSTANT CFG_REG26 : Def_RegNum := std_logic_vector(to_unsigned(26,6));
   CONSTANT CFG_REG27 : Def_RegNum := std_logic_vector(to_unsigned(27,6));
   CONSTANT CFG_REG28 : Def_RegNum := std_logic_vector(to_unsigned(28,6));
   CONSTANT CFG_REG29 : Def_RegNum := std_logic_vector(to_unsigned(29,6));
   CONSTANT CFG_REG30 : Def_RegNum := std_logic_vector(to_unsigned(30,6));
   CONSTANT CFG_REG31 : Def_RegNum := std_logic_vector(to_unsigned(31,6));
   CONSTANT CFG_REG32 : Def_RegNum := std_logic_vector(to_unsigned(32,6));
   CONSTANT CFG_REG33 : Def_RegNum := std_logic_vector(to_unsigned(33,6));
   CONSTANT CFG_REG34 : Def_RegNum := std_logic_vector(to_unsigned(34,6));
   CONSTANT CFG_REG35 : Def_RegNum := std_logic_vector(to_unsigned(35,6));
   CONSTANT CFG_REG36 : Def_RegNum := std_logic_vector(to_unsigned(36,6));
   CONSTANT CFG_REG37 : Def_RegNum := std_logic_vector(to_unsigned(37,6));
   CONSTANT CFG_REG38 : Def_RegNum := std_logic_vector(to_unsigned(38,6));
   CONSTANT CFG_REG39 : Def_RegNum := std_logic_vector(to_unsigned(39,6));
   CONSTANT CFG_REG40 : Def_RegNum := std_logic_vector(to_unsigned(40,6));
   CONSTANT CFG_REG41 : Def_RegNum := std_logic_vector(to_unsigned(41,6));
   CONSTANT CFG_REG42 : Def_RegNum := std_logic_vector(to_unsigned(42,6));
   CONSTANT CFG_REG43 : Def_RegNum := std_logic_vector(to_unsigned(43,6));
   CONSTANT CFG_REG44 : Def_RegNum := std_logic_vector(to_unsigned(44,6));
   CONSTANT CFG_REG45 : Def_RegNum := std_logic_vector(to_unsigned(45,6));
   CONSTANT CFG_REG46 : Def_RegNum := std_logic_vector(to_unsigned(46,6));
   CONSTANT CFG_REG47 : Def_RegNum := std_logic_vector(to_unsigned(47,6));
   CONSTANT CFG_REG48 : Def_RegNum := std_logic_vector(to_unsigned(48,6));
   CONSTANT CFG_REG49 : Def_RegNum := std_logic_vector(to_unsigned(49,6));
   CONSTANT CFG_REG50 : Def_RegNum := std_logic_vector(to_unsigned(50,6));
   CONSTANT CFG_REG51 : Def_RegNum := std_logic_vector(to_unsigned(51,6));
   CONSTANT CFG_REG52 : Def_RegNum := std_logic_vector(to_unsigned(52,6));
   CONSTANT CFG_REG53 : Def_RegNum := std_logic_vector(to_unsigned(53,6));
   CONSTANT CFG_REG54 : Def_RegNum := std_logic_vector(to_unsigned(54,6));
   CONSTANT CFG_REG55 : Def_RegNum := std_logic_vector(to_unsigned(55,6));
   CONSTANT CFG_REG56 : Def_RegNum := std_logic_vector(to_unsigned(56,6));
   CONSTANT CFG_REG57 : Def_RegNum := std_logic_vector(to_unsigned(57,6));
   CONSTANT CFG_REG58 : Def_RegNum := std_logic_vector(to_unsigned(58,6));
   CONSTANT CFG_REG59 : Def_RegNum := std_logic_vector(to_unsigned(59,6));
   CONSTANT CFG_REG60 : Def_RegNum := std_logic_vector(to_unsigned(60,6));
   CONSTANT CFG_REG61 : Def_RegNum := std_logic_vector(to_unsigned(61,6));
   CONSTANT CFG_REG62 : Def_RegNum := std_logic_vector(to_unsigned(62,6));
   CONSTANT CFG_REG63 : Def_RegNum := std_logic_vector(to_unsigned(63,6));

   -- Header Type
   CONSTANT TYPE0 : Def_HdType := std_logic_vector(to_unsigned(0,2));
   CONSTANT TYPE1 : Def_HdType := std_logic_vector(to_unsigned(1,2));

END PackageBridgePCI;

-- ===========================================================================================
-- | PACKAGE BODY
-- ===========================================================================================
LIBRARY IEEE;
USE IEEE.STD_LOGIC_1164.all;
USE IEEE.NUMERIC_STD.ALL;

PACKAGE BODY PackageBridgePCI IS

----------------------------------------------------------------------------------------------
-- | FONCTION xor_reduct()
-- | -> retourne le resultat d'un XOR sur l'ensemble des bits d'un vecteur
----------------------------------------------------------------------------------------------
   FUNCTION xor_reduct(slv : IN std_logic_vector) RETURN Def_Bit IS
      VARIABLE res_v : Def_Bit := '0';
   BEGIN
      FOR i IN slv'RANGE LOOP
         res_v := res_v XOR slv(i);
      END LOOP;
      RETURN res_v;
   END FUNCTION;
    
----------------------------------------------------------------------------------------------
-- | FONCTION GenIDSel()
-- | -> Convertion d'un numero de peripherique en Chip Select
----------------------------------------------------------------------------------------------
   FUNCTION GenIDSel(DevNum : IN Def_DevNum) RETURN Def_IDSel IS
      VARIABLE res_v : Def_IDSel := "0000";
   BEGIN
      CASE DevNum IS
      WHEN "00000" => res_v := "0001";
      WHEN "00001" => res_v := "0010";
      WHEN "00010" => res_v := "0100";
      WHEN "00011" => res_v := "1000";
      WHEN OTHERS  => res_v := "0000";
      END CASE;
      RETURN res_v;
   END FUNCTION;

----------------------------------------------------------------------------------------------
-- | FONCTION GenCfgAddr()
-- | -> Convertion d'une adresse dans l'espace de configuration en Type0 ou Type1
----------------------------------------------------------------------------------------------
   FUNCTION GenCfgAddr(A : IN Def_Addr) RETURN Def_Addr IS
      VARIABLE res_v : Def_Addr := (OTHERS=>'0');
   BEGIN
      -- Destinataire sur le bus0 donc on transmet l'adresse avec le format Type0
      IF  A(31)=ENABLE AND A(23 downto 16)=BUS0 AND A(1 downto 0)=TYPE0 THEN
         res_v(31 downto 11) := (OTHERS=>'1');
         res_v(10 downto 2)  := A(10 downto 2);
         res_v(1 downto 0)   := TYPE0;
      -- Le destinataire est sur un bus different du bus0 donc on transmet l'adresse
      -- avec le format Type1
      ELSIF A(31)=ENABLE AND A(23 downto 16)=BUS0 AND A(1 downto 0)=TYPE1 THEN
         res_v(31)          := ENABLE;
         res_v(30 downto 2) := A(30 downto 2);
         res_v(1 downto 0)  := TYPE1;
      END IF;
      RETURN res_v;
   END FUNCTION;

----------------------------------------------------------------------------------------------
-- | FONCTION status_to_vector()
-- | -> Convertion le record Def_Status en std_logic_vector
----------------------------------------------------------------------------------------------
   FUNCTION status_to_vector(s : Def_Status) RETURN std_logic_vector IS
      VARIABLE res_v : std_logic_vector(9 downto 0);
   BEGIN
        res_v(9) := s.TargetAbort ;
        res_v(8) := s.MasterAbort ;
        res_v(7) := s.ErrAddr ;
        res_v(6) := s.ErrDataIn ;
        res_v(5) := s.ErrDataOut ;
        res_v(4) := s.ErrSystem ;
        res_v(3) := s.Busy ;
        res_v(2) := s.WaitGrant ;
        res_v(1) := s.RxDone ;
        res_v(0) := s.TxDone ;
        RETURN res_v;
   END FUNCTION status_to_vector; 

END PackageBridgePCI;
