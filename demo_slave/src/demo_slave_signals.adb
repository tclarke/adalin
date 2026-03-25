--  Demo_Slave_Signals - body
--
--  Only Initialize_Node lives here; the Signal instantiations and
--  Signal_Entry primitives are defined in the Adalin.Signals package.

package body Demo_Slave_Signals is

   procedure Initialize_Node is
   begin
      My_Slave.Register
        (My_Node, Engine_Speed_Entry.PID, Engine_Speed_Entry'Access);
      My_Slave.Register
        (My_Node, Battery_Voltage_Entry.PID, Battery_Voltage_Entry'Access);
      My_Slave.Register
        (My_Node, Sensor_Bytes_Entry.PID, Sensor_Bytes_Entry'Access);
   end Initialize_Node;

end Demo_Slave_Signals;
