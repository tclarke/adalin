with Interfaces;

package Adalin is
   --  The interface is loosely based on the official API.
   --  That API is required for C based implementations but other
   --  languages are not standardized. That said, it's a good idea
   --  to stay close to the C API.

   --  Types from the LIN2.1 spec.
   subtype l_irqmask is Interfaces.Unsigned_16;
   subtype l_signal_handle is Natural range 0 .. 255;
   subtype l_flag_handle is Natural range 0 .. 255;
   subtype l_ifc_handle is Natural range 0 .. 255;

   subtype l_bool is Boolean;
   type l_u8 is range 0 .. 2 ** 8 - 1;
   type l_u16 is range 0 .. 2 ** 16 - 1;

   type l_array_index is range 0 .. 7;

   type l_byte_array is array (l_array_index) of l_u8;

   type Core_Interface is interface;

   --  Core API
   --  Driver and cluster management
   --  Initialize the LIN core;
   function l_sys_init (T : in out Core_Interface) return l_bool is abstract;

   --  Signal interaction
   --  Scalar signal read
   function l_rd (T : in out Core_Interface; sig : l_signal_handle) return l_bool is abstract;
   function l_rd (T : in out Core_Interface; sig : l_signal_handle) return l_u8 is abstract;
   function l_rd (T : in out Core_Interface; sig : l_signal_handle) return l_u16 is abstract;

   --  Scalar signal write
   procedure l_wr (T : in out Core_Interface; sig : l_signal_handle; val : l_bool) is abstract;
   procedure l_wr (T : in out Core_Interface; sig : l_signal_handle; val : l_u8) is abstract;
   procedure l_wr (T : in out Core_Interface; sig : l_signal_handle; val : l_u16) is abstract;

   --  Byte array read
   function l_rd (T : in out Core_Interface; sig : l_signal_handle) return l_byte_array is abstract;

   --  Byte array write
   procedure l_wr (T : in out Core_Interface; sig : l_signal_handle; val : l_byte_array) is abstract;

   --  Notification
   --  Test if a flag is set
   function l_flg_tst (T : in out Core_Interface; flag : l_flag_handle) return l_bool is abstract;

   --  Clear a flag
   procedure l_flg_clr (T : in out Core_Interface; flag : l_flag_handle) is abstract;

   --  Interface management
   --  Initialize the interface
   function l_ifc_init (T : in out Core_Interface; iii : l_ifc_handle) return l_bool is abstract;

   --  Transmit one wakeup signal
   procedure l_ifc_wake_up (T : in out Core_Interface; iii : l_ifc_handle) is abstract;

   --  User provided call-outs
   --  Disable interrupts
   function sys_irq_disable (T : in out Core_Interface) return l_irqmask is abstract;

   --  Restore interrupts from mask that was returned from sys_irq_disable
   procedure sys_irq_restore (T : in out Core_Interface; State : l_irqmask) is abstract;

end Adalin;
