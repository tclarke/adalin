--  Demo_Slave_Signals
--
--  Owns the concrete Adalin.Signal instances for the demo slave node and
--  registers them with the Adalin.Slave.Slave_Node ADT.
--
--  Layout
--  ------
--  1. Instantiate Adalin.Slave (Capacity => 3) as My_Slave.
--  2. Declare mask/trim helpers as expression functions (defined here so
--     they are available during spec elaboration when Make is called).
--  3. Instantiate Adalin.Signal for each LIN value type in use.
--  4. Derive concrete Signal_Entry wrapper types.
--  5. Declare the three static signal objects (no heap allocation).
--  6. Expose My_Node : My_Slave.Slave_Node and Initialize_Node.

with Adalin;
with Adalin.Signal;
with Adalin.Slave;

package Demo_Slave_Signals is

   ---------------------------------------------------------------------------
   --  1. Slave instantiation
   ---------------------------------------------------------------------------
   package My_Slave is new Adalin.Slave (Capacity => 3);

   ---------------------------------------------------------------------------
   --  2. Mask / trim helpers – expression functions so they are visible
   --     during spec elaboration (signal object initialisers call Make,
   --     which calls Constrain, which dispatches to these functions).
   --
   --  l_u8 / l_u16 are signed range types; masking is done with mod.
   --  Array_Trim uses an Ada 2022 iterated component association.
   ---------------------------------------------------------------------------

   function U8_Mask
     (V : Adalin.l_u8; Bits : Positive) return Adalin.l_u8 is
     (Adalin.l_u8 (Integer (V) mod 2 ** Bits));

   function U8_Identity
     (V : Adalin.l_u8; Unused_Bytes : Positive) return Adalin.l_u8 is
     (V);  --  Unused_Bytes is a required stub parameter

   function U16_Mask
     (V : Adalin.l_u16; Bits : Positive) return Adalin.l_u16 is
     (Adalin.l_u16 (Integer (V) mod 2 ** Bits));

   function U16_Identity
     (V : Adalin.l_u16; Unused_Bytes : Positive) return Adalin.l_u16 is
     (V);  --  Unused_Bytes is a required stub parameter

   --  Zero-fill elements at index >= Bytes; preserve [0 .. Bytes-1].
   function Array_Trim
     (V     : Adalin.l_byte_array;
      Bytes : Positive) return Adalin.l_byte_array is
     ([for I in Adalin.l_array_index =>
         (if Natural (I) < Bytes then V (I) else 0)]);

   function Array_Identity
     (V           : Adalin.l_byte_array;
      Unused_Bits : Positive) return Adalin.l_byte_array is
     (V);  --  Unused_Bits is a required stub parameter

   ---------------------------------------------------------------------------
   --  3. Adalin.Signal instantiations
   ---------------------------------------------------------------------------
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

   ---------------------------------------------------------------------------
   --  4. Concrete Signal_Entry wrapper types
   ---------------------------------------------------------------------------

   --  Wraps a U8_Signal.Signal; associated with an 8-bit scalar PID.
   type U8_Signal_Entry is new My_Slave.Signal_Entry with record
      PID : My_Slave.LIN_PID;
      Sig : U8_Signal.Signal;
   end record;

   overriding function Get_PID
     (E : U8_Signal_Entry) return My_Slave.LIN_PID;
   overriding function Is_Updated
     (E : U8_Signal_Entry) return Boolean;
   overriding procedure Clear_Updated
     (E : in out U8_Signal_Entry);

   function  Get_Value
     (E :        U8_Signal_Entry) return Adalin.l_u8;
   procedure Set_Value
     (E : in out U8_Signal_Entry; Value : Adalin.l_u8);

   --  Wraps a U16_Signal.Signal; associated with a 16-bit scalar PID.
   type U16_Signal_Entry is new My_Slave.Signal_Entry with record
      PID : My_Slave.LIN_PID;
      Sig : U16_Signal.Signal;
   end record;

   overriding function Get_PID
     (E : U16_Signal_Entry) return My_Slave.LIN_PID;
   overriding function Is_Updated
     (E : U16_Signal_Entry) return Boolean;
   overriding procedure Clear_Updated
     (E : in out U16_Signal_Entry);

   function  Get_Value
     (E :        U16_Signal_Entry) return Adalin.l_u16;
   procedure Set_Value
     (E : in out U16_Signal_Entry; Value : Adalin.l_u16);

   --  Wraps an Arr_Signal.Signal; associated with a byte-array PID.
   type Arr_Signal_Entry is new My_Slave.Signal_Entry with record
      PID : My_Slave.LIN_PID;
      Sig : Arr_Signal.Signal;
   end record;

   overriding function Get_PID
     (E : Arr_Signal_Entry) return My_Slave.LIN_PID;
   overriding function Is_Updated
     (E : Arr_Signal_Entry) return Boolean;
   overriding procedure Clear_Updated
     (E : in out Arr_Signal_Entry);

   function  Get_Value
     (E :        Arr_Signal_Entry) return Adalin.l_byte_array;
   procedure Set_Value
     (E : in out Arr_Signal_Entry; Value : Adalin.l_byte_array);

   ---------------------------------------------------------------------------
   --  5. Static signal objects  (PIDs from illustrative LDF values)
   ---------------------------------------------------------------------------

   --  PID 0x21  EngineSpeed   - 8-bit scalar, 8 bits wide
   Engine_Speed_Entry : aliased U8_Signal_Entry :=
     (PID => 16#21#,
      Sig => U8_Signal.Make
               (Handle        => 0,
                Name          => "EngineSpeed" & [12 .. 64 => ' '],
                Default_Value => 0,
                Size          => 8));

   --  PID 0x22  BatteryVoltage - 16-bit scalar, 16 bits wide
   Battery_Voltage_Entry : aliased U16_Signal_Entry :=
     (PID => 16#22#,
      Sig => U16_Signal.Make
               (Handle        => 1,
                Name          => "BatteryVoltage" & [15 .. 64 => ' '],
                Default_Value => 0,
                Size          => 16));

   --  PID 0x23  SensorBytes   - byte array, 4 active bytes
   Sensor_Bytes_Entry : aliased Arr_Signal_Entry :=
     (PID => 16#23#,
      Sig => Arr_Signal.Make
               (Handle        => 2,
                Name          => "SensorBytes" & [12 .. 64 => ' '],
                Default_Value => [others => 0],
                Size          => 4));

   ---------------------------------------------------------------------------
   --  6. Slave node instance and initialisation
   ---------------------------------------------------------------------------
   My_Node : My_Slave.Slave_Node;

   --  Register all three signal entries with My_Node.
   --  Must be called exactly once before the node is used.
   procedure Initialize_Node;

end Demo_Slave_Signals;
