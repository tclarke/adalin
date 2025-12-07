package body Adalin.Managers is
   overriding
   procedure Initialize (Self : in out Irq_Manager) is
   begin
      Self.state := Self.Obj.sys_irq_disable;
      Self.slave := Self.Obj;
   end Initialize;

   overriding
   procedure Finalize (Self : in out Irq_Manager) is
   begin
      Self.slave.sys_irq_restore (Self.state);
   end Finalize;
end Adalin.Managers;
