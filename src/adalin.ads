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
   --  LIN PID type (8-bit protected identifier, A2.3.1.3 of LIN 2.2A spec).
   ---------------------------------------------------------------------------
   subtype LIN_PID is Interfaces.Unsigned_8;

   ---------------------------------------------------------------------------
   --  Raw frame buffer used to pass received bytes into Signal_Entry.
   --  Matches the LIN maximum of 8 data bytes (spec sec 2.3.1.4).
   ---------------------------------------------------------------------------
   Max_Frame_Bytes : constant := 8;
   subtype Frame_Byte_Index is Natural range 0 .. Max_Frame_Bytes - 1;
   type Raw_Frame_Bytes is
     array (Frame_Byte_Index) of Interfaces.Unsigned_8;

   ---------------------------------------------------------------------------
   --  Signal_Entry - abstract interface that wraps one Adalin.Signal
   --  instance of any value type.  External packages derive from this type
   --  and override all abstract operations.
   ---------------------------------------------------------------------------
   type Signal_Entry is abstract tagged limited null record;
   type Signal_Entry_Access is access all Signal_Entry'Class;

   --  Return the LIN PID this entry is associated with.
   function Get_PID (E : Signal_Entry) return LIN_PID is abstract;

   --  True when the underlying signal has been written since the last
   --  Clear_Updated call (LIN 2.2A A2.3.3.2-3 "updated" flag).
   function Is_Updated (E : Signal_Entry) return Boolean is abstract;

   --  Clear the updated flag once the driver has consumed the value.
   procedure Clear_Updated (E : in out Signal_Entry) is abstract;

   --  Called by l_ifc_rx after a subscribe frame is received and its
   --  checksum is verified.  Buf holds N raw bytes (little-endian per
   --  LIN 2.2A sec 2.3.1.4) that the entry should decode and store.
   procedure Receive_Bytes
     (E   : in out Signal_Entry;
      Buf : Raw_Frame_Bytes;
      N   : Positive) is abstract;

   --  Called by l_ifc_tx to fill Buf with the N raw bytes that should
   --  be transmitted for a publish frame (little-endian encoding).
   procedure Transmit_Bytes
     (E   : Signal_Entry;
      Buf : out Raw_Frame_Bytes;
      N   : Positive) is abstract;

   ---------------------------------------------------------------------------
   --  Signal_Map - discriminated private record.
   ---------------------------------------------------------------------------
   type Signal_Map (Capacity : Positive) is private;

   --  Register one signal entry under the given PID.
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

   --  True when Registered_Count = Capacity.
   function Is_Ready (Map : Signal_Map) return Boolean;

   ---------------------------------------------------------------------------
   --  Mask / trim helpers
   ---------------------------------------------------------------------------

   function U8_Mask
     (V : l_u8; Bits : Positive) return l_u8 is
     (l_u8 (Integer (V) mod 2 ** Bits));

   function U8_Identity
     (V : l_u8; Unused_Bytes : Positive) return l_u8 is
     (V);

   function U16_Mask
     (V : l_u16; Bits : Positive) return l_u16 is
     (l_u16 (Integer (V) mod 2 ** Bits));

   function U16_Identity
     (V : l_u16; Unused_Bytes : Positive) return l_u16 is
     (V);

   function Array_Trim
     (V     : l_byte_array;
      Bytes : Positive) return l_byte_array is
     ([for I in l_array_index =>
         (if Natural (I) < Bytes then V (I) else 0)]);

   function Array_Identity
     (V           : l_byte_array;
      Unused_Bits : Positive) return l_byte_array is
     (V);

   ---------------------------------------------------------------------------
   --  Core API
   ---------------------------------------------------------------------------
   procedure l_sys_init;

   function l_rd (sig : l_signal_handle) return l_bool;
   function l_rd (sig : l_signal_handle) return l_u8;
   function l_rd (sig : l_signal_handle) return l_u16;
   function l_rd (sig : l_signal_handle) return l_byte_array;

   procedure l_wr (sig : l_signal_handle; val : l_bool);
   procedure l_wr (sig : l_signal_handle; val : l_u8);
   procedure l_wr (sig : l_signal_handle; val : l_u16);
   procedure l_wr (sig : l_signal_handle; val : l_byte_array);

   function  l_flg_tst (flag : l_flag_handle) return l_bool;
   procedure l_flg_clr (flag : l_flag_handle);

   procedure l_ifc_init     (iii : l_ifc_handle);
   procedure l_ifc_wake_up  (iii : l_ifc_handle);
   procedure l_ifc_rx       (iii : l_ifc_handle);
   procedure l_ifc_tx       (iii : l_ifc_handle);

   function sys_irq_disable return l_irqmask
   with
      Import,
      Convention    => Ada,
      External_Name => "sys_irq_disable";

   procedure sys_irq_restore (State : l_irqmask)
   with
      Import,
      Convention    => Ada,
      External_Name => "sys_irq_restore";

private

   type Signal_Map_Entry is record
      PID       : LIN_PID             := 0;
      Entry_Ptr : Signal_Entry_Access := null;
   end record;

   type Signal_Map_Entry_Array is
     array (Natural range <>) of Signal_Map_Entry;

   type Signal_Map (Capacity : Positive) is record
      Entries : Signal_Map_Entry_Array (1 .. Capacity);
      Count   : Natural := 0;
   end record;

end Adalin;
