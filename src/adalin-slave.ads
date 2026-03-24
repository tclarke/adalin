--  Adalin.Slave – Generic Abstract Data Machine for a LIN slave node.
--
--  Design overview
--  ───────────────
--  A LIN slave node owns a statically-sized Signal_Map that associates each
--  registered LIN PID with an abstract Signal_Entry.  The Signal_Map type
--  and its supporting abstract types (Signal_Entry, Signal_Entry_Access,
--  LIN_PID) now live in the parent package Adalin; Adalin.Slave uses the
--  map via composition inside Slave_Node.
--
--  Re-exported subtypes (LIN_PID, Signal_Entry, Signal_Entry_Access) let
--  existing client code continue to qualify names through the instance,
--  e.g. My_Slave.Signal_Entry, without change.
--
--  Generic formal
--  ──────────────
--    Capacity : Positive  –  compile-time upper bound on the number of
--                            PIDs registered with this slave.  Forwarded
--                            directly as the discriminant of the
--                            Adalin.Signal_Map component inside Slave_Node.
--
--  Usage sketch
--  ────────────
--    package My_Slave is new Adalin.Slave (Capacity => 4);
--
--    -- Derive Signal_Entry wrapper types and register entries:
--    My_Slave.Register (Node, PID, Entry'Access);
--
--    -- Driver look-up:
--    E := My_Slave.Get_Entry (Node, PID);

generic
   Capacity : Positive;

package Adalin.Slave is

   ---------------------------------------------------------------------------
   --  Re-export of key Adalin types so callers can qualify through the
   --  instance without adding a separate "with Adalin" / use clause.
   ---------------------------------------------------------------------------
   subtype LIN_PID             is Adalin.LIN_PID;
   subtype Signal_Entry        is Adalin.Signal_Entry;
   subtype Signal_Entry_Access is Adalin.Signal_Entry_Access;

   --  Re-export of the generic formal for runtime inspection.
   Max_Signals : constant Positive := Capacity;

   ---------------------------------------------------------------------------
   --  Slave_Node ADT
   --
   --  Embeds an Adalin.Signal_Map (Capacity) via composition.  All map
   --  operations are available directly on the node through the delegating
   --  subprograms below.
   ---------------------------------------------------------------------------
   type Slave_Node is tagged limited private;

   --  Register one signal entry under the given PID.  Delegates to
   --  Adalin.Register; raises Constraint_Error when the map is full or
   --  Entry_Ptr is null.
   procedure Register
     (Node      : in out Slave_Node;
      PID       : LIN_PID;
      Entry_Ptr : not null Signal_Entry_Access);

   --  Look up a signal by PID.  Returns null when not registered.
   function Get_Entry
     (Node : Slave_Node;
      PID  : LIN_PID) return Signal_Entry_Access;

   --  Return the number of signals currently registered.
   function Registered_Count (Node : Slave_Node) return Natural;

   --  True when Registered_Count = Capacity.
   function Is_Ready (Node : Slave_Node) return Boolean;

   ---------------------------------------------------------------------------
   --  IRQ call-out interface
   ---------------------------------------------------------------------------
   type IrqState is abstract tagged null record;

   type Slave is abstract tagged null record;

   function sys_irq_disable (Self : in out Slave)
      return IrqState'Class is abstract;

   procedure sys_irq_restore
     (Self  : in out Slave;
      State : IrqState'Class) is abstract;

private

   type Slave_Node is tagged limited record
      Map : Adalin.Signal_Map (Capacity);
   end record;

end Adalin.Slave;
