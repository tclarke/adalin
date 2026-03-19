with Interfaces;

package Adalin is
   --  The interface is loosely based on the official API.
   --  That API is required for C based implementations but other
   --  languages are not standardized. That said, it's a good idea
   --  to stay close to the C API.
   --  We'll use some ada features to make the interface nicer but stick with
   --  the standard names, etc.

   --  Types from the LIN2.1 spec.
   --  Currently support up to 16 IRQs in the mast,
   --  and a max of 256 signaks, flags, and interfaces.
   subtype l_irqmask is Interfaces.Unsigned_16;
   subtype l_signal_handle is Natural range 0 .. 255;
   subtype l_flag_handle is Natural range 0 .. 255;
   subtype l_ifc_handle is Natural range 0 .. 255;
   subtype l_bool is Boolean;
   type l_u8 is range 0 .. 2 ** 8 - 1;
   type l_u16 is range 0 .. 2 ** 16 - 1;
   type l_array_index is range 0 .. 7;
   type l_byte_array is array (l_array_index) of l_u8;

   --  The default interface. Implementations can allow more.
   i_ifc_default : constant l_ifc_handle := 0;

   --  Exception definitions
   Sys_Init_Error : exception;
   Ifc_Init_Error : exception;

   --  Core API
   --  Driver and cluster management
   --  Initialize the LIN core;
   procedure l_sys_init;

   --  Signal interaction
   --  Scalar and byte array signal read
   function l_rd (sig : l_signal_handle) return l_bool;
   function l_rd (sig : l_signal_handle) return l_u8;
   function l_rd (sig : l_signal_handle) return l_u16;
   function l_rd (sig : l_signal_handle) return l_byte_array;

   --  Scalar and byte array signal write
   procedure l_wr (sig : l_signal_handle; val : l_bool);
   procedure l_wr (sig : l_signal_handle; val : l_u8);
   procedure l_wr (sig : l_signal_handle; val : l_u16);
   procedure l_wr (sig : l_signal_handle; val : l_byte_array);

   --  Notification
   --  Test if a flag is set
   function l_flg_tst (flag : l_flag_handle) return l_bool;

   --  Clear a flag
   procedure l_flg_clr (flag : l_flag_handle);

   --  Interface management
   --  Initialize the interface
   procedure l_ifc_init (iii : l_ifc_handle);

   --  Transmit one wakeup signal
   procedure l_ifc_wake_up (iii : l_ifc_handle);

   --  User provided call-outs
   --  Disable interrupts
   function sys_irq_disable return l_irqmask
   with
      Import,
      Convention    => Ada,
      External_Name => "sys_irq_disable";

   --  Restore interrupts from mask that was returned from sys_irq_disable
   procedure sys_irq_restore (State : l_irqmask)
   with
      Import,
      Convention    => Ada,
      External_Name => "sys_irq_restore";
end Adalin;
