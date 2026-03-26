--  Adalin.Signal - body

package body Adalin.Signal
  with SPARK_Mode => On
is

   --  Route to Mask_Bits (scalar) or Trim_Bytes (array) based on the
   --  Is_Array_Type generic formal.  Declared as an expression function so
   --  GNATprove can see through it when verifying postconditions on Make
   --  and Set_Value.
   --
   --  The pragma Warnings suppresses the "statement has no effect" warning
   --  that the compiler emits for the dead branch of the static Boolean
   --  Is_Array_Type when the generic is instantiated with a fixed value.
   function Constrain (V : Value_Type; Size : Signal_Size) return Value_Type is
     (if Is_Array_Type then Trim_Bytes (V, Size) else Mask_Bits (V, Size));

   function Make
     (Handle        : l_signal_handle;
      Name          : Signal_Name;
      Default_Value : Value_Type;
      Size          : Signal_Size) return Signal
   is
   begin
      return Signal'(Handle  => Handle,
                     Name    => Name,
                     Value   => Constrain (Default_Value, Size),
                     Size    => Size,
                     Updated => False);
   end Make;

   procedure Set_Value (S : in out Signal; Value : Value_Type) is
   begin
      S.Value   := Constrain (Value, S.Size);
      S.Updated := True;
   end Set_Value;

   procedure Clear_Updated (S : in out Signal) is
   begin
      S.Updated := False;
   end Clear_Updated;

end Adalin.Signal;