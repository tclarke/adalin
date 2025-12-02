with Adalin.Slave;
with Demo_Slave_Type;
with Simple_Logging; use Simple_Logging;

procedure Demo_Slave is
   demo_obj : aliased Demo_Slave_Type.Demo_Slave_Type;
   slave_access : access Adalin.Slave.Slave'Class := demo_obj'Access;

   procedure critical is
      irq : constant Adalin.Slave.IrqState'Class
         := slave_access.sys_irq_disable;
   begin
      Log ("In critical sub-program: " & demo_obj.irq'Image);
      slave_access.sys_irq_restore (irq);
   end critical;
begin
   Log ("Demo_Slave started: " & demo_obj.irq'Image);
   critical;
   Log ("Demo_Slave ended: " & demo_obj.irq'Image);
end Demo_Slave;
