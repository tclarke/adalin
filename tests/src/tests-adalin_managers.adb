with AUnit.Assertions;
with Adalin.Slave;
with Adalin.Managers; use Adalin.Managers;

package body Tests.Adalin_Managers is

   overriding
   procedure Register_Tests (T : in out Test) is
      use Registration;
   begin
      Register_Routine
        (T,
         Tests.Adalin_Managers.Test_Irq_Manager'Access,
         "Test IRQ RAII Manager");
   end Register_Tests;

   overriding
   function Name (T : Test) return Message_String is
   begin
      return Format ("adaLIN RAII Managers Tests");
   end Name;

   --  Dummy slave for testing
   type Test_IrqState is new Adalin.Slave.IrqState with record
     state : Boolean := true;
   end record;

   type Test_Slave is new Adalin.Slave.Slave with record
      active : Boolean;
   end record;

   function sys_irq_disable (Self : in out Test_Slave) return Test_IrqState'Class
      State : Test_IrqState;
   begin
      State.state := Self.active;
      Self.active := false;
      return State'Class;
   end sys_irq_disable;

   procedure sys_irq_restore (Self : in out Test_Slave, State : Test_IrqState'Class) begin
      Self.state := State.state;
   end sys_irq_restore;

   --  Test the manager
   procedure Test_Irq_Manager (T : in out Test_Case'Class) is
      pragma Unreferenced (T);

      Slave : Adalin.Slave.Slave;
   begin
      AUnit.Assertions.Assert (Slave.state = true, "Precondition for slave state is false");

      declare
         mgr : Irq_Manager (Slave);
      begin
         AUnit.Assertions.Assert (Slave.state = false, "State didn't change");
      end
      AUnit.Assertions.Assert (Slave.state = true, "State wasn't restored");
   end Test_Irq_Manager;

end Tests.Adalin_Managers;
