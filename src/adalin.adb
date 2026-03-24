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
