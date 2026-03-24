--  Demo_Slave_Signals
--
--  This package owns the concrete Adalin.Signal instances for the demo
--  slave node and registers them with the Adalin.Slave.Slave_Node ADT.
--
--  Responsibilities:
--    1. Instantiate Adalin.Signal for each LIN value type needed.
--    2. Derive concrete Signal_Entry types that wrap those instantiations.
--    3. Expose the Slave_Node instance (My_Node) that the rest of the
--       application (and the driver) can query via Get_Entry.
--
--  The collection is fully static: no heap allocation is involved.
--  Adalin.Slave is instantiated with Capacity => 3, matching the three
--  signals declared here.

with Adalin.Signal;
with Adalin.Slave;

package Demo_Slave_Signals is

   --  -----------------------------------------------------------------------
   --  Step 1 – Instantiate Adalin.Slave for this node's signal count.
   --  -----------------------------------------------------------------------
   package My_Slave is new Adalin.Slave (Capacity => 3);

   --  -----------------------------------------------------------------------
   --  Step 2 – Instantiate Adalin.Signal for the value types we need.
   --  -----------------------------------------------------------------------

   --  Helper mask/trim functions required by the Adalin.Signal generic.
   function U8_Mask (V : Adalin.l_u8; Bits : Positive) return Adalin.l_u8;
   function U8_Identity
     (V : Adalin.l_u8; Bytes : Positive) return Adalin.l_u8;

   function U16_Mask (V : Adalin.l_u16; Bits : Positive) return Adalin.l_u16;
   function U16_Identity
     (V : Adalin.l_u16; Bytes : Positive) return Adalin.l_u16;

   function Array_Trim
     (V     : Adalin.l_byte_array;
      Bytes : Positive) return Adalin.l_byte_array;
   function Array_Identity
     (V    : Adalin.l_byte_array;
      Bits : Positive) return Adalin.l_byte_array;

   package U8_Signal is new Adalin.Signal
     (Value_Type    => Adalin.l_u8,
      Is_Array_Type => False,
      Mask_Bits     => U8_Mask,
      Trim_Bytes    => U8_Identity);

   package U16_Signal is new Adalin.Signal
     (Value_Type    => Adalin.l_u16,
      Is_Array_Type => False,
      Mask_Bits     => U16_Mask,
      Trim_Bytes    => U16_Identity);

   package Arr_Signal is new Adalin.Signal
     (Value_Type    => Adalin.l_byte_array,
      Is_Array_Type => True,
      Mask_Bits     => Array_Identity,
      Trim_Bytes    => Array_Trim);

   --  -----------------------------------------------------------------------
   --  Step 3 – Concrete Signal_Entry wrappers (one per value type in use).
   --  -----------------------------------------------------------------------

   --  Wrapper for a U8_Signal.Signal
   type U8_Signal_Entry is new My_Slave.Signal_Entry with record
      PID : My_Slave.LIN_PID;
      Sig : U8_Signal.Signal;
   end record;

   overriding function Get_PID    (E : U8_Signal_Entry) return My_Slave.LIN_PID;
   overriding function Is_Updated (E : U8_Signal_Entry) return Boolean;
   overriding procedure Clear_Updated (E : in out U8_Signal_Entry);

   --  Convenience: read/write the wrapped signal value directly.
   function  Get_Value (E : U8_Signal_Entry) return Adalin.l_u8;
   procedure Set_Value (E : in out U8_Signal_Entry; Value : Adalin.l_u8);

   --  Wrapper for a U16_Signal.Signal
   type U16_Signal_Entry is new My_Slave.Signal_Entry with record
      PID : My_Slave.LIN_PID;
      Sig : U16_Signal.Signal;
   end record;

   overriding function Get_PID    (E : U16_Signal_Entry) return My_Slave.LIN_PID;
   overriding function Is_Updated (E : U16_Signal_Entry) return Boolean;
   overriding procedure Clear_Updated (E : in out U16_Signal_Entry);

   function  Get_Value (E : U16_Signal_Entry) return Adalin.l_u16;
   procedure Set_Value (E : in out U16_Signal_Entry; Value : Adalin.l_u16);

   --  Wrapper for an Arr_Signal.Signal
   type Arr_Signal_Entry is new My_Slave.Signal_Entry with record
      PID : My_Slave.LIN_PID;
      Sig : Arr_Signal.Signal;
   end record;

   overriding function Get_PID    (E : Arr_Signal_Entry) return My_Slave.LIN_PID;
   overriding function Is_Updated (E : Arr_Signal_Entry) return Boolean;
   overriding procedure Clear_Updated (E : in out Arr_Signal_Entry);

   function  Get_Value (E : Arr_Signal_Entry) return Adalin.l_byte_array;
   procedure Set_Value (E : in out Arr_Signal_Entry; Value : Adalin.l_byte_array);

   --  -----------------------------------------------------------------------
   --  Step 4 – Concrete signal objects (stored here, never on the heap).
   --           PID values are illustrative; replace with real LDF values.
   --  -----------------------------------------------------------------------

   --  PID 0x21 – engine speed (8-bit scalar, 8 bits wide)
   Engine_Speed_Entry : aliased U8_Signal_Entry :=
     (PID => 16#21#,
      Sig => U8_Signal.Make
               (Handle        => 0,
                Name          => "EngineSpeed" & (12 .. 64 => ' '),
                Default_Value => 0,
                Size          => 8));

   --  PID 0x22 – battery voltage (16-bit scalar, 16 bits wide)
   Battery_Voltage_Entry : aliased U16_Signal_Entry :=
     (PID => 16#22#,
      Sig => U16_Signal.Make
               (Handle        => 1,
                Name          => "BatteryVoltage" & (15 .. 64 => ' '),
                Default_Value => 0,
                Size          => 16));

   --  PID 0x23 – sensor bytes (byte array, 4 active bytes)
   Sensor_Bytes_Entry : aliased Arr_Signal_Entry :=
     (PID => 16#23#,
      Sig => Arr_Signal.Make
               (Handle        => 2,
                Name          => "SensorBytes" & (12 .. 64 => ' '),
                Default_Value => (others => 0),
                Size          => 4));

   --  -----------------------------------------------------------------------
   --  Step 5 – The Slave_Node instance shared with the rest of the system.
   --  -----------------------------------------------------------------------
   My_Node : My_Slave.Slave_Node;

   --  Called once during elaboration (or explicitly) to populate My_Node.
   procedure Initialize_Node;

end Demo_Slave_Signals;
