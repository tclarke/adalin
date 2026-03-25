--  Unit tests for Adalin.Signal (generic ADT).
--
--  Four instantiations are exercised, one per allowed LIN signal type:
--    Bool_Signals, U8_Signals, U16_Signals, Array_Signals.
--
--  Every public subprogram (Make, Get_Handle, Get_Name, Get_Value, Get_Size,
--  Is_Updated, Set_Value, Clear_Updated) is covered for each instantiation.
--  Masking behaviour is verified for each scalar and array type.

with AUnit.Assertions; use AUnit.Assertions;
with Adalin; use Adalin;
with Adalin.Signal;

package body Tests.Adalin_Signal is

   --  -----------------------------------------------------------------------
   --  Mask_Bits actuals (scalar signal instantiations)
   --  -----------------------------------------------------------------------

   --  l_bool is always 1 bit; the value is its own mask.
   function Bool_Mask (V : l_bool; Bits : Positive) return l_bool is
      pragma Unreferenced (Bits);
   begin
      return V;
   end Bool_Mask;

   --  Keep only the lowest Bits bits of a l_u8 value.
   function U8_Mask (V : l_u8; Bits : Positive) return l_u8 is
      Modulus : constant Natural := 2 ** Bits;
   begin
      if Modulus > Natural (l_u8'Last) + 1 then
         return V;
      end if;
      return l_u8 (Natural (V) mod Modulus);
   end U8_Mask;

   --  Keep only the lowest Bits bits of a l_u16 value.
   function U16_Mask (V : l_u16; Bits : Positive) return l_u16 is
      Modulus : constant Natural := 2 ** Bits;
   begin
      if Modulus > Natural (l_u16'Last) + 1 then
         return V;
      end if;
      return l_u16 (Natural (V) mod Modulus);
   end U16_Mask;

   --  -----------------------------------------------------------------------
   --  Trim_Bytes actual (array signal instantiation)
   --  -----------------------------------------------------------------------

   --  Keep the first Bytes elements; zero out elements at index >= Bytes.
   function Array_Trim
     (V : l_byte_array; Bytes : Positive) return l_byte_array
   is
      Result : l_byte_array := V;
   begin
      for I in l_array_index loop
         if Natural (I) >= Bytes then
            Result (I) := 0;
         end if;
      end loop;
      return Result;
   end Array_Trim;

   --  -----------------------------------------------------------------------
   --  Identity stubs – passed as the unused formal in each instantiation
   --  -----------------------------------------------------------------------

   function Bool_Identity (V : l_bool; N : Positive) return l_bool is
      pragma Unreferenced (N);
   begin
      return V;
   end Bool_Identity;

   function U8_Identity (V : l_u8; N : Positive) return l_u8 is
      pragma Unreferenced (N);
   begin
      return V;
   end U8_Identity;

   function U16_Identity (V : l_u16; N : Positive) return l_u16 is
      pragma Unreferenced (N);
   begin
      return V;
   end U16_Identity;

   function Array_Identity (V : l_byte_array; N : Positive) return l_byte_array
   is
      pragma Unreferenced (N);
   begin
      return V;
   end Array_Identity;

   --  -----------------------------------------------------------------------
   --  Instantiations under test
   --  -----------------------------------------------------------------------

   package Bool_Signals is new Adalin.Signal
     (Value_Type    => l_bool,
      Is_Array_Type => False,
      Mask_Bits     => Bool_Mask,
      Trim_Bytes    => Bool_Identity);

   package U8_Signals is new Adalin.Signal
     (Value_Type    => l_u8,
      Is_Array_Type => False,
      Mask_Bits     => U8_Mask,
      Trim_Bytes    => U8_Identity);

   package U16_Signals is new Adalin.Signal
     (Value_Type    => l_u16,
      Is_Array_Type => False,
      Mask_Bits     => U16_Mask,
      Trim_Bytes    => U16_Identity);

   package Array_Signals is new Adalin.Signal
     (Value_Type    => l_byte_array,
      Is_Array_Type => True,
      Mask_Bits     => Array_Identity,
      Trim_Bytes    => Array_Trim);

   --  -----------------------------------------------------------------------
   --  Helpers
   --  -----------------------------------------------------------------------

   --  Build a 64-character signal name from a short string literal.
   function Pad (S : String) return Bool_Signals.Signal_Name is
      Result : Bool_Signals.Signal_Name := [others => ' '];
   begin
      Result (1 .. S'Length) := S;
      return Result;
   end Pad;

   --  -----------------------------------------------------------------------
   --  Registration
   --  -----------------------------------------------------------------------

   overriding
   procedure Register_Tests (T : in out Test) is
      use Registration;
   begin
      Register_Routine (T, Test_Make_Bool'Access,
                        "Make: Bool signal initial state");
      Register_Routine (T, Test_Make_U8'Access,
                        "Make: U8 signal initial state");
      Register_Routine (T, Test_Make_U16'Access,
                        "Make: U16 signal initial state");
      Register_Routine (T, Test_Make_Byte_Array'Access,
                        "Make: Byte-array signal initial state");

      Register_Routine (T, Test_Set_Value_Bool'Access,
                        "Set_Value: Bool stored and flag raised");
      Register_Routine (T, Test_Set_Value_U8'Access,
                        "Set_Value: U8 stored and flag raised");
      Register_Routine (T, Test_Set_Value_U16'Access,
                        "Set_Value: U16 stored and flag raised");
      Register_Routine (T, Test_Set_Value_Byte_Array'Access,
                        "Set_Value: Byte-array stored and flag raised");

      Register_Routine (T, Test_Mask_U8'Access,
                        "Set_Value: U8 masked to declared bit size");
      Register_Routine (T, Test_Mask_U16'Access,
                        "Set_Value: U16 masked to declared bit size");
      Register_Routine (T, Test_Mask_Byte_Array'Access,
                        "Set_Value: byte-array trimmed to declared size");
      Register_Routine (T, Test_Mask_Default_Value'Access,
                        "Make: default value masked to declared bit size");

      Register_Routine (T, Test_Clear_Updated_Bool'Access,
                        "Clear_Updated: Bool flag cleared, state preserved");
      Register_Routine (T, Test_Clear_Updated_U8'Access,
                        "Clear_Updated: U8 flag cleared, state preserved");
      Register_Routine (T, Test_Clear_Updated_U16'Access,
                        "Clear_Updated: U16 flag cleared, state preserved");
      Register_Routine (T, Test_Clear_Updated_Byte_Array'Access,
                        "Clear_Updated: array flag cleared, state preserved");

      Register_Routine (T, Test_Overwrite_Value'Access,
                        "Set_Value twice: latest value wins, flag stays set");
      Register_Routine (T, Test_Round_Trip'Access,
                        "Round-trip: set, clear, set again");
   end Register_Tests;

   overriding
   function Name (T : Test) return Message_String is
   begin
      return Format ("adaLIN Signal ADT Tests");
   end Name;

   --  -----------------------------------------------------------------------
   --  Make tests – verify constructor post-conditions for every type
   --  -----------------------------------------------------------------------

   procedure Test_Make_Bool (T : in out Test_Case'Class) is
      pragma Unreferenced (T);
      N : constant Bool_Signals.Signal_Name := Pad ("EngineRunning");
      S : constant Bool_Signals.Signal :=
            Bool_Signals.Make
              (Handle        => 1,
               Name          => N,
               Default_Value => False,
               Size          => 1);
   begin
      Assert (Bool_Signals.Get_Handle (S) = 1,
              "Make_Bool: wrong handle");
      Assert (Bool_Signals.Get_Name (S) = N,
              "Make_Bool: wrong name");
      Assert (Bool_Signals.Get_Size (S) = 1,
              "Make_Bool: wrong size");
      Assert (not Bool_Signals.Get_Value (S),
              "Make_Bool: default value should be False");
      Assert (not Bool_Signals.Is_Updated (S),
              "Make_Bool: updated flag should be clear");
   end Test_Make_Bool;

   procedure Test_Make_U8 (T : in out Test_Case'Class) is
      pragma Unreferenced (T);
      N : constant U8_Signals.Signal_Name := Pad ("EngineSpeed");
      S : constant U8_Signals.Signal :=
            U8_Signals.Make
              (Handle        => 42,
               Name          => N,
               Default_Value => 0,
               Size          => 8);
   begin
      Assert (U8_Signals.Get_Handle (S) = 42,
              "Make_U8: wrong handle");
      Assert (U8_Signals.Get_Name (S) = N,
              "Make_U8: wrong name");
      Assert (U8_Signals.Get_Size (S) = 8,
              "Make_U8: wrong size");
      Assert (U8_Signals.Get_Value (S) = 0,
              "Make_U8: default value should be 0");
      Assert (not U8_Signals.Is_Updated (S),
              "Make_U8: updated flag should be clear");
   end Test_Make_U8;

   procedure Test_Make_U16 (T : in out Test_Case'Class) is
      pragma Unreferenced (T);
      N : constant U16_Signals.Signal_Name := Pad ("WheelSpeed");
      S : constant U16_Signals.Signal :=
            U16_Signals.Make
              (Handle        => 255,
               Name          => N,
               Default_Value => 0,
               Size          => 16);
   begin
      Assert (U16_Signals.Get_Handle (S) = 255,
              "Make_U16: wrong handle");
      Assert (U16_Signals.Get_Name (S) = N,
              "Make_U16: wrong name");
      Assert (U16_Signals.Get_Size (S) = 16,
              "Make_U16: wrong size");
      Assert (U16_Signals.Get_Value (S) = 0,
              "Make_U16: default value should be 0");
      Assert (not U16_Signals.Is_Updated (S),
              "Make_U16: updated flag should be clear");
   end Test_Make_U16;

   procedure Test_Make_Byte_Array (T : in out Test_Case'Class) is
      pragma Unreferenced (T);
      N        : constant Array_Signals.Signal_Name := Pad ("DiagPayload");
      Zero_Arr : constant l_byte_array := [others => 0];
      S        : constant Array_Signals.Signal :=
                   Array_Signals.Make
                     (Handle        => 7,
                      Name          => N,
                      Default_Value => Zero_Arr,
                      Size          => 4);
   begin
      Assert (Array_Signals.Get_Handle (S) = 7,
              "Make_Byte_Array: wrong handle");
      Assert (Array_Signals.Get_Name (S) = N,
              "Make_Byte_Array: wrong name");
      Assert (Array_Signals.Get_Size (S) = 4,
              "Make_Byte_Array: wrong size");
      Assert (Array_Signals.Get_Value (S) = Zero_Arr,
              "Make_Byte_Array: default should be all zeros");
      Assert (not Array_Signals.Is_Updated (S),
              "Make_Byte_Array: updated flag should be clear");
   end Test_Make_Byte_Array;

   --  -----------------------------------------------------------------------
   --  Set_Value tests – new value stored, Is_Updated becomes True
   --  -----------------------------------------------------------------------

   procedure Test_Set_Value_Bool (T : in out Test_Case'Class) is
      pragma Unreferenced (T);
      S : Bool_Signals.Signal :=
            Bool_Signals.Make (0, Pad ("Lamp"), False, 1);
   begin
      Bool_Signals.Set_Value (S, True);
      Assert (Bool_Signals.Get_Value (S),
              "Set_Value_Bool: value not stored");
      Assert (Bool_Signals.Is_Updated (S),
              "Set_Value_Bool: updated flag not raised");
      --  Handle and name must be preserved
      Assert (Bool_Signals.Get_Handle (S) = 0,
              "Set_Value_Bool: handle changed unexpectedly");
      Assert (Bool_Signals.Get_Name (S) = Pad ("Lamp"),
              "Set_Value_Bool: name changed unexpectedly");
   end Test_Set_Value_Bool;

   procedure Test_Set_Value_U8 (T : in out Test_Case'Class) is
      pragma Unreferenced (T);
      S : U8_Signals.Signal :=
            U8_Signals.Make (10, Pad ("ThrottlePos"), 0, 8);
   begin
      U8_Signals.Set_Value (S, 200);
      Assert (Integer (U8_Signals.Get_Value (S)) = 200,
              "Set_Value_U8: value not stored");
      Assert (U8_Signals.Is_Updated (S),
              "Set_Value_U8: updated flag not raised");
      Assert (U8_Signals.Get_Handle (S) = 10,
              "Set_Value_U8: handle changed unexpectedly");
   end Test_Set_Value_U8;

   procedure Test_Set_Value_U16 (T : in out Test_Case'Class) is
      pragma Unreferenced (T);
      S : U16_Signals.Signal :=
            U16_Signals.Make (20, Pad ("RPM"), 0, 16);
   begin
      U16_Signals.Set_Value (S, 6_000);
      Assert (Integer (U16_Signals.Get_Value (S)) = 6_000,
              "Set_Value_U16: value not stored");
      Assert (U16_Signals.Is_Updated (S),
              "Set_Value_U16: updated flag not raised");
      Assert (U16_Signals.Get_Handle (S) = 20,
              "Set_Value_U16: handle changed unexpectedly");
   end Test_Set_Value_U16;

   procedure Test_Set_Value_Byte_Array (T : in out Test_Case'Class) is
      pragma Unreferenced (T);
      Zero : constant l_byte_array := [others => 0];
      S    : Array_Signals.Signal :=
               Array_Signals.Make (5, Pad ("RawFrame"), Zero, 8);
      Data : constant l_byte_array :=
               [16#01#, 16#02#, 16#03#, 16#04#,
                16#05#, 16#06#, 16#07#, 16#08#];
   begin
      Array_Signals.Set_Value (S, Data);
      Assert (Array_Signals.Get_Value (S) = Data,
              "Set_Value_Byte_Array: value not stored");
      Assert (Array_Signals.Is_Updated (S),
              "Set_Value_Byte_Array: updated flag not raised");
      Assert (Array_Signals.Get_Handle (S) = 5,
              "Set_Value_Byte_Array: handle changed unexpectedly");
   end Test_Set_Value_Byte_Array;

   --  -----------------------------------------------------------------------
   --  Masking tests – bits / bytes beyond declared size are discarded
   --  -----------------------------------------------------------------------

   --  A 4-bit U8 signal (max value 15). Writing 0x1F (31) must yield 0xF (15).
   procedure Test_Mask_U8 (T : in out Test_Case'Class) is
      pragma Unreferenced (T);
      S : U8_Signals.Signal :=
            U8_Signals.Make (11, Pad ("NibbleSig"), 0, 4);
   begin
      Assert (U8_Signals.Get_Size (S) = 4,
              "Mask_U8: size should be 4");
      U8_Signals.Set_Value (S, 16#1F#);   --  0001_1111 -> 0000_1111
      Assert (Integer (U8_Signals.Get_Value (S)) = 16#0F#,
              "Mask_U8: upper bits not masked out");
      Assert (U8_Signals.Is_Updated (S),
              "Mask_U8: updated flag not raised");
   end Test_Mask_U8;

   --  A 10-bit U16 signal (max 1023). Writing 2000 must yield 976
   --  because 2000 mod 1024 = 976.
   procedure Test_Mask_U16 (T : in out Test_Case'Class) is
      pragma Unreferenced (T);
      S : U16_Signals.Signal :=
            U16_Signals.Make (12, Pad ("TenBitSig"), 0, 10);
   begin
      Assert (U16_Signals.Get_Size (S) = 10,
              "Mask_U16: size should be 10");
      U16_Signals.Set_Value (S, 2_000);   --  2000 mod 1024 = 976
      Assert (Integer (U16_Signals.Get_Value (S)) = 976,
              "Mask_U16: upper bits not masked out");
      Assert (U16_Signals.Is_Updated (S),
              "Mask_U16: updated flag not raised");
   end Test_Mask_U16;

   --  A 3-byte array signal. Writing 8 non-zero bytes must zero bytes 3-7.
   procedure Test_Mask_Byte_Array (T : in out Test_Case'Class) is
      pragma Unreferenced (T);
      Zero   : constant l_byte_array := [others => 0];
      S      : Array_Signals.Signal :=
                 Array_Signals.Make (13, Pad ("ThreeByteSig"), Zero, 3);
      Full   : constant l_byte_array :=
                 [16#AA#, 16#BB#, 16#CC#, 16#DD#,
                  16#EE#, 16#FF#, 16#11#, 16#22#];
      --  Expected: first 3 bytes kept, rest zeroed.
      Expect : constant l_byte_array :=
                 [16#AA#, 16#BB#, 16#CC#, 0, 0, 0, 0, 0];
   begin
      Assert (Array_Signals.Get_Size (S) = 3,
              "Mask_Array: size should be 3");
      Array_Signals.Set_Value (S, Full);
      Assert (Array_Signals.Get_Value (S) = Expect,
              "Mask_Array: bytes beyond size not zeroed");
      Assert (Array_Signals.Is_Updated (S),
              "Mask_Array: updated flag not raised");
   end Test_Mask_Byte_Array;

   --  The default value passed to Make is also masked.
   --  A 4-bit U8 signal with Default_Value => 0xFF must store 0x0F.
   procedure Test_Mask_Default_Value (T : in out Test_Case'Class) is
      pragma Unreferenced (T);
      S : constant U8_Signals.Signal :=
            U8_Signals.Make (14, Pad ("MaskedDefault"), 16#FF#, 4);
   begin
      Assert (Integer (U8_Signals.Get_Value (S)) = 16#0F#,
              "Mask_Default: default value not masked on construction");
      Assert (not U8_Signals.Is_Updated (S),
              "Mask_Default: updated flag should be clear after Make");
   end Test_Mask_Default_Value;

   --  -----------------------------------------------------------------------
   --  Clear_Updated tests – flag cleared, value and identity unchanged
   --  -----------------------------------------------------------------------

   procedure Test_Clear_Updated_Bool (T : in out Test_Case'Class) is
      pragma Unreferenced (T);
      S : Bool_Signals.Signal :=
            Bool_Signals.Make (3, Pad ("DoorOpen"), False, 1);
   begin
      Bool_Signals.Set_Value (S, True);
      Bool_Signals.Clear_Updated (S);
      Assert (not Bool_Signals.Is_Updated (S),
              "Clear_Updated_Bool: flag not cleared");
      Assert (Bool_Signals.Get_Value (S),
              "Clear_Updated_Bool: value must not change");
      Assert (Bool_Signals.Get_Handle (S) = 3,
              "Clear_Updated_Bool: handle changed unexpectedly");
      Assert (Bool_Signals.Get_Name (S) = Pad ("DoorOpen"),
              "Clear_Updated_Bool: name changed unexpectedly");
   end Test_Clear_Updated_Bool;

   procedure Test_Clear_Updated_U8 (T : in out Test_Case'Class) is
      pragma Unreferenced (T);
      S : U8_Signals.Signal :=
            U8_Signals.Make (8, Pad ("FanSpeed"), 0, 8);
   begin
      U8_Signals.Set_Value (S, 128);
      U8_Signals.Clear_Updated (S);
      Assert (not U8_Signals.Is_Updated (S),
              "Clear_Updated_U8: flag not cleared");
      Assert (U8_Signals.Get_Value (S) = 128,
              "Clear_Updated_U8: value must not change");
      Assert (U8_Signals.Get_Handle (S) = 8,
              "Clear_Updated_U8: handle changed unexpectedly");
   end Test_Clear_Updated_U8;

   procedure Test_Clear_Updated_U16 (T : in out Test_Case'Class) is
      pragma Unreferenced (T);
      S : U16_Signals.Signal :=
            U16_Signals.Make (15, Pad ("OdometerKm"), 0, 16);
   begin
      U16_Signals.Set_Value (S, 50_000);
      U16_Signals.Clear_Updated (S);
      Assert (not U16_Signals.Is_Updated (S),
              "Clear_Updated_U16: flag not cleared");
      Assert (U16_Signals.Get_Value (S) = 50_000,
              "Clear_Updated_U16: value must not change");
      Assert (U16_Signals.Get_Handle (S) = 15,
              "Clear_Updated_U16: handle changed unexpectedly");
   end Test_Clear_Updated_U16;

   procedure Test_Clear_Updated_Byte_Array (T : in out Test_Case'Class) is
      pragma Unreferenced (T);
      Zero : constant l_byte_array := [others => 0];
      S    : Array_Signals.Signal :=
               Array_Signals.Make (9, Pad ("ConfigFrame"), Zero, 8);
      Data : constant l_byte_array :=
               [16#AA#, 16#BB#, 16#CC#, 16#DD#,
                16#EE#, 16#FF#, 16#11#, 16#22#];
   begin
      Array_Signals.Set_Value (S, Data);
      Array_Signals.Clear_Updated (S);
      Assert (not Array_Signals.Is_Updated (S),
              "Clear_Updated_Byte_Array: flag not cleared");
      Assert (Array_Signals.Get_Value (S) = Data,
              "Clear_Updated_Byte_Array: value unchanged");
      Assert (Array_Signals.Get_Handle (S) = 9,
              "Clear_Updated_Byte_Array: handle changed unexpectedly");
   end Test_Clear_Updated_Byte_Array;

   --  -----------------------------------------------------------------------
   --  Set_Value twice: latest value wins, updated flag stays set
   --  -----------------------------------------------------------------------

   procedure Test_Overwrite_Value (T : in out Test_Case'Class) is
      pragma Unreferenced (T);
      S : U16_Signals.Signal :=
            U16_Signals.Make (30, Pad ("BattVoltage"), 0, 16);
   begin
      U16_Signals.Set_Value (S, 1_200);
      U16_Signals.Set_Value (S, 1_350);
      Assert (Integer (U16_Signals.Get_Value (S)) = 1_350,
              "Overwrite: second value should replace first");
      Assert (U16_Signals.Is_Updated (S),
              "Overwrite: updated flag must remain set");
   end Test_Overwrite_Value;

   --  -----------------------------------------------------------------------
   --  Round-trip: Set_Value → Clear_Updated → Set_Value again
   --  -----------------------------------------------------------------------

   procedure Test_Round_Trip (T : in out Test_Case'Class) is
      pragma Unreferenced (T);
      S : U8_Signals.Signal :=
            U8_Signals.Make (50, Pad ("LightLevel"), 0, 8);
   begin
      --  First write
      U8_Signals.Set_Value (S, 10);
      Assert (U8_Signals.Is_Updated (S),
              "Round_Trip: flag set after 1st write");

      --  Simulate driver consuming the value
      U8_Signals.Clear_Updated (S);
      Assert (not U8_Signals.Is_Updated (S),
              "Round_Trip: flag clear after consume");
      Assert (Integer (U8_Signals.Get_Value (S)) = 10,
              "Round_Trip: value intact after clear");

      --  Second write
      U8_Signals.Set_Value (S, 99);
      Assert (Integer (U8_Signals.Get_Value (S)) = 99,
              "Round_Trip: 2nd value stored");
      Assert (U8_Signals.Is_Updated (S),
              "Round_Trip: flag set after 2nd write");
   end Test_Round_Trip;

end Tests.Adalin_Signal;
