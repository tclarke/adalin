with Adalin.Slave;
use Adalin.Slave;

package Demo_Slave_Type is

   type Demo_Slave_Type is new Slave with record
      irq_state : Boolean := True;
   end record;

   overriding
   procedure sys_irq_disable (Self : in out Demo_Slave_Type);

end Demo_Slave_Type;