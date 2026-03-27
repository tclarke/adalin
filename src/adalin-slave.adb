--  Adalin.Slave - body

with Interfaces; use Interfaces;

package body Adalin.Slave is

   ---------------------------------------------------------------------------
   --  Internal: linear scan for a PID.  Returns 1-based index or 0.
   ---------------------------------------------------------------------------
   function Find_Entry
     (Node : Slave_Node;
      PID  : LIN_PID) return Natural
   is
   begin
      for I in 1 .. Node.Count loop
         if Node.Entries (I).PID = PID then
            return I;
         end if;
      end loop;
      return 0;
   end Find_Entry;

   ---------------------------------------------------------------------------
   --  Register
   ---------------------------------------------------------------------------
   procedure Register
     (Node      : in out Slave_Node;
      PID       : LIN_PID;
      Entry_Ptr : not null Signal_Entry_Access;
      Dir       : Frame_Direction;
      Num_Bytes : Positive)
   is
   begin
      if Node.Count >= Capacity then
         raise Constraint_Error with
           "Adalin.Slave.Register: capacity (" & Capacity'Image & ") exceeded";
      end if;
      Node.Count := Node.Count + 1;
      Node.Entries (Node.Count) :=
        (PID       => PID,
         Entry_Ptr => Entry_Ptr,
         Dir       => Dir,
         Num_Bytes => Num_Bytes);
   end Register;

   ---------------------------------------------------------------------------
   --  Queries
   ---------------------------------------------------------------------------
   function Get_Entry
     (Node : Slave_Node;
      PID  : LIN_PID) return Signal_Entry_Access
   is
      Idx : constant Natural := Find_Entry (Node, PID);
   begin
      return (if Idx = 0 then null else Node.Entries (Idx).Entry_Ptr);
   end Get_Entry;

   function Registered_Count (Node : Slave_Node) return Natural is
     (Node.Count);

   function Is_Ready (Node : Slave_Node) return Boolean is
     (Node.Count = Capacity);

   function Current_State (Node : Slave_Node) return Slave_State is
     (Node.State);

   ---------------------------------------------------------------------------
   --  Checksum validation (LIN 2.2A sec 2.3.1.5)
   --
   --  Enhanced checksum (LIN 2.x): 8-bit sum-with-carry over PID + data,
   --  then one's complement.  Classic checksum: data bytes only.
   --  FIDs 0x3C and 0x3D always use classic checksum.
   ---------------------------------------------------------------------------
   function Checksum_Valid
     (PID      : LIN_PID;
      Buf      : Raw_Frame_Bytes;
      N        : Natural;
      Received : Unsigned_8) return Boolean
   is
      FID : constant Unsigned_8 := PID and 16#3F#;
      Sum : Natural := 0;
   begin
      if FID /= 16#3C# and then FID /= 16#3D# then
         Sum := Natural (PID);
      end if;
      for I in 0 .. N - 1 loop
         Sum := Sum + Natural (Buf (I));
         if Sum >= 256 then
            Sum := Sum - 255;
         end if;
      end loop;
      return (not Unsigned_8 (Sum mod 256)) = Received;
   end Checksum_Valid;

   ---------------------------------------------------------------------------
   --  l_ifc_rx - per-byte receive/transmit state machine
   --
   --  Called from the UART RX ISR once per received byte (LIN 2.2A API
   --  spec sec 7.2.5.5).
   --
   --  Sync detection: the break field is assumed handled at the hardware or
   --  l_ifc_aux layer.  This implementation treats 0x55 as the sync trigger
   --  from the Idle state, which is correct for UART-based implementations
   --  where the break + sync byte sequence brings the node into frame lock.
   --
   --  Recv_Sync -> Recv_PID is an immediate re-dispatch: the byte that
   --  transitions us out of Recv_Sync IS the PID, so we tail-call back into
   --  l_ifc_rx rather than waiting for the next byte.
   ---------------------------------------------------------------------------
   procedure l_ifc_rx
     (Node : in out Slave_Node;
      Byte : Unsigned_8)
   is
   begin
      case Node.State is

         --  Waiting for the LIN sync byte (0x55).
         when Idle =>
            if Byte = 16#55# then
               Node.State := Recv_Sync;
            end if;

         --  Sync confirmed; the very next byte is the PID.
         --  Transition state first, then re-dispatch the same byte.
         when Recv_Sync =>
            Node.State := Recv_PID;
            l_ifc_rx (Node, Byte);

         --  Decode PID: verify parity, look up in signal map.
         when Recv_PID =>
            declare
               Raw_FID : constant Unsigned_8 := Byte and 16#3F#;

               function Bit (N : Natural) return Boolean is
                 ((Shift_Right (Raw_FID, N) and 1) /= 0);

               --  LIN 2.2A sec 2.3.1.3 parity equations.
               Exp_P0 : constant Boolean :=
                 Bit (0) xor Bit (1) xor Bit (2) xor Bit (4);
               Exp_P1 : constant Boolean :=
                 not (Bit (1) xor Bit (3) xor Bit (4) xor Bit (5));

               Raw_P0 : constant Boolean :=
                 (Shift_Right (Byte, 6) and 1) /= 0;
               Raw_P1 : constant Boolean :=
                 (Shift_Right (Byte, 7) and 1) /= 0;

               Idx : Natural;
            begin
               if Raw_P0 /= Exp_P0 or else Raw_P1 /= Exp_P1 then
                  Node.State := Idle;
                  return;
               end if;

               Idx := Find_Entry (Node, Byte);

               if Idx = 0 then
                  Node.State := Idle;
                  return;
               end if;

               Node.Current_PID    := Byte;
               Node.Current_Dir    := Node.Entries (Idx).Dir;
               Node.Bytes_Expected := Node.Entries (Idx).Num_Bytes;
               Node.Bytes_Done     := 0;
               Node.Rx_Buf         := [others => 0];
               Node.Matched_Entry  := Node.Entries (Idx).Entry_Ptr;

               if Node.Current_Dir = Subscribe then
                  Node.State := Recv_Data;
               else
                  Node.State := Tx_Data;
               end if;
            end;

         --  Collect subscribe-frame data bytes.
         when Recv_Data =>
            Node.Rx_Buf (Node.Bytes_Done) := Byte;
            Node.Bytes_Done := Node.Bytes_Done + 1;
            if Node.Bytes_Done = Node.Bytes_Expected then
               Node.State := Recv_Checksum;
            end if;

         --  Slave is publisher: count the echoed bytes, ignore their value.
         when Tx_Data =>
            Node.Bytes_Done := Node.Bytes_Done + 1;
            if Node.Bytes_Done = Node.Bytes_Expected then
               Node.State := Recv_Checksum;
            end if;

         --  Validate checksum; commit received data for subscribe frames.
         when Recv_Checksum =>
            declare
               Ok : constant Boolean :=
                 Checksum_Valid
                   (PID      => Node.Current_PID,
                    Buf      => Node.Rx_Buf,
                    N        => Node.Bytes_Done,
                    Received => Byte);
            begin
               if Ok
                 and then Node.Current_Dir = Subscribe
                 and then Node.Matched_Entry /= null
               then
                  Node.Matched_Entry.Receive_Bytes
                    (Node.Rx_Buf, Node.Bytes_Done);
               end if;
            end;
            Node.State        := Idle;
            Node.Matched_Entry := null;

      end case;
   end l_ifc_rx;

end Adalin.Slave;