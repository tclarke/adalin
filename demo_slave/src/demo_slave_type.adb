with Simple_Logging; use Simple_Logging;

package body Demo_Slave_Type is

   overriding
   procedure sys_irq_disable (Self : in out Demo_Slave_Type) is
   begin
      --  Implementation of IRQ disable for Demo_Slave
      Log ("IRQ disabled for Demo_Slave.");
   end sys_irq_disable;

end Demo_Slave_Type;
