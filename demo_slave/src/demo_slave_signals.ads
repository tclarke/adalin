--  Demo_Slave_Signals
--
--  Owns the concrete Adalin.Signal instances for the demo slave node and
--  registers them with the Adalin.Slave.Slave_Node ADT.
--
--  Layout
--  ------
--  1. Instantiate Adalin.Slave (Capacity => 3) as My_Slave.
--  2. Declare the three static signal objects (no heap allocation),
--     using the *_Signal_Entry types from the Adalin package.
--  3. Expose My_Node : My_Slave.Slave_Node and Initialize_Node.

with Adalin;
with Adalin.Signals;
with Adalin.Slave;

package Demo_Slave_Signals is

   ---------------------------------------------------------------------------
   --  1. Slave instantiation
   ---------------------------------------------------------------------------
   package My_Slave is new Adalin.Slave (Capacity => 3);

   ---------------------------------------------------------------------------
   --  2. Static signal objects  (PIDs from illustrative LDF values)
   --
   --  U8_Signal_Entry, U16_Signal_Entry, and Arr_Signal_Entry are declared
   --  in the Adalin.Signals package and used directly here.
   ---------------------------------------------------------------------------

   --  PID 0x21  EngineSpeed   - 8-bit scalar, 8 bits wide
   Engine_Speed_Entry : aliased Adalin.Signals.U8_Signal_Entry :=
     (PID => 16#21#,
      Sig => Adalin.Signals.U8_Signal.Make
               (Handle        => 0,
                Name          => "EngineSpeed" & [12 .. 64 => ' '],
                Default_Value => 0,
                Size          => 8));

   --  PID 0x22  BatteryVoltage - 16-bit scalar, 16 bits wide
   Battery_Voltage_Entry : aliased Adalin.Signals.U16_Signal_Entry :=
     (PID => 16#22#,
      Sig => Adalin.Signals.U16_Signal.Make
               (Handle        => 1,
                Name          => "BatteryVoltage" & [15 .. 64 => ' '],
                Default_Value => 0,
                Size          => 16));

   --  PID 0x23  SensorBytes   - byte array, 4 active bytes
   Sensor_Bytes_Entry : aliased Adalin.Signals.Arr_Signal_Entry :=
     (PID => 16#23#,
      Sig => Adalin.Signals.Arr_Signal.Make
               (Handle        => 2,
                Name          => "SensorBytes" & [12 .. 64 => ' '],
                Default_Value => [others => 0],
                Size          => 4));

   ---------------------------------------------------------------------------
   --  3. Slave node instance and initialisation
   ---------------------------------------------------------------------------
   My_Node : My_Slave.Slave_Node;

   --  Register all three signal entries with My_Node.
   --  Must be called exactly once before the node is used.
   procedure Initialize_Node;

end Demo_Slave_Signals;
