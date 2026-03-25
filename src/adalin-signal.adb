--  Adalin.Signal – body

package body Adalin.Signal
  with SPARK_Mode => On
is

   --  Route to Mask_Bits (scalar) or Trim_Bytes (array) based on the
   --  Is_Array_Type generic formal.  This is the single call-site used by
   --  both Make and Set_Value so the dispatch logic lives in one place.
   function Constrain (V : Value_Type; Size : Signal_Size) return Value_Type is
   begin
      if Is_Array_Type then
         return Trim_Bytes (V, Size);
      else
         return Mask_Bits (V, Size);
      end if;
   end Constrain;

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

   function Get_Handle (S : Signal) return l_signal_handle is
   begin
      return S.Handle;
   end Get_Handle;

   function Get_Name (S : Signal) return Signal_Name is
   begin
      return S.Name;
   end Get_Name;

   function Get_Value (S : Signal) return Value_Type is
   begin
      return S.Value;
   end Get_Value;

   function Get_Size (S : Signal) return Signal_Size is
   begin
      return S.Size;
   end Get_Size;

   function Is_Updated (S : Signal) return Boolean is
   begin
      return S.Updated;
   end Is_Updated;

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
