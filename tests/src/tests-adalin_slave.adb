--  Tests for Adalin.Slave state machine and l_ifc_rx.

with AUnit.Assertions; use AUnit.Assertions;
with Adalin;           use Adalin;
with Adalin.Signals;   use Adalin.Signals;
with Adalin.Slave;
with Interfaces;       use Interfaces;

package body Tests.Adalin_Slave is

   package My_Slave is new Adalin.Slave (Capacity => 3);
   use My_Slave;

   --  Named array type for test data (anonymous arrays not allowed as params).
   type Byte_Array is array (Natural range <>) of Unsigned_8;

   ---------------------------------------------------------------------------
   --  Helpers
   ---------------------------------------------------------------------------

   function Make_PID (FID : Unsigned_8) return Unsigned_8 is
      function Bit (N : Natural) return Boolean is
        ((Shift_Right (FID, N) and 1) /= 0);
      P0 : constant Boolean :=
        Bit (0) xor Bit (1) xor Bit (2) xor Bit (4);
      P1 : constant Boolean :=
        not (Bit (1) xor Bit (3) xor Bit (4) xor Bit (5));
   begin
      return (FID and 16#3F#)
             or (if P0 then 16#40# else 0)
             or (if P1 then 16#80# else 0);
   end Make_PID;

   function Make_Checksum
     (PID  : Unsigned_8;
      Data : Byte_Array) return Unsigned_8
   is
      FID : constant Unsigned_8 := PID and 16#3F#;
      Sum : Natural :=
        (if FID /= 16#3C# and then FID /= 16#3D#
         then Natural (PID) else 0);
   begin
      for B of Data loop
         Sum := Sum + Natural (B);
         if Sum >= 256 then
            Sum := Sum - 255;
         end if;
      end loop;
      return not Unsigned_8 (Sum mod 256);
   end Make_Checksum;

   procedure Feed_Frame
     (Node : in out My_Slave.Slave_Node;
      PID  : Unsigned_8;
      Data : Byte_Array)
   is
   begin
      My_Slave.l_ifc_rx (Node, 16#55#);
      My_Slave.l_ifc_rx (Node, PID);
      for B of Data loop
         My_Slave.l_ifc_rx (Node, B);
      end loop;
      My_Slave.l_ifc_rx (Node, Make_Checksum (PID, Data));
   end Feed_Frame;

   procedure Feed_Publish_Frame
     (Node      : in out My_Slave.Slave_Node;
      PID       : Unsigned_8;
      Num_Bytes : Positive)
   is
      Dummy : constant Byte_Array (0 .. Num_Bytes - 1) := [others => 0];
   begin
      My_Slave.l_ifc_rx (Node, 16#55#);
      My_Slave.l_ifc_rx (Node, PID);
      for I in 0 .. Num_Bytes - 1 loop
         My_Slave.l_ifc_rx (Node, 0);
      end loop;
      My_Slave.l_ifc_rx (Node, Make_Checksum (PID, Dummy));
   end Feed_Publish_Frame;

   --  Return a space-padded 64-char signal name.
   function Pad (S : String) return U8_Signal.Signal_Name is
      Result : U8_Signal.Signal_Name := [others => ' '];
   begin
      Result (1 .. S'Length) := S;
      return Result;
   end Pad;

   --  Same padding for U16 and Arr signals (same Signal_Name subtype).
   function Pad16 (S : String) return U16_Signal.Signal_Name is
      Result : U16_Signal.Signal_Name := [others => ' '];
   begin
      Result (1 .. S'Length) := S;
      return Result;
   end Pad16;

   function PadArr (S : String) return Arr_Signal.Signal_Name is
      Result : Arr_Signal.Signal_Name := [others => ' '];
   begin
      Result (1 .. S'Length) := S;
      return Result;
   end PadArr;

   ---------------------------------------------------------------------------
   --  Register_Tests / Name
   ---------------------------------------------------------------------------

   overriding procedure Register_Tests (T : in out Test) is
      use Registration;
   begin
      Register_Routine (T, Test_Register_And_Count'Unchecked_Access,
        "Register: count increments correctly");
      Register_Routine (T, Test_Is_Ready'Unchecked_Access,
        "Is_Ready: true when capacity reached");
      Register_Routine (T, Test_Get_Entry_Found'Unchecked_Access,
        "Get_Entry: returns entry for registered PID");
      Register_Routine (T, Test_Get_Entry_Not_Found'Unchecked_Access,
        "Get_Entry: returns null for unknown PID");
      Register_Routine (T, Test_Register_Overflow'Unchecked_Access,
        "Register: raises Constraint_Error when full");
      Register_Routine (T, Test_Initial_State_Is_Idle'Unchecked_Access,
        "Initial state is Idle");
      Register_Routine (T, Test_Non_Sync_Byte_Ignored'Unchecked_Access,
        "Non-sync byte in Idle is discarded");
      Register_Routine (T, Test_Sync_Byte_Advances'Unchecked_Access,
        "Sync byte 0x55 advances to Recv_Sync");
      Register_Routine (T, Test_Unknown_PID_Returns_Idle'Unchecked_Access,
        "Unregistered PID returns to Idle");
      Register_Routine (T, Test_Bad_Parity_Returns_Idle'Unchecked_Access,
        "PID with bad parity returns to Idle");
      Register_Routine (T, Test_Subscribe_PID_Recv_Data'Unchecked_Access,
        "Valid subscribe PID advances to Recv_Data");
      Register_Routine (T, Test_Publish_PID_Tx_Data'Unchecked_Access,
        "Valid publish PID advances to Tx_Data");
      Register_Routine (T, Test_Subscribe_U8_Full_Frame'Unchecked_Access,
        "Full subscribe frame: U8 value committed");
      Register_Routine (T, Test_Subscribe_U16_Full_Frame'Unchecked_Access,
        "Full subscribe frame: U16 little-endian decode");
      Register_Routine (T, Test_Subscribe_Arr_Full_Frame'Unchecked_Access,
        "Full subscribe frame: byte-array value committed");
      Register_Routine (T, Test_Bad_Checksum_No_Commit'Unchecked_Access,
        "Bad checksum: value not committed");
      Register_Routine (T, Test_Publish_Full_Frame'Unchecked_Access,
        "Full publish frame: Tx_Data -> Idle, value unchanged");
      Register_Routine (T, Test_Returns_To_Idle_After_Frame'Unchecked_Access,
        "State returns to Idle after complete frame");
      Register_Routine (T, Test_Two_Frames_In_Sequence'Unchecked_Access,
        "Two consecutive frames committed correctly");
   end Register_Tests;

   overriding function Name (T : Test) return Message_String is
   begin
      return Format ("adaLIN Slave State Machine Tests");
   end Name;

   ---------------------------------------------------------------------------
   --  Registration / query tests
   ---------------------------------------------------------------------------

   procedure Test_Register_And_Count (T : in out Test_Case'Class) is
      pragma Unreferenced (T);
      Node : My_Slave.Slave_Node;
      E1   : aliased U8_Signal_Entry :=
        (PID => Make_PID (16#01#),
         Sig => U8_Signal.Make (0, Pad ("s1"), 0, 8));
      E2   : aliased U16_Signal_Entry :=
        (PID => Make_PID (16#02#),
         Sig => U16_Signal.Make (1, Pad16 ("s2"), 0, 16));
   begin
      Assert (My_Slave.Registered_Count (Node) = 0, "count should be 0");
      My_Slave.Register (Node, E1.PID, E1'Unchecked_Access, My_Slave.Subscribe, 1);
      Assert (My_Slave.Registered_Count (Node) = 1, "count should be 1");
      My_Slave.Register (Node, E2.PID, E2'Unchecked_Access, My_Slave.Subscribe, 2);
      Assert (My_Slave.Registered_Count (Node) = 2, "count should be 2");
   end Test_Register_And_Count;

   procedure Test_Is_Ready (T : in out Test_Case'Class) is
      pragma Unreferenced (T);
      Node : My_Slave.Slave_Node;
      E1   : aliased U8_Signal_Entry :=
        (PID => Make_PID (16#01#),
         Sig => U8_Signal.Make (0, Pad ("s1"), 0, 8));
      E2   : aliased U8_Signal_Entry :=
        (PID => Make_PID (16#02#),
         Sig => U8_Signal.Make (1, Pad ("s2"), 0, 8));
      E3   : aliased U8_Signal_Entry :=
        (PID => Make_PID (16#03#),
         Sig => U8_Signal.Make (2, Pad ("s3"), 0, 8));
   begin
      Assert (not My_Slave.Is_Ready (Node), "not ready at 0/3");
      My_Slave.Register (Node, E1.PID, E1'Unchecked_Access, My_Slave.Subscribe, 1);
      My_Slave.Register (Node, E2.PID, E2'Unchecked_Access, My_Slave.Subscribe, 1);
      Assert (not My_Slave.Is_Ready (Node), "not ready at 2/3");
      My_Slave.Register (Node, E3.PID, E3'Unchecked_Access, My_Slave.Subscribe, 1);
      Assert (My_Slave.Is_Ready (Node), "ready at 3/3");
   end Test_Is_Ready;

   procedure Test_Get_Entry_Found (T : in out Test_Case'Class) is
      pragma Unreferenced (T);
      Node : My_Slave.Slave_Node;
      PID  : constant Unsigned_8 := Make_PID (16#05#);
      E    : aliased U8_Signal_Entry :=
        (PID => PID, Sig => U8_Signal.Make (0, Pad ("s5"), 0, 8));
   begin
      My_Slave.Register (Node, PID, E'Unchecked_Access, My_Slave.Subscribe, 1);
      Assert (My_Slave.Get_Entry (Node, PID) = E'Unchecked_Access,
              "Get_Entry should return the registered access value");
   end Test_Get_Entry_Found;

   procedure Test_Get_Entry_Not_Found (T : in out Test_Case'Class) is
      pragma Unreferenced (T);
      Node : My_Slave.Slave_Node;
   begin
      Assert (My_Slave.Get_Entry (Node, 16#AA#) = null,
              "Get_Entry should return null for unknown PID");
   end Test_Get_Entry_Not_Found;

   procedure Test_Register_Overflow (T : in out Test_Case'Class) is
      pragma Unreferenced (T);
      Node   : My_Slave.Slave_Node;
      E1     : aliased U8_Signal_Entry :=
        (PID => Make_PID (16#01#),
         Sig => U8_Signal.Make (0, Pad ("s1"), 0, 8));
      E2     : aliased U8_Signal_Entry :=
        (PID => Make_PID (16#02#),
         Sig => U8_Signal.Make (1, Pad ("s2"), 0, 8));
      E3     : aliased U8_Signal_Entry :=
        (PID => Make_PID (16#03#),
         Sig => U8_Signal.Make (2, Pad ("s3"), 0, 8));
      E4     : aliased U8_Signal_Entry :=
        (PID => Make_PID (16#04#),
         Sig => U8_Signal.Make (3, Pad ("s4"), 0, 8));
      Raised : Boolean := False;
   begin
      My_Slave.Register (Node, E1.PID, E1'Unchecked_Access, My_Slave.Subscribe, 1);
      My_Slave.Register (Node, E2.PID, E2'Unchecked_Access, My_Slave.Subscribe, 1);
      My_Slave.Register (Node, E3.PID, E3'Unchecked_Access, My_Slave.Subscribe, 1);
      begin
         My_Slave.Register
           (Node, E4.PID, E4'Unchecked_Access, My_Slave.Subscribe, 1);
      exception
         when Constraint_Error => Raised := True;
      end;
      Assert (Raised, "Constraint_Error expected when map is full");
   end Test_Register_Overflow;

   ---------------------------------------------------------------------------
   --  State machine - initial state and sync detection
   ---------------------------------------------------------------------------

   procedure Test_Initial_State_Is_Idle (T : in out Test_Case'Class) is
      pragma Unreferenced (T);
      Node : My_Slave.Slave_Node;
   begin
      Assert (My_Slave.Current_State (Node) = My_Slave.Idle,
              "initial state should be Idle");
   end Test_Initial_State_Is_Idle;

   procedure Test_Non_Sync_Byte_Ignored (T : in out Test_Case'Class) is
      pragma Unreferenced (T);
      Node : My_Slave.Slave_Node;
   begin
      My_Slave.l_ifc_rx (Node, 16#00#);
      Assert (My_Slave.Current_State (Node) = My_Slave.Idle,
              "0x00 should stay Idle");
      My_Slave.l_ifc_rx (Node, 16#AA#);
      Assert (My_Slave.Current_State (Node) = My_Slave.Idle,
              "0xAA should stay Idle");
      My_Slave.l_ifc_rx (Node, 16#FF#);
      Assert (My_Slave.Current_State (Node) = My_Slave.Idle,
              "0xFF should stay Idle");
   end Test_Non_Sync_Byte_Ignored;

   procedure Test_Sync_Byte_Advances (T : in out Test_Case'Class) is
      pragma Unreferenced (T);
      Node : My_Slave.Slave_Node;
   begin
      My_Slave.l_ifc_rx (Node, 16#55#);
      Assert (My_Slave.Current_State (Node) = My_Slave.Recv_Sync,
              "0x55 should advance to Recv_Sync");
   end Test_Sync_Byte_Advances;

   ---------------------------------------------------------------------------
   --  State machine - PID handling
   ---------------------------------------------------------------------------

   procedure Test_Unknown_PID_Returns_Idle (T : in out Test_Case'Class) is
      pragma Unreferenced (T);
      Node : My_Slave.Slave_Node;
      PID  : constant Unsigned_8 := Make_PID (16#10#);
   begin
      My_Slave.l_ifc_rx (Node, 16#55#);
      My_Slave.l_ifc_rx (Node, PID);
      Assert (My_Slave.Current_State (Node) = My_Slave.Idle,
              "unregistered PID should return to Idle");
   end Test_Unknown_PID_Returns_Idle;

   procedure Test_Bad_Parity_Returns_Idle (T : in out Test_Case'Class) is
      pragma Unreferenced (T);
      Node    : My_Slave.Slave_Node;
      PID     : constant Unsigned_8 := Make_PID (16#01#);
      Bad_PID : constant Unsigned_8 := PID xor 16#40#;
      E       : aliased U8_Signal_Entry :=
        (PID => PID, Sig => U8_Signal.Make (0, Pad ("s1"), 0, 8));
   begin
      My_Slave.Register (Node, PID, E'Unchecked_Access, My_Slave.Subscribe, 1);
      My_Slave.l_ifc_rx (Node, 16#55#);
      My_Slave.l_ifc_rx (Node, Bad_PID);
      Assert (My_Slave.Current_State (Node) = My_Slave.Idle,
              "corrupted parity should return to Idle");
   end Test_Bad_Parity_Returns_Idle;

   procedure Test_Subscribe_PID_Recv_Data (T : in out Test_Case'Class) is
      pragma Unreferenced (T);
      Node : My_Slave.Slave_Node;
      PID  : constant Unsigned_8 := Make_PID (16#01#);
      E    : aliased U8_Signal_Entry :=
        (PID => PID, Sig => U8_Signal.Make (0, Pad ("s1"), 0, 8));
   begin
      My_Slave.Register (Node, PID, E'Unchecked_Access, My_Slave.Subscribe, 1);
      My_Slave.l_ifc_rx (Node, 16#55#);
      My_Slave.l_ifc_rx (Node, PID);
      Assert (My_Slave.Current_State (Node) = My_Slave.Recv_Data,
              "subscribe PID should advance to Recv_Data");
   end Test_Subscribe_PID_Recv_Data;

   procedure Test_Publish_PID_Tx_Data (T : in out Test_Case'Class) is
      pragma Unreferenced (T);
      Node : My_Slave.Slave_Node;
      PID  : constant Unsigned_8 := Make_PID (16#02#);
      E    : aliased U8_Signal_Entry :=
        (PID => PID, Sig => U8_Signal.Make (0, Pad ("s2"), 0, 8));
   begin
      My_Slave.Register (Node, PID, E'Unchecked_Access, My_Slave.Publish, 1);
      My_Slave.l_ifc_rx (Node, 16#55#);
      My_Slave.l_ifc_rx (Node, PID);
      Assert (My_Slave.Current_State (Node) = My_Slave.Tx_Data,
              "publish PID should advance to Tx_Data");
   end Test_Publish_PID_Tx_Data;

   ---------------------------------------------------------------------------
   --  Full subscribe frames
   ---------------------------------------------------------------------------

   procedure Test_Subscribe_U8_Full_Frame (T : in out Test_Case'Class) is
      pragma Unreferenced (T);
      Node : My_Slave.Slave_Node;
      PID  : constant Unsigned_8 := Make_PID (16#01#);
      E    : aliased U8_Signal_Entry :=
        (PID => PID,
         Sig => U8_Signal.Make (0, Pad ("speed"), 0, 8));
      Data : constant Byte_Array (0 .. 0) := [42];
   begin
      My_Slave.Register (Node, PID, E'Unchecked_Access, My_Slave.Subscribe, 1);
      Feed_Frame (Node, PID, Data);
      Assert (My_Slave.Current_State (Node) = My_Slave.Idle,
              "state should be Idle after complete frame");
      Assert (Get_Value (E) = 42, "U8 value should be 42");
      Assert (E.Is_Updated, "Is_Updated should be True after receive");
   end Test_Subscribe_U8_Full_Frame;

   procedure Test_Subscribe_U16_Full_Frame (T : in out Test_Case'Class) is
      pragma Unreferenced (T);
      --  0x1234 little-endian: byte0 = 0x34, byte1 = 0x12
      Node : My_Slave.Slave_Node;
      PID  : constant Unsigned_8 := Make_PID (16#02#);
      E    : aliased U16_Signal_Entry :=
        (PID => PID,
         Sig => U16_Signal.Make (0, Pad16 ("volt"), 0, 16));
      Data : constant Byte_Array (0 .. 1) := [16#34#, 16#12#];
   begin
      My_Slave.Register (Node, PID, E'Unchecked_Access, My_Slave.Subscribe, 2);
      Feed_Frame (Node, PID, Data);
      Assert (Get_Value (E) = 16#1234#,
              "U16 should be 0x1234 after little-endian decode");
   end Test_Subscribe_U16_Full_Frame;

   procedure Test_Subscribe_Arr_Full_Frame (T : in out Test_Case'Class) is
      pragma Unreferenced (T);
      Node : My_Slave.Slave_Node;
      PID  : constant Unsigned_8 := Make_PID (16#03#);
      E    : aliased Arr_Signal_Entry :=
        (PID => PID,
         Sig => Arr_Signal.Make
           (0, PadArr ("sens"), [others => 0], 4));
      Data : constant Byte_Array (0 .. 3) := [1, 2, 3, 4];
   begin
      My_Slave.Register (Node, PID, E'Unchecked_Access, My_Slave.Subscribe, 4);
      Feed_Frame (Node, PID, Data);
      declare
         V : constant l_byte_array := Get_Value (E);
      begin
         Assert (V (0) = 1 and then V (1) = 2
                 and then V (2) = 3 and then V (3) = 4,
                 "byte array should be [1,2,3,4]");
      end;
   end Test_Subscribe_Arr_Full_Frame;

   ---------------------------------------------------------------------------
   --  Checksum rejection
   ---------------------------------------------------------------------------

   procedure Test_Bad_Checksum_No_Commit (T : in out Test_Case'Class) is
      pragma Unreferenced (T);
      Node : My_Slave.Slave_Node;
      PID  : constant Unsigned_8 := Make_PID (16#01#);
      E    : aliased U8_Signal_Entry :=
        (PID => PID, Sig => U8_Signal.Make (0, Pad ("spd"), 0, 8));
   begin
      My_Slave.Register (Node, PID, E'Unchecked_Access, My_Slave.Subscribe, 1);
      My_Slave.l_ifc_rx (Node, 16#55#);
      My_Slave.l_ifc_rx (Node, PID);
      My_Slave.l_ifc_rx (Node, 99);       --  data byte
      My_Slave.l_ifc_rx (Node, 16#00#);   --  wrong checksum
      Assert (My_Slave.Current_State (Node) = My_Slave.Idle,
              "should return to Idle after bad checksum");
      Assert (Get_Value (E) = 0,
              "value must not be committed on bad checksum");
      Assert (not E.Is_Updated,
              "Is_Updated must stay False on bad checksum");
   end Test_Bad_Checksum_No_Commit;

   ---------------------------------------------------------------------------
   --  Publish frame
   ---------------------------------------------------------------------------

   procedure Test_Publish_Full_Frame (T : in out Test_Case'Class) is
      pragma Unreferenced (T);
      Node : My_Slave.Slave_Node;
      PID  : constant Unsigned_8 := Make_PID (16#04#);
      E    : aliased U8_Signal_Entry :=
        (PID => PID, Sig => U8_Signal.Make (0, Pad ("cmd"), 77, 8));
   begin
      My_Slave.Register (Node, PID, E'Unchecked_Access, My_Slave.Publish, 1);
      Feed_Publish_Frame (Node, PID, 1);
      Assert (My_Slave.Current_State (Node) = My_Slave.Idle,
              "state should be Idle after publish frame");
      Assert (Get_Value (E) = 77,
              "publish frame must not overwrite the signal value");
   end Test_Publish_Full_Frame;

   ---------------------------------------------------------------------------
   --  State reset and sequencing
   ---------------------------------------------------------------------------

   procedure Test_Returns_To_Idle_After_Frame (T : in out Test_Case'Class) is
      pragma Unreferenced (T);
      Node : My_Slave.Slave_Node;
      PID  : constant Unsigned_8 := Make_PID (16#05#);
      E    : aliased U8_Signal_Entry :=
        (PID => PID, Sig => U8_Signal.Make (0, Pad ("x"), 0, 8));
      Data : constant Byte_Array (0 .. 0) := [10];
   begin
      My_Slave.Register (Node, PID, E'Unchecked_Access, My_Slave.Subscribe, 1);
      Feed_Frame (Node, PID, Data);
      Assert (My_Slave.Current_State (Node) = My_Slave.Idle,
              "state must be Idle after frame completes");
   end Test_Returns_To_Idle_After_Frame;

   procedure Test_Two_Frames_In_Sequence (T : in out Test_Case'Class) is
      pragma Unreferenced (T);
      Node : My_Slave.Slave_Node;
      PID1 : constant Unsigned_8 := Make_PID (16#01#);
      PID2 : constant Unsigned_8 := Make_PID (16#02#);
      E1   : aliased U8_Signal_Entry :=
        (PID => PID1, Sig => U8_Signal.Make (0, Pad ("a"), 0, 8));
      E2   : aliased U8_Signal_Entry :=
        (PID => PID2, Sig => U8_Signal.Make (1, Pad ("b"), 0, 8));
      D1   : constant Byte_Array (0 .. 0) := [11];
      D2   : constant Byte_Array (0 .. 0) := [22];
   begin
      My_Slave.Register (Node, PID1, E1'Unchecked_Access, My_Slave.Subscribe, 1);
      My_Slave.Register (Node, PID2, E2'Unchecked_Access, My_Slave.Subscribe, 1);
      Feed_Frame (Node, PID1, D1);
      Feed_Frame (Node, PID2, D2);
      Assert (Get_Value (E1) = 11, "E1 should hold 11");
      Assert (Get_Value (E2) = 22, "E2 should hold 22");
      Assert (My_Slave.Current_State (Node) = My_Slave.Idle,
              "state should be Idle after both frames");
   end Test_Two_Frames_In_Sequence;

end Tests.Adalin_Slave;