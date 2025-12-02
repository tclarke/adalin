package Adalin.Slave is
   Slave_Initialization_Except : exception;

   --  Base class for slave nodes.
   --  The interface is loosely based on the official API.
   --  That API is required for C based implementations but other
   --  languages are not standardized. That said, it's a good idea
   --  to stay close to the C API.
   type Slave is abstract tagged null record;

   type IrqState is tagged null record;

   function sys_irq_disable (Self : in out Slave) return IrqState'Class is abstract;
   procedure sys_irq_restore (Self : in out Slave;
		State : IrqState'Class) is abstract;

end Adalin.Slave;
