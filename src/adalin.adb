package body Adalin is
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
      return (others => 0);
   end l_rd;

   procedure l_wr (sig : l_signal_handle; val : l_bool) is null;
   procedure l_wr (sig : l_signal_handle; val : l_u8) is null;
   procedure l_wr (sig : l_signal_handle; val : l_u16) is null;
   procedure l_wr (sig : l_signal_handle; val : l_byte_array) is null;

   function l_flg_tst (flag : l_flag_handle) return l_bool is
      pragma Unreferenced (flag);
   begin
      return False;
   end l_flg_tst;

   procedure l_flg_clr (flag : l_flag_handle) is null;
   procedure l_ifc_init (iii : l_ifc_handle) is null;
   procedure l_ifc_wake_up (iii : l_ifc_handle) is null;
end Adalin;
