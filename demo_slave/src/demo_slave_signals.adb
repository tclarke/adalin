--  Demo_Slave_Signals - body
--
--  The mask/trim helper functions are expression functions defined in the
--  spec; only the Signal_Entry primitives and Initialize_Node live here.

package body Demo_Slave_Signals is

   ---------------------------------------------------------------------------
   --  U8_Signal_Entry
   ---------------------------------------------------------------------------

   overriding function Get_PID
     (E : U8_Signal_Entry) return My_Slave.LIN_PID
   is
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

   function Get_Value (E : U8_Signal_Entry) return Adalin.l_u8 is
   begin
      return U8_Signal.Get_Value (E.Sig);
   end Get_Value;

   procedure Set_Value
     (E : in out U8_Signal_Entry; Value : Adalin.l_u8)
   is
   begin
      U8_Signal.Set_Value (E.Sig, Value);
   end Set_Value;

   ---------------------------------------------------------------------------
   --  U16_Signal_Entry
   ---------------------------------------------------------------------------

   overriding function Get_PID
     (E : U16_Signal_Entry) return My_Slave.LIN_PID
   is
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

   function Get_Value (E : U16_Signal_Entry) return Adalin.l_u16 is
   begin
      return U16_Signal.Get_Value (E.Sig);
   end Get_Value;

   procedure Set_Value
     (E : in out U16_Signal_Entry; Value : Adalin.l_u16)
   is
   begin
      U16_Signal.Set_Value (E.Sig, Value);
   end Set_Value;

   ---------------------------------------------------------------------------
   --  Arr_Signal_Entry
   ---------------------------------------------------------------------------

   overriding function Get_PID
     (E : Arr_Signal_Entry) return My_Slave.LIN_PID
   is
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

   function Get_Value (E : Arr_Signal_Entry) return Adalin.l_byte_array is
   begin
      return Arr_Signal.Get_Value (E.Sig);
   end Get_Value;

   procedure Set_Value
     (E : in out Arr_Signal_Entry; Value : Adalin.l_byte_array)
   is
   begin
      Arr_Signal.Set_Value (E.Sig, Value);
   end Set_Value;

   ---------------------------------------------------------------------------
   --  Initialize_Node
   ---------------------------------------------------------------------------

   procedure Initialize_Node is
   begin
      My_Slave.Register
        (My_Node, Engine_Speed_Entry.PID, Engine_Speed_Entry'Access);
      My_Slave.Register
        (My_Node, Battery_Voltage_Entry.PID, Battery_Voltage_Entry'Access);
      My_Slave.Register
        (My_Node, Sensor_Bytes_Entry.PID, Sensor_Bytes_Entry'Access);
   end Initialize_Node;

end Demo_Slave_Signals;
