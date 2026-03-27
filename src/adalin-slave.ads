--  Adalin.Slave - Generic abstract data machine for a LIN slave node.
--
--  Design overview
--  ---------------
--  A LIN slave node owns a statically-sized signal map that associates each
--  registered LIN PID with an abstract Signal_Entry.
--
--  State machine (l_ifc_rx)
--  ------------------------
--  Each call to l_ifc_rx advances the per-node receive state machine by one
--  byte.  The states follow the LIN 2.2A frame structure (sec 2.3.1):
--
--    Idle          - waiting for the sync byte (0x55).
--    Recv_Sync     - 0x55 seen; next byte is the PID.
--    Recv_PID      - PID received; validated and looked up.
--                      Subscribe match -> Recv_Data
--                      Publish  match  -> Tx_Data
--                      No match        -> Idle
--    Recv_Data     - accumulate data bytes (subscribe frame).
--    Tx_Data       - slave is publisher; count echoed bytes (publish frame).
--    Recv_Checksum - validate checksum; commit data for subscribe frames.
--
--  Generic formal
--  --------------
--    Capacity : Positive  -  max number of PIDs registered with this slave.

with Interfaces;

generic
   Capacity : Positive;

package Adalin.Slave is

   ---------------------------------------------------------------------------
   --  Re-export of key Adalin types.
   ---------------------------------------------------------------------------
   subtype LIN_PID             is Adalin.LIN_PID;
   subtype Signal_Entry        is Adalin.Signal_Entry;
   subtype Signal_Entry_Access is Adalin.Signal_Entry_Access;

   Max_Signals : constant Positive := Capacity;

   ---------------------------------------------------------------------------
   --  Frame direction from the slave's point of view (LIN 2.2A sec 2.3.3).
   ---------------------------------------------------------------------------
   type Frame_Direction is (Subscribe, Publish);

   ---------------------------------------------------------------------------
   --  Rx/Tx state machine states.
   ---------------------------------------------------------------------------
   type Slave_State is
     (Idle,
      Recv_Sync,
      Recv_PID,
      Recv_Data,
      Tx_Data,
      Recv_Checksum);

   ---------------------------------------------------------------------------
   --  Slave_Node ADT
   ---------------------------------------------------------------------------
   type Slave_Node is tagged limited private;

   --  Register one signal entry.
   --  Dir:       Subscribe | Publish (from the slave's point of view).
   --  Num_Bytes: number of data bytes for this frame.
   procedure Register
     (Node      : in out Slave_Node;
      PID       : LIN_PID;
      Entry_Ptr : not null Signal_Entry_Access;
      Dir       : Frame_Direction;
      Num_Bytes : Positive)
   with Pre => Num_Bytes <= Max_Frame_Bytes;

   function Get_Entry
     (Node : Slave_Node;
      PID  : LIN_PID) return Signal_Entry_Access;

   function Registered_Count (Node : Slave_Node) return Natural;

   function Is_Ready (Node : Slave_Node) return Boolean;

   --  Current state-machine state (for diagnostics).
   function Current_State (Node : Slave_Node) return Slave_State;

   ---------------------------------------------------------------------------
   --  l_ifc_rx
   --
   --  Called from the UART RX ISR once per received byte.
   --  Drives the LIN slave receive state machine (LIN 2.2A API sec 7.2.5.5).
   ---------------------------------------------------------------------------
   procedure l_ifc_rx
     (Node : in out Slave_Node;
      Byte : Interfaces.Unsigned_8);

   ---------------------------------------------------------------------------
   --  IRQ call-out interface
   ---------------------------------------------------------------------------
   type IrqState is abstract tagged null record;
   type Slave    is abstract tagged null record;

   function sys_irq_disable (Self : in out Slave)
      return IrqState'Class is abstract;

   procedure sys_irq_restore
     (Self  : in out Slave;
      State : IrqState'Class) is abstract;

private

   type Slave_Map_Entry is record
      PID       : LIN_PID             := 0;
      Entry_Ptr : Signal_Entry_Access := null;
      Dir       : Frame_Direction     := Subscribe;
      Num_Bytes : Positive            := 1;
   end record;

   type Slave_Map_Array is array (Natural range <>) of Slave_Map_Entry;

   type Slave_Node is tagged limited record
      Entries        : Slave_Map_Array  (1 .. Capacity);
      Count          : Natural          := 0;
      State          : Slave_State      := Idle;
      Current_PID    : LIN_PID          := 0;
      Current_Dir    : Frame_Direction  := Subscribe;
      Bytes_Expected : Positive         := 1;
      Bytes_Done     : Natural          := 0;
      Rx_Buf         : Raw_Frame_Bytes  := [others => 0];
      Matched_Entry  : Signal_Entry_Access := null;
   end record;

end Adalin.Slave;