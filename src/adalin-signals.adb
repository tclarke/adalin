--  Adalin.Signals - body

with Interfaces; use Interfaces;

package body Adalin.Signals
   with SPARK_Mode => On
is
   ---------------------------------------------------------------------------
   --  U8_Signal_Entry primitives
   ---------------------------------------------------------------------------

   overriding function Get_PID (E : U8_Signal_Entry) return LIN_PID is
   begin
      return E.PID;
   end Get_PID;

   overriding function Is_Updated (E : U8_Signal_Entry) return Boolean is
   begin
      return U8_Signal.Is_Updated (E.Sig);
   end Is_Updated;

   overriding procedure Clear_Updated (E : in out U8_Signal_Entry) is
   begin
      U8_Signal.Clear_Updated (E.Sig);
   end Clear_Updated;

   --  LIN 2.2A sec 2.3.1.4: scalars are little-endian, so byte 0 is LSB.
   --  An l_u8 fits in one byte; N is expected to be 1 but we guard anyway.
   overriding procedure Receive_Bytes
     (E   : in out U8_Signal_Entry;
      Buf : Raw_Frame_Bytes;
      N   : Positive)
   is
      pragma Unreferenced (N);
   begin
      U8_Signal.Set_Value (E.Sig, l_u8 (Buf (0)));
   end Receive_Bytes;

   overriding procedure Transmit_Bytes
     (E   : U8_Signal_Entry;
      Buf : out Raw_Frame_Bytes;
      N   : Positive)
   is
      pragma Unreferenced (N);
   begin
      Buf := [others => 0];
      Buf (0) := Unsigned_8 (U8_Signal.Get_Value (E.Sig));
   end Transmit_Bytes;

   function Get_Value (E : U8_Signal_Entry) return l_u8 is
   begin
      return U8_Signal.Get_Value (E.Sig);
   end Get_Value;

   procedure Set_Value (E : in out U8_Signal_Entry; Value : l_u8) is
   begin
      U8_Signal.Set_Value (E.Sig, Value);
   end Set_Value;

   ---------------------------------------------------------------------------
   --  U16_Signal_Entry primitives
   ---------------------------------------------------------------------------

   overriding function Get_PID (E : U16_Signal_Entry) return LIN_PID is
   begin
      return E.PID;
   end Get_PID;

   overriding function Is_Updated (E : U16_Signal_Entry) return Boolean is
   begin
      return U16_Signal.Is_Updated (E.Sig);
   end Is_Updated;

   overriding procedure Clear_Updated (E : in out U16_Signal_Entry) is
   begin
      U16_Signal.Clear_Updated (E.Sig);
   end Clear_Updated;

   --  LIN 2.2A sec 2.3.1.4: byte 0 = LSB, byte 1 = MSB (little-endian).
   overriding procedure Receive_Bytes
     (E   : in out U16_Signal_Entry;
      Buf : Raw_Frame_Bytes;
      N   : Positive)
   is
      Lo  : constant Unsigned_16 := Unsigned_16 (Buf (0));
      Hi  : constant Unsigned_16 :=
              (if N >= 2 then Unsigned_16 (Buf (1)) else 0);
      Val : constant l_u16 := l_u16 (Lo or Shift_Left (Hi, 8));
   begin
      U16_Signal.Set_Value (E.Sig, Val);
   end Receive_Bytes;

   overriding procedure Transmit_Bytes
     (E   : U16_Signal_Entry;
      Buf : out Raw_Frame_Bytes;
      N   : Positive)
   is
      Val : constant Unsigned_16 := Unsigned_16 (U16_Signal.Get_Value (E.Sig));
   begin
      Buf := [others => 0];
         Buf (0) := Unsigned_8 (Val and 16#FF#);
      if N >= 2 then
         Buf (1) := Unsigned_8 (Shift_Right (Val, 8) and 16#FF#);
      end if;
   end Transmit_Bytes;

   function Get_Value (E : U16_Signal_Entry) return l_u16 is
   begin
      return U16_Signal.Get_Value (E.Sig);
   end Get_Value;

   procedure Set_Value (E : in out U16_Signal_Entry; Value : l_u16) is
   begin
      U16_Signal.Set_Value (E.Sig, Value);
   end Set_Value;

   ---------------------------------------------------------------------------
   --  Arr_Signal_Entry primitives
   ---------------------------------------------------------------------------

   overriding function Get_PID (E : Arr_Signal_Entry) return LIN_PID is
   begin
      return E.PID;
   end Get_PID;

   overriding function Is_Updated (E : Arr_Signal_Entry) return Boolean is
   begin
      return Arr_Signal.Is_Updated (E.Sig);
   end Is_Updated;

   overriding procedure Clear_Updated (E : in out Arr_Signal_Entry) is
   begin
      Arr_Signal.Clear_Updated (E.Sig);
   end Clear_Updated;

   --  Byte arrays map 1-to-1: buf[0] -> l_byte_array(0), etc.
   overriding procedure Receive_Bytes
     (E   : in out Arr_Signal_Entry;
      Buf : Raw_Frame_Bytes;
      N   : Positive)
   is
      Val : l_byte_array := [others => 0];
   begin
      for I in 0 .. N - 1 loop
         exit when I > Integer (l_array_index'Last);
         Val (l_array_index (I)) := l_u8 (Buf (I));
      end loop;
      Arr_Signal.Set_Value (E.Sig, Val);
   end Receive_Bytes;

   overriding procedure Transmit_Bytes
     (E   : Arr_Signal_Entry;
      Buf : out Raw_Frame_Bytes;
      N   : Positive)
   is
      Val : constant l_byte_array := Arr_Signal.Get_Value (E.Sig);
   begin
      Buf := [others => 0];
      for I in 0 .. N - 1 loop
         exit when I > Integer (l_array_index'Last);
         Buf (I) := Unsigned_8 (Val (l_array_index (I)));
      end loop;
   end Transmit_Bytes;

   function Get_Value (E : Arr_Signal_Entry) return l_byte_array is
   begin
      return Arr_Signal.Get_Value (E.Sig);
   end Get_Value;

   procedure Set_Value (E : in out Arr_Signal_Entry; Value : l_byte_array) is
   begin
      Arr_Signal.Set_Value (E.Sig, Value);
   end Set_Value;

end Adalin.Signals;
