with Simple_Logging;
use Simple_Logging;

with Demo_Slave_Type;

procedure Demo_Slave is
   slave : Demo_Slave_Type.Demo_Slave_Type;
begin
   Log ("Demo_Slave started.");
   slave.sys_irq_disable;
   Log ("Demo_Slave ended.");
end Demo_Slave;
