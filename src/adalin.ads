with Interfaces;
use type Interfaces.Unsigned_8;

package Adalin is
   --  The interface is loosely based on the official LIN 2.2A API.
   --  We stay close to the standard C names while using Ada features
   --  where they improve clarity.

   --  Types from the LIN 2.2A spec.
   subtype l_irqmask      is Interfaces.Unsigned_16;
   subtype l_signal_handle is Natural range 0 .. 255;
   subtype l_flag_handle   is Natural range 0 .. 255;
   subtype l_ifc_handle    is Natural range 0 .. 255;
   subtype l_bool          is Boolean;
   type l_u8  is range 0 .. 2 ** 8  - 1;
   type l_u16 is range 0 .. 2 ** 16 - 1;
   type l_array_index is range 0 .. 7;
   type l_byte_array  is array (l_array_index) of l_u8;

   --  The default interface.
   i_ifc_default : constant l_ifc_handle := 0;

   --  Exception definitions
   Sys_Init_Error : exception;
   Ifc_Init_Error : exception;

   ---------------------------------------------------------------------------
   --  LIN PID type (8-bit protected identifier, §2.3.1.3 of LIN 2.2A spec).
   ---------------------------------------------------------------------------
   subtype LIN_PID is Interfaces.Unsigned_8;

   ---------------------------------------------------------------------------
   --  Signal_Entry – abstract interface that wraps one Adalin.Signal
   --  instance of any value type.  External packages derive from this type
   --  and override all three abstract operations.
   ---------------------------------------------------------------------------
   type Signal_Entry is abstract tagged limited null record;
   type Signal_Entry_Access is access all Signal_Entry'Class;

   --  Return the LIN PID this entry is associated with.
   function Get_PID (E : Signal_Entry) return LIN_PID is abstract;

   --  True when the underlying signal has been written since the last
   --  Clear_Updated call (LIN 2.2A §2.3.3.2-3 "updated" flag).
   function Is_Updated (E : Signal_Entry) return Boolean is abstract;

   --  Clear the updated flag once the driver has consumed the value.
   procedure Clear_Updated (E : in out Signal_Entry) is abstract;

   ---------------------------------------------------------------------------
   --  Signal_Map – discriminated private record.
   --
   --  The discriminant Capacity fixes the maximum number of PID→signal
   --  mappings at compile-time so no heap allocation is ever needed.
   --  Compose Signal_Map into any node record that needs a signal map;
   --  use the four operations below to manipulate it.
   ---------------------------------------------------------------------------
   type Signal_Map (Capacity : Positive) is private;

   --  Register one signal entry under the given PID.
   --  Raises Constraint_Error if called more than Capacity times or if
   --  Entry_Ptr is null.
   procedure Register
     (Map       : in out Signal_Map;
      PID       : LIN_PID;
      Entry_Ptr : not null Signal_Entry_Access);

   --  Look up a signal by its PID.  Returns null when not registered.
   function Get_Entry
     (Map : Signal_Map;
      PID : LIN_PID) return Signal_Entry_Access;

   --  Return the number of signals currently registered in the map.
   function Registered_Count (Map : Signal_Map) return Natural;

   --  True when Registered_Count = Capacity (map is fully populated).
   function Is_Ready (Map : Signal_Map) return Boolean;

   ---------------------------------------------------------------------------
   --  Core API – driver and cluster management
   ---------------------------------------------------------------------------
   procedure l_sys_init;

   --  Scalar and byte-array signal read.
   function l_rd (sig : l_signal_handle) return l_bool;
   function l_rd (sig : l_signal_handle) return l_u8;
   function l_rd (sig : l_signal_handle) return l_u16;
   function l_rd (sig : l_signal_handle) return l_byte_array;

   --  Scalar and byte-array signal write.
   procedure l_wr (sig : l_signal_handle; val : l_bool);
   procedure l_wr (sig : l_signal_handle; val : l_u8);
   procedure l_wr (sig : l_signal_handle; val : l_u16);
   procedure l_wr (sig : l_signal_handle; val : l_byte_array);

   --  Notification
   function  l_flg_tst (flag : l_flag_handle) return l_bool;
   procedure l_flg_clr (flag : l_flag_handle);

   --  Interface management
   procedure l_ifc_init     (iii : l_ifc_handle);
   procedure l_ifc_wake_up  (iii : l_ifc_handle);

   --  Called from an ISR or task context when one byte has been received
   --  on interface iii (UART-based: once per character; hardware LIN: once
   --  per complete frame).  Drives the LIN receive state machine.
   procedure l_ifc_rx (iii : l_ifc_handle);

   --  Called from an ISR or task context when interface iii is ready to
   --  accept the next transmit byte.  Drives the LIN transmit state machine.
   procedure l_ifc_tx (iii : l_ifc_handle);

   --  User-provided call-outs -----------------------------------------------
   --  Disable interrupts; returns the current mask so it can be restored.
   function sys_irq_disable return l_irqmask
   with
      Import,
      Convention    => Ada,
      External_Name => "sys_irq_disable";

   --  Restore interrupts from the mask returned by sys_irq_disable.
   procedure sys_irq_restore (State : l_irqmask)
   with
      Import,
      Convention    => Ada,
      External_Name => "sys_irq_restore";

private

   ---------------------------------------------------------------------------
   --  Full definition of Signal_Map.
   --
   --  Signal_Map_Entry pairs a PID with an access to its Signal_Entry.
   --  Both components carry explicit defaults (PID => 0, Entry_Ptr => null),
   --  so all Entries array elements are default-initialized automatically
   --  per ARM 3.3.1(20): an array component is initialized when its element
   --  type has a default_expression for any subcomponent.
   ---------------------------------------------------------------------------
   type Signal_Map_Entry is record
      PID       : LIN_PID             := 0;
      Entry_Ptr : Signal_Entry_Access := null;
   end record;

   type Signal_Map_Entry_Array is
     array (Natural range <>) of Signal_Map_Entry;

   --  Capacity is a discriminant, so the Entries array is statically
   --  sized to exactly Capacity elements.  Count tracks how many have
   --  been filled by Register calls.
   type Signal_Map (Capacity : Positive) is record
      Entries : Signal_Map_Entry_Array (1 .. Capacity);
      Count   : Natural := 0;
   end record;

end Adalin;
