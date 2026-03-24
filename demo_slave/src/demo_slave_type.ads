--  Demo_Slave_Type
--
--  Concrete Adalin.Slave.Slave derivation for the demo node.
--  Derives from My_Slave.Slave (the instance declared in
--  Demo_Slave_Signals) so that the IRQ call-out interface and the
--  signal collection share the same Adalin.Slave instantiation.

with Demo_Slave_Signals;  --  owns My_Slave instantiation + signal objects

package Demo_Slave_Type is

   --  Bring the instance's namespace into scope for readability.
   package My_Slave renames Demo_Slave_Signals.My_Slave;

   type Interrupt_State is (Enabled, Disabled);

   --  Concrete slave: derives from the IRQ call-out root in My_Slave.
   type Demo_Slave_Type is new My_Slave.Slave with record
      irq : Interrupt_State := Enabled;  --  Simple on/off interrupt state
   end record;

   type DemoIrqState is new My_Slave.IrqState with record
      state : Interrupt_State;
   end record;

   overriding function sys_irq_disable
     (Self : in out Demo_Slave_Type) return My_Slave.IrqState'Class;

   overriding procedure sys_irq_restore
     (Self  : in out Demo_Slave_Type;
      State : My_Slave.IrqState'Class);

end Demo_Slave_Type;