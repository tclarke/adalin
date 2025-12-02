with Adalin.Slave; use Adalin.Slave;

--  Implement a dummy Adalin.Slave which logs profusely and shows usage
package Demo_Slave_Type is
   type Interrupt_State is (Enabled, Disabled);

   type Demo_Slave_Type is new Slave with record
      irq : Interrupt_State := Enabled;  --  Simple on/off iterrupt state
   end record;

   type DemoIrqState is new IrqState with record
      state : Interrupt_State;
   end record;

   overriding function sys_irq_disable (Self : in out Demo_Slave_Type)
      return IrqState'Class;
   overriding procedure sys_irq_restore (Self : in out Demo_Slave_Type;
      State : IrqState'Class);
end Demo_Slave_Type;