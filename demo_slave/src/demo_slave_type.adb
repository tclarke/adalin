with Simple_Logging; use Simple_Logging;

package body Demo_Slave_Type is
   overriding function sys_irq_disable (Self : in out Demo_Slave_Type)
      return IrqState'Class is

      save : constant DemoIrqState := (state => Self.irq);
   begin
      Log ("Demo_Slave_Type.sys_irq_disable");
      Self.irq := Disabled;
      return save;
   end sys_irq_disable;

   overriding procedure sys_irq_restore (Self : in out Demo_Slave_Type;
         State : IrqState'Class) is
      LState : DemoIrqState renames DemoIrqState (State);
   begin
      Log ("Demo_Slave_Type.sys_irq_restore");
      Self.irq := LState.state;
   end sys_irq_restore;
end Demo_Slave_Type;
