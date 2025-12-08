with AUnit.Assertions; use AUnit.Assertions;
with Adalin; use Adalin;
with Interfaces; use Interfaces;

package body Tests.Adalin_Core is

   overriding
   procedure Register_Tests (T : in out Test) is
      use Registration;
   begin
      Register_Routine
        (T,
         Tests.Adalin_Core.Test_Driver_Management'Access,
         "Test driver and cluster management interface");
      Register_Routine
        (T,
         Tests.Adalin_Core.Test_Signal'Access,
         "Test signal interaction");
   end Register_Tests;

   overriding
   function Name (T : Test) return Message_String is
   begin
      return Format ("adaLIN Core API Tests");
   end Name;

   --  Mock implementation of the API
   subtype flag_value is Unsigned_8 range 0 .. 31;
   type Core_Mock is new Core_Interface with record
      c_l_sys_init : Boolean := False;
      c_l_rd : Boolean := False;
      c_l_wr : Boolean := False;
      c_l_ifc_init : Boolean := False;
      c_l_ifc_wake_up : Boolean := False;
      s_bool : l_bool := False;
      s_u8 : l_u8 := 0;
      s_u16 : l_u16 := 0;
      s_array : l_byte_array := (others => 0);
      flg : flag_value := 0;
      irq : l_irqmask := 16#ff#;
   end record;
   overriding function l_sys_init (T : in out Core_Mock) return l_bool;
   overriding function l_rd (T : in out Core_Mock; sig : l_signal_handle) return l_bool;
   overriding function l_rd (T : in out Core_Mock; sig : l_signal_handle) return l_u8;
   overriding function l_rd (T : in out Core_Mock; sig : l_signal_handle) return l_u16;
   overriding procedure l_wr (T : in out Core_Mock; sig : l_signal_handle; val : l_bool);
   overriding procedure l_wr (T : in out Core_Mock; sig : l_signal_handle; val : l_u8);
   overriding procedure l_wr (T : in out Core_Mock; sig : l_signal_handle; val : l_u16);
   overriding function l_rd (T : in out Core_Mock; sig : l_signal_handle) return l_byte_array;
   overriding procedure l_wr (T : in out Core_Mock; sig : l_signal_handle; val : l_byte_array);
   overriding function l_flg_tst (T : in out Core_Mock; flag : l_flag_handle) return l_bool;
   overriding procedure l_flg_clr (T : in out Core_Mock; flag : l_flag_handle);
   overriding function l_ifc_init (T : in out Core_Mock; iii : l_ifc_handle) return l_bool;
   overriding procedure l_ifc_wake_up (T : in out Core_Mock; iii : l_ifc_handle);
   overriding function sys_irq_disable (T : in out Core_Mock) return l_irqmask;
   overriding procedure sys_irq_restore (T : in out Core_Mock; State : l_irqmask);

   procedure Reset (T : in out Core_Mock) is
   begin
      T.c_l_sys_init := False;
      T.c_l_rd := False;
      T.c_l_wr := False;
      T.c_l_ifc_init := False;
      T.c_l_ifc_wake_up := False;
      T.s_bool := False;
      T.s_u8 := 0;
      T.s_u16 := 0;
      T.s_array := (others => 0);
      T.flg := 0;
      T.irq := 16#ff#;
   end Reset;

   overriding function l_sys_init (T : in out Core_Mock) return l_bool is
   begin
      T.c_l_sys_init := True;
      return True;
   end l_sys_init;
   overriding function l_rd (T : in out Core_Mock; sig : l_signal_handle) return l_bool is
   begin
      T.c_l_rd := True;
      return T.s_bool;
   end l_rd;
   overriding function l_rd (T : in out Core_Mock; sig : l_signal_handle) return l_u8 is
   begin
      T.c_l_rd := True;
      return T.s_u8;
   end l_rd;
   overriding function l_rd (T : in out Core_Mock; sig : l_signal_handle) return l_u16 is
   begin
      T.c_l_rd := True;
      return T.s_u16;
   end l_rd;
   overriding procedure l_wr (T : in out Core_Mock; sig : l_signal_handle; val : l_bool) is
   begin
      T.s_bool := val;
      T.c_l_wr := True;
   end l_wr;
   overriding procedure l_wr (T : in out Core_Mock; sig : l_signal_handle; val : l_u8) is
   begin
      T.s_u8 := val;
      T.c_l_wr := True;
   end l_wr;
   overriding procedure l_wr (T : in out Core_Mock; sig : l_signal_handle; val : l_u16) is
   begin
      T.s_u16 := val;
      T.c_l_wr := True;
   end l_wr;
   overriding function l_rd (T : in out Core_Mock; sig : l_signal_handle) return l_byte_array is
   begin
      T.c_l_rd := True;
      return T.s_array;
   end l_rd;
   overriding procedure l_wr (T : in out Core_Mock; sig : l_signal_handle; val : l_byte_array) is
   begin
      T.s_array := val;
   end l_wr;
   overriding function l_flg_tst (T : in out Core_Mock; flag : l_flag_handle) return l_bool is
      tst : constant flag_value := Shift_Left (1, flag);
   begin
      return (T.flg and tst) /= 0;
   end l_flg_tst;
   overriding procedure l_flg_clr (T : in out Core_Mock; flag : l_flag_handle) is
      mask : constant flag_value := not Shift_Left (1, flag);
   begin
      T.flg := T.flg and mask;
   end l_flg_clr;
   overriding function l_ifc_init (T : in out Core_Mock; iii : l_ifc_handle) return l_bool is
   begin
      T.c_l_ifc_init := True;
      return True;
   end l_ifc_init;
   overriding procedure l_ifc_wake_up (T : in out Core_Mock; iii : l_ifc_handle) is
   begin
      T.c_l_ifc_wake_up := True;
   end l_ifc_wake_up;
   overriding function sys_irq_disable (T : in out Core_Mock) return l_irqmask is
      rval : constant l_irqmask := T.irq;
   begin
      T.irq := 0;
      return rval;
   end sys_irq_disable;
   overriding procedure sys_irq_restore (T : in out Core_Mock; State : l_irqmask) is
   begin
      T.irq := State;
   end sys_irq_restore;

   --  Fixture elements
   CORE : Core_Mock;

   overriding
   procedure Set_Up (T : in out Test) is
   begin
      CORE.Reset;
   end Set_Up;

   procedure Test_Driver_Management (T : in out Test_Case'Class) is
      pragma Unreferenced (T);

   begin
      Assert (l_sys_init (CORE) = True, "l_sys_init failed");
      Assert (CORE.l_sys_init = True, "l_sys_init was not called");
   end Test_Driver_Management;

   procedure Test_Signal (T : in out Test_Case'Class) is
      pragma Unreferenced (T);

   begin
      null;
   end Test_Signal;

   procedure Test_Notification (T : in out Test_Case'Class) is
   begin
      null;
   end Test_Notification;

   procedure Test_Interface (T : in out Test_Case'Class) is
   begin
      null;
   end Test_Interface;

   procedure Test_Interrupts (T : in out Test_Case'Class) is
      mask : l_irqmask := CORE.sys_irq_disable;
   begin
      Assert (mask = 16#ff#, "irqs weren't disabled");
      Assert (CORE.irq = 0, "irqs aren't disabled");
      CORE.sys_irq_restore (mask);
      Assert (CORE.irq = mask, "irqs weren't restored");
   end Test_Interrupts;

end Tests.Adalin_Core;
