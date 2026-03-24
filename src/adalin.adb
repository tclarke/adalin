package body Adalin is

   ---------------------------------------------------------------------------
   --  Signal_Map operations
   ---------------------------------------------------------------------------

   procedure Register
     (Map       : in out Signal_Map;
      PID       : LIN_PID;
      Entry_Ptr : not null Signal_Entry_Access)
   is
   begin
      if Map.Count >= Map.Capacity then
         raise Constraint_Error with
           "Adalin.Register: Signal_Map capacity ("
           & Map.Capacity'Image & ") exceeded";
      end if;
      Map.Entries (Map.Count + 1) := (PID => PID, Entry_Ptr => Entry_Ptr);
      Map.Count := Map.Count + 1;
   end Register;

   function Get_Entry
     (Map : Signal_Map;
      PID : LIN_PID) return Signal_Entry_Access
   is
   begin
      for I in 1 .. Map.Count loop
         if Map.Entries (I).PID = PID then
            return Map.Entries (I).Entry_Ptr;
         end if;
      end loop;
      return null;
   end Get_Entry;

   function Registered_Count (Map : Signal_Map) return Natural is
   begin
      return Map.Count;
   end Registered_Count;

   function Is_Ready (Map : Signal_Map) return Boolean is
   begin
      return Map.Count = Map.Capacity;
   end Is_Ready;

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

   function Get_Value (E : Arr_Signal_Entry) return l_byte_array is
   begin
      return Arr_Signal.Get_Value (E.Sig);
   end Get_Value;

   procedure Set_Value (E : in out Arr_Signal_Entry; Value : l_byte_array) is
   begin
      Arr_Signal.Set_Value (E.Sig, Value);
   end Set_Value;

   ---------------------------------------------------------------------------
   --  Core API stubs (to be replaced with hardware implementations)
   ---------------------------------------------------------------------------

   procedure l_sys_init is null;

   function l_rd (sig : l_signal_handle) return l_bool is
      pragma Unreferenced (sig);
   begin
      return False;
   end l_rd;

   function l_rd (sig : l_signal_handle) return l_u8 is
      pragma Unreferenced (sig);
   begin
      return 0;
   end l_rd;

   function l_rd (sig : l_signal_handle) return l_u16 is
      pragma Unreferenced (sig);
   begin
      return 0;
   end l_rd;

   function l_rd (sig : l_signal_handle) return l_byte_array is
      pragma Unreferenced (sig);
   begin
      return [others => 0];
   end l_rd;

   procedure l_wr (sig : l_signal_handle; val : l_bool) is null;
   procedure l_wr (sig : l_signal_handle; val : l_u8)   is null;
   procedure l_wr (sig : l_signal_handle; val : l_u16)  is null;
   procedure l_wr (sig : l_signal_handle; val : l_byte_array) is null;

   function l_flg_tst (flag : l_flag_handle) return l_bool is
      pragma Unreferenced (flag);
   begin
      return False;
   end l_flg_tst;

   procedure l_flg_clr  (flag : l_flag_handle) is null;
   procedure l_ifc_init     (iii : l_ifc_handle) is null;
   procedure l_ifc_wake_up  (iii : l_ifc_handle) is null;
   procedure l_ifc_rx       (iii : l_ifc_handle) is null;
   procedure l_ifc_tx       (iii : l_ifc_handle) is null;

end Adalin;
