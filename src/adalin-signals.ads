--  Adalin.Signals – Library-level Adalin.Signal instantiations and
--  concrete Signal_Entry wrapper types for the three standard LIN value
--  types (l_u8, l_u16, l_byte_array).
--
--  Placing these in a child package avoids the circular dependency that
--  would arise from withing Adalin.Signal inside adalin.ads itself (a
--  parent package may not with its own child).  As a child of Adalin,
--  this package has implicit visibility into all public declarations of
--  Adalin (l_u8, l_u16, l_byte_array, LIN_PID, Signal_Entry, and the
--  mask/trim helpers) without an explicit with clause.
--
--  Layout
--  ------
--  1. Adalin.Signal instantiations – one per concrete LIN value type.
--  2. Concrete Signal_Entry wrapper types – one per instantiation.

with Adalin.Signal;

package Adalin.Signals is

   ---------------------------------------------------------------------------
   --  1. Adalin.Signal instantiations
   ---------------------------------------------------------------------------
   package U8_Signal is new Adalin.Signal
     (Value_Type    => l_u8,
      Is_Array_Type => False,
      Mask_Bits     => U8_Mask,
      Trim_Bytes    => U8_Identity);

   package U16_Signal is new Adalin.Signal
     (Value_Type    => l_u16,
      Is_Array_Type => False,
      Mask_Bits     => U16_Mask,
      Trim_Bytes    => U16_Identity);

   package Arr_Signal is new Adalin.Signal
     (Value_Type    => l_byte_array,
      Is_Array_Type => True,
      Mask_Bits     => Array_Identity,
      Trim_Bytes    => Array_Trim);

   ---------------------------------------------------------------------------
   --  2. Concrete Signal_Entry wrapper types
   ---------------------------------------------------------------------------

   --  Wraps a U8_Signal.Signal; associated with an 8-bit scalar PID.
   type U8_Signal_Entry is new Signal_Entry with record
      PID : LIN_PID;
      Sig : U8_Signal.Signal;
   end record;

   overriding function Get_PID
     (E : U8_Signal_Entry) return LIN_PID;
   overriding function Is_Updated
     (E : U8_Signal_Entry) return Boolean;
   overriding procedure Clear_Updated
     (E : in out U8_Signal_Entry);

   function  Get_Value
     (E :        U8_Signal_Entry) return l_u8;
   procedure Set_Value
     (E : in out U8_Signal_Entry; Value : l_u8);

   --  Wraps a U16_Signal.Signal; associated with a 16-bit scalar PID.
   type U16_Signal_Entry is new Signal_Entry with record
      PID : LIN_PID;
      Sig : U16_Signal.Signal;
   end record;

   overriding function Get_PID
     (E : U16_Signal_Entry) return LIN_PID;
   overriding function Is_Updated
     (E : U16_Signal_Entry) return Boolean;
   overriding procedure Clear_Updated
     (E : in out U16_Signal_Entry);

   function  Get_Value
     (E :        U16_Signal_Entry) return l_u16;
   procedure Set_Value
     (E : in out U16_Signal_Entry; Value : l_u16);

   --  Wraps an Arr_Signal.Signal; associated with a byte-array PID.
   type Arr_Signal_Entry is new Signal_Entry with record
      PID : LIN_PID;
      Sig : Arr_Signal.Signal;
   end record;

   overriding function Get_PID
     (E : Arr_Signal_Entry) return LIN_PID;
   overriding function Is_Updated
     (E : Arr_Signal_Entry) return Boolean;
   overriding procedure Clear_Updated
     (E : in out Arr_Signal_Entry);

   function  Get_Value
     (E :        Arr_Signal_Entry) return l_byte_array;
   procedure Set_Value
     (E : in out Arr_Signal_Entry; Value : l_byte_array);

end Adalin.Signals;
