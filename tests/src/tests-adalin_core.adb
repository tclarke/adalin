with AUnit.Assertions; use AUnit.Assertions;
with Adalin;
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

   function sys_irq_disable return Adalin.l_irqmask
   with Export,
        Convention    => Ada,
        External_Name => "sys_irq_disable";

   procedure sys_irq_restore (State : Adalin.l_irqmask)
   with Export,
        Convention    => Ada,
        External_Name => "sys_irq_restore";

   irq_state : Adalin.l_irqmask := 16#ff#;

   function sys_irq_disable return Adalin.l_irqmask is
      rval : constant Adalin.l_irqmask := irq_state;
   begin
      irq_state := 0;
      return rval;
   end sys_irq_disable;

   procedure sys_irq_restore (State : Adalin.l_irqmask) is
   begin
      irq_state := State;
   end sys_irq_restore;

   procedure Test_Driver_Management (T : in out Test_Case'Class) is
      pragma Unreferenced (T);
   begin
      Adalin.l_sys_init;
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
      pragma Unreferenced (T);
      mask : constant Adalin.l_irqmask := Adalin.sys_irq_disable;
   begin
      Assert (mask = 16#ff#, "irqs weren't disabled");
      Assert (irq_state = 0, "irqs aren't disabled");
      Adalin.sys_irq_restore (mask);
      Assert (irq_state = mask, "irqs weren't restored");
   end Test_Interrupts;

end Tests.Adalin_Core;
