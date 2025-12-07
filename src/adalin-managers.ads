with Ada.Finalization;
with Adalin.Slave;

package Adalin.Managers is
   type Irq_Manager (Obj : not null Adalin.Slave.Slave'Class)
      is tagged limited private;

   type State is tagged null record;

private
   type Irq_Manager (Obj : not null Adalin.Slave.Slave'Class)
      is new Ada.Finalization.Limited_Controlled with record
         state : Adalin.Slave.IrqState'Class;
         slave : Adalin.Slave.Slave'Class;
   end record;

   overriding
   procedure Initialize (Self : in out Irq_Manager);

   overriding
   procedure Finalize (Self : in out Irq_Manager);
end Adalin.Managers;
