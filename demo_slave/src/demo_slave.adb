with Adalin;                     use Adalin;
with Demo_Slave_Signals;         use Demo_Slave_Signals;
with Demo_Slave_Type;            use Demo_Slave_Type;
with Demo_Slave_UDP;
with Interfaces;
with Simple_Logging;             use Simple_Logging;
use Demo_Slave_Signals.My_Slave;

procedure Demo_Slave is

   --  The slave node instance lives in Demo_Slave_Signals.
   --  Bring the My_Slave namespace into scope for Signal_Entry_Access.
   package My_Slave renames Demo_Slave_Signals.My_Slave;

   --  Concrete slave object that provides the IRQ call-outs.
   demo_obj     : aliased Demo_Slave_Type.Demo_Slave_Type;
   slave_access : constant access My_Slave.Slave'Class := demo_obj'Access;

   ---------------------------------------------------------------------------
   --  Helper: log the name and updated flag for every registered signal.
   ---------------------------------------------------------------------------
   procedure Log_Signal_Map is
   begin
      Log ("Signal map has"
           & My_Slave.Registered_Count (My_Node)'Image
           & " entries (capacity"
           & My_Slave.Max_Signals'Image & "):");

      --  Engine Speed (PID 0x21, U8)
      declare
         E : constant My_Slave.Signal_Entry_Access :=
               My_Slave.Get_Entry (My_Node, 16#21#);
      begin
         if E /= null then
            Log ("  PID 0x21 EngineSpeed    updated=" & E.Is_Updated'Image);
         end if;
      end;

      --  Battery Voltage (PID 0x22, U16)
      declare
         E : constant My_Slave.Signal_Entry_Access :=
               My_Slave.Get_Entry (My_Node, 16#22#);
      begin
         if E /= null then
            Log ("  PID 0x22 BatteryVoltage updated=" & E.Is_Updated'Image);
         end if;
      end;

      --  Sensor Bytes (PID 0x23, byte array)
      declare
         E : constant My_Slave.Signal_Entry_Access :=
               My_Slave.Get_Entry (My_Node, 16#23#);
      begin
         if E /= null then
            Log ("  PID 0x23 SensorBytes    updated=" & E.Is_Updated'Image);
         end if;
      end;
   end Log_Signal_Map;

   ---------------------------------------------------------------------------
   --  critical – guards a section with the IRQ call-outs while updating
   --  a signal so the driver will notice the change on the next frame slot.
   ---------------------------------------------------------------------------
   procedure Critical_Update_Engine_Speed (New_Speed : Adalin.l_u8) is
      irq : constant My_Slave.IrqState'Class := slave_access.sys_irq_disable;
   begin
      Log ("  [critical] irq=" & demo_obj.irq'Image
           & "  writing EngineSpeed ->" & New_Speed'Image);
      Engine_Speed_Entry.Set_Value (New_Speed);
      slave_access.sys_irq_restore (irq);
   end Critical_Update_Engine_Speed;

begin
   --  ── Initialise ──────────────────────────────────────────────────────
   Log ("Demo_Slave: initialising signal map");
   Initialize_Node;   --  registers all three entries with My_Node

   Log ("Demo_Slave: Is_Ready = " & My_Slave.Is_Ready (My_Node)'Image);
   Log_Signal_Map;

   --  ── Write signals ────────────────────────────────────────────────────
   Log ("--- writing signals ---");
   Critical_Update_Engine_Speed (120);
   Battery_Voltage_Entry.Set_Value (12_400);
   Sensor_Bytes_Entry.Set_Value ([1, 2, 3, 4, 0, 0, 0, 0]);

   Log_Signal_Map;  --  all three should now show updated=TRUE

   --  ── Simulate driver consuming the frames (clears updated flags) ─────
   Log ("--- driver consuming frames ---");
   declare
      E21 : constant My_Slave.Signal_Entry_Access :=
              My_Slave.Get_Entry (My_Node, 16#21#);
      E22 : constant My_Slave.Signal_Entry_Access :=
              My_Slave.Get_Entry (My_Node, 16#22#);
      E23 : constant My_Slave.Signal_Entry_Access :=
              My_Slave.Get_Entry (My_Node, 16#23#);
   begin
      if E21 /= null and then E21.Is_Updated then
         Log ("  transmitting PID 0x21");
         E21.Clear_Updated;
      end if;
      if E22 /= null and then E22.Is_Updated then
         Log ("  transmitting PID 0x22");
         E22.Clear_Updated;
      end if;
      if E23 /= null and then E23.Is_Updated then
         Log ("  transmitting PID 0x23");
         E23.Clear_Updated;
      end if;
   end;

   Log_Signal_Map;  --  all three should now show updated=FALSE

   --  ── UDP send / receive demo ──────────────────────────────────────────
   --  The Receiver task started automatically when Demo_Slave_UDP was
   --  elaborated.  Send a test LIN frame to the loopback address; the
   --  Receiver will pick it up and call l_ifc_rx once per byte.
   Log ("--- UDP demo (loopback on port 7373) ---");

   --  Frame: PID=0x21 (EngineSpeed), data=[120,0,0,0], checksum=0
   Demo_Slave_UDP.Send_Frame
     (iii      => i_ifc_default,
      PID      => Interfaces.Unsigned_8 (16#21#),
      Data     => [120, 0, 0, 0, 0, 0, 0, 0],
      Data_Len => 4,
      Checksum => 0);

   --  Frame: PID=0x22 (BatteryVoltage), data=[0x30,0x48], checksum=0
   Demo_Slave_UDP.Send_Frame
     (iii      => i_ifc_default,
      PID      => Interfaces.Unsigned_8 (16#22#),
      Data     => [16#30#, 16#48#, 0, 0, 0, 0, 0, 0],
      Data_Len => 2,
      Checksum => 0);

   --  Allow the Receiver task a moment to process the loopback packets.
   delay 0.5;

   --  Orderly shutdown: tell the task to stop and wait for it to exit.
   Demo_Slave_UDP.Receiver.Shutdown;

   Log ("Demo_Slave: done");

end Demo_Slave;
