--  Demo_Slave_UDP
--
--  Provides a UDP transport layer that stands in for a hardware UART in the
--  demo slave node.  The mapping onto the LIN 2.2A driver API is:
--
--    Receive path
--    ───────────
--    Receiver task  ──►  Rx_Buffer.Put       (deposit raw bytes)
--                   ──►  l_ifc_rx per byte   (drive LIN RX state machine)
--
--    Transmit path
--    ─────────────
--    Application    ──►  Send_Frame          (pack PID+data+checksum → UDP)
--
--  UDP packet format (same for both directions):
--    Byte 0       : PID  (6-bit FID + 2 parity bits, LIN 2.2A §2.3.1.3)
--    Bytes 1..N-1 : data (1..8 payload bytes)
--    Byte N       : checksum
--
--  l_ifc_get_byte is exported so that when the LIN RX state machine
--  (adalin.adb) is implemented it can pull bytes from Rx_Buffer without
--  any source-level dependency on this package.

with Interfaces;
with Adalin;
with GNAT.Sockets;

package Demo_Slave_UDP is

   UDP_Port : constant GNAT.Sockets.Port_Type := 7373;

   --  Maximum wire bytes per LIN frame: PID (1) + data (8) + checksum (1).
   Max_Frame_Bytes : constant := 10;

   type Frame_Buffer is
     array (Natural range 0 .. Max_Frame_Bytes - 1) of Interfaces.Unsigned_8;

   ---------------------------------------------------------------------------
   --  Rx_Buffer – single-slot protected byte buffer.
   --
   --  Thread-safe handoff between the Receiver task and l_ifc_rx / the LIN
   --  state machine.  Holds at most one LIN frame at a time.
   --
   --  Put       – called by Receiver; overwrites any unconsumed frame.
   --  Next_Byte – called by l_ifc_rx (or the state machine) once per byte,
   --              simulating a UART data-register read.
   --  Has_Data  – true when at least one byte has not yet been consumed.
   --  Flush     – discard the current frame (e.g. on checksum error).
   ---------------------------------------------------------------------------
   protected Rx_Buffer is
      procedure Put
        (Data : Frame_Buffer;
         Len  : Natural);

      procedure Next_Byte
        (B  : out Interfaces.Unsigned_8;
         Available : out Boolean);

      function Has_Data return Boolean;

      procedure Flush;

   private
      Buf   : Frame_Buffer := [others => 0];
      Count : Natural      := 0;   --  valid bytes in Buf
      Pos   : Natural      := 0;   --  index of next byte to return
   end Rx_Buffer;

   ---------------------------------------------------------------------------
   --  Send_Frame
   --
   --  Packs  PID + Data[0 .. Data_Len-1] + Checksum  into a single UDP
   --  datagram and sends it to  Dest_Addr : UDP_Port.
   --  Dest_Addr defaults to the loopback address so that the demo's own
   --  Receiver task picks the frame back up, exercising the full path.
   ---------------------------------------------------------------------------
   procedure Send_Frame
     (iii       : Adalin.l_ifc_handle;
      PID       : Interfaces.Unsigned_8;
      Data      : Adalin.l_byte_array;
      Data_Len  : Positive;
      Checksum  : Interfaces.Unsigned_8;
      Dest_Addr : GNAT.Sockets.Inet_Addr_Type :=
                    GNAT.Sockets.Loopback_Inet_Addr);

   ---------------------------------------------------------------------------
   --  Receiver – background task
   --
   --  Binds a UDP socket to *:UDP_Port and loops:
   --    1. Receive one datagram (blocks up to 1 s then retries).
   --    2. Deposit the raw bytes into Rx_Buffer.
   --    3. Call l_ifc_rx (i_ifc_default) once per received byte.
   --
   --  Call  Receiver.Shutdown  for an orderly stop; the task will exit
   --  within one receive-timeout period (≤ 1 s).
   ---------------------------------------------------------------------------
   task Receiver is
      entry Shutdown;
   end Receiver;

end Demo_Slave_UDP;
