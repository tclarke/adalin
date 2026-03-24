--  Adalin.Signal – Generic ADT for a single LIN signal.
--
--  Each instantiation binds the signal to one concrete LIN data type:
--    • l_bool       (1-bit scalar)
--    • l_u8         (2-8 bit scalar)
--    • l_u16        (9-16 bit scalar)
--    • l_byte_array (1-8 byte array)
--
--  Two generic formal functions handle the two fundamentally different
--  size-constraint semantics:
--
--    Mask_Bits  – used when Is_Array_Type = False (scalar signals).
--                 Must return V with all bits at or above bit position
--                 Bits cleared, e.g. V AND (2**Bits - 1).
--
--    Trim_Bytes – used when Is_Array_Type = True (byte-array signals).
--                 Must return V with all elements at index >= Bytes
--                 replaced by zero/default, preserving the first Bytes
--                 elements unchanged.
--
--  The caller provides an identity stub for whichever formal is not used.
--
--  Usage examples:
--    package U8_Signals is new Adalin.Signal
--      (Value_Type    => Adalin.l_u8,
--       Is_Array_Type => False,
--       Mask_Bits     => U8_Mask,
--       Trim_Bytes    => U8_Identity);
--    package Array_Signals is new Adalin.Signal
--      (Value_Type    => Adalin.l_byte_array,
--       Is_Array_Type => True,
--       Mask_Bits     => Array_Identity,
--       Trim_Bytes    => Array_Trim);
--
--  The "updated" flag mirrors the LIN sporadic/event-triggered frame concept
--  (LIN 2.2A spec §2.3.3.2-3): a signal is marked updated when written and
--  the flag is cleared by the driver once the frame has been transmitted.

generic
   --  The LIN data type carried by this signal.
   type Value_Type is private;

   --  True for byte-array signals; False for scalar (bool/u8/u16) signals.
   --  Selects whether Mask_Bits or Trim_Bytes is applied on every write.
   Is_Array_Type : Boolean;

   --  Called when Is_Array_Type = False.
   --  Must return V with all bits at or above bit position Bits cleared.
   with function Mask_Bits
     (V    : Value_Type;
      Bits : Positive) return Value_Type;

   --  Called when Is_Array_Type = True.
   --  Must return V with all elements at index >= Bytes replaced by zero.
   with function Trim_Bytes
     (V     : Value_Type;
      Bytes : Positive) return Value_Type;

package Adalin.Signal
  with SPARK_Mode => On
is

   --  Maximum length of a signal name (printable ASCII, space-padded).
   Max_Name_Length : constant := 64;
   subtype Signal_Name is String (1 .. Max_Name_Length);

   --  Number of bits for scalar signals (1 = l_bool, 2-8 = l_u8, 9-16 = l_u16)
   --  or number of active bytes for byte-array signals (1-8).
   subtype Signal_Size is Positive range 1 .. 16;

   --  -----------------------------------------------------------------------
   --  Signal ADT – private record; always manipulate via subprograms below.
   --  -----------------------------------------------------------------------
   type Signal is private;

   --  -----------------------------------------------------------------------
   --  Constructor
   --  -----------------------------------------------------------------------

   --  Return a new signal with the given handle, name, default value, and
   --  size.  The default value is itself constrained (via Mask_Bits or
   --  Trim_Bytes) so the stored value is always consistent with Size.
   --  Is_Updated is initialised to False.
   function Make
     (Handle        : l_signal_handle;
      Name          : Signal_Name;
      Default_Value : Value_Type;
      Size          : Signal_Size) return Signal
   with Post =>
     Get_Handle (Make'Result) = Handle and then
     Get_Name   (Make'Result) = Name   and then
     Get_Size   (Make'Result) = Size   and then
     Get_Value  (Make'Result) =
       (if Is_Array_Type
        then Trim_Bytes (Default_Value, Size)
        else Mask_Bits  (Default_Value, Size)) and then
     not Is_Updated (Make'Result);

   --  -----------------------------------------------------------------------
   --  Queries
   --  -----------------------------------------------------------------------

   function Get_Handle (S : Signal) return l_signal_handle;
   function Get_Name   (S : Signal) return Signal_Name;
   function Get_Value  (S : Signal) return Value_Type;

   --  Number of bits (scalar) or active bytes (array) for this signal.
   function Get_Size   (S : Signal) return Signal_Size;

   --  True when the value has been written since the last Clear_Updated call.
   --  Mirrors the "updated signal" flag used by sporadic / event-triggered
   --  frames (LIN 2.2A §2.3.3.2-3).
   function Is_Updated (S : Signal) return Boolean;

   --  -----------------------------------------------------------------------
   --  Mutators
   --  -----------------------------------------------------------------------

   --  Overwrite the signal value.  For scalar signals the value is masked
   --  to the declared bit width via Mask_Bits; for array signals the active
   --  bytes are trimmed to Size via Trim_Bytes.  Marks the signal as updated.
   procedure Set_Value (S : in out Signal; Value : Value_Type)
   with Post =>
     Get_Value  (S) =
       (if Is_Array_Type
        then Trim_Bytes (Value, Get_Size (S'Old))
        else Mask_Bits  (Value, Get_Size (S'Old))) and then
     Is_Updated (S) and then
     Get_Size   (S) = Get_Size   (S'Old) and then
     Get_Handle (S) = Get_Handle (S'Old) and then
     Get_Name   (S) = Get_Name   (S'Old);

   --  Clear the updated flag once the value has been consumed by the driver.
   procedure Clear_Updated (S : in out Signal)
   with Post =>
     not Is_Updated (S) and then
     Get_Value  (S) = Get_Value  (S'Old) and then
     Get_Size   (S) = Get_Size   (S'Old) and then
     Get_Handle (S) = Get_Handle (S'Old) and then
     Get_Name   (S) = Get_Name   (S'Old);

private

   type Signal is record
      Handle  : l_signal_handle := 0;
      Name    : Signal_Name     := [others => ' '];
      Value   : Value_Type;
      Size    : Signal_Size     := 1;
      Updated : Boolean         := False;
   end record;

end Adalin.Signal;
