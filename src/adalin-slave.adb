--  Adalin.Slave – body
--
--  All Slave_Node operations are thin delegations to the Signal_Map
--  operations defined in the parent package Adalin.

package body Adalin.Slave is

   procedure Register
     (Node      : in out Slave_Node;
      PID       : LIN_PID;
      Entry_Ptr : not null Signal_Entry_Access)
   is
   begin
      Adalin.Register (Node.Map, PID, Entry_Ptr);
   end Register;

   function Get_Entry
     (Node : Slave_Node;
      PID  : LIN_PID) return Signal_Entry_Access
   is
   begin
      return Adalin.Get_Entry (Node.Map, PID);
   end Get_Entry;

   function Registered_Count (Node : Slave_Node) return Natural is
   begin
      return Adalin.Registered_Count (Node.Map);
   end Registered_Count;

   function Is_Ready (Node : Slave_Node) return Boolean is
   begin
      return Adalin.Is_Ready (Node.Map);
   end Is_Ready;

end Adalin.Slave;
