--  Demo_Slave_UDP – body

with Ada.Exceptions; use Ada.Exceptions;
with Ada.Streams;    use Ada.Streams;
with Interfaces;     use Interfaces;
with GNAT.Sockets;   use GNAT.Sockets;
with Simple_Logging; use Simple_Logging;
with Adalin;         use Adalin;

package body Demo_Slave_UDP is

   ---------------------------------------------------------------------------
   --  Rx_Buffer
   ---------------------------------------------------------------------------

   protected body Rx_Buffer is

      --  Deposit a freshly-received frame.  Any unconsumed bytes from the
      --  previous frame are silently discarded; the LIN driver must drain
      --  Rx_Buffer faster than new frames arrive (always true at LIN speeds).
      procedure Put (Data : Frame_Buffer; Len : Natural) is
      begin
         Buf   := Data;
         Count := (if Len > Max_Frame_Bytes then Max_Frame_Bytes else Len);
         Pos   := 0;
      end Put;

      --  Return the next unconsumed byte.  Sets OK=False when empty.
      procedure Next_Byte (B : out Unsigned_8; OK : out Boolean) is
      begin
         if Pos < Count then
            B   := Buf (Pos);
            Pos := Pos + 1;
            OK  := True;
         else
            B  := 0;
            OK := False;
         end if;
      end Next_Byte;

      function Has_Data return Boolean is (Pos < Count);

      procedure Flush is
      begin
         Count := 0;
         Pos   := 0;
      end Flush;

   end Rx_Buffer;

   ---------------------------------------------------------------------------
   --  l_ifc_get_byte – exported call-out
   --
   --  When the LIN RX state machine in adalin.adb is implemented it will
   --  import this symbol (External_Name => "l_ifc_get_byte") to pull bytes
   --  from the transport layer one at a time, exactly as it would read a
   --  hardware UART data register.
   --
   --  iii is the base type of l_ifc_handle; Unsigned_8 keeps the exported
   --  symbol unambiguous across compilation units.
   ---------------------------------------------------------------------------
   procedure l_ifc_get_byte
     (iii : Unsigned_8;
      B   : out Unsigned_8;
      OK  : out Boolean)
   with Export, Convention => Ada, External_Name => "l_ifc_get_byte";

   procedure l_ifc_get_byte
     (iii : Unsigned_8; B : out Unsigned_8; OK : out Boolean)
   is
      pragma Unreferenced (iii);
   begin
      Rx_Buffer.Next_Byte (B, OK);
   end l_ifc_get_byte;

   ---------------------------------------------------------------------------
   --  Send_Frame
   ---------------------------------------------------------------------------

   procedure Send_Frame
     (iii       : l_ifc_handle;
      PID       : Unsigned_8;
      Data      : l_byte_array;
      Data_Len  : Positive;
      Checksum  : Unsigned_8;
      Dest_Addr : Inet_Addr_Type := Loopback_Inet_Addr)
   is
      pragma Unreferenced (iii);

      --  Wire layout: [PID][data_0]..[data_N-1][checksum]
      Pkt_Len : constant Stream_Element_Offset :=
                  Stream_Element_Offset (1 + Data_Len + 1);
      Pkt     : Stream_Element_Array (1 .. Pkt_Len);
      Dest    : constant Sock_Addr_Type :=
                  (Family => Family_Inet,
                   Addr   => Dest_Addr,
                   Port   => UDP_Port);
      Sock    : Socket_Type;
      Last    : Stream_Element_Offset;
   begin
      Pkt (1) := Stream_Element (PID);
      for I in 0 .. Data_Len - 1 loop
         Pkt (Stream_Element_Offset (2 + I)) :=
           Stream_Element (Unsigned_8 (Data (l_array_index (I))));
      end loop;
      Pkt (Pkt_Len) := Stream_Element (Checksum);

      Create_Socket (Sock, Family_Inet, Socket_Datagram);
      begin
         Send_Socket (Sock, Pkt, Last, Dest);
         Log ("UDP TX -> " & Image (Dest_Addr)
              & ":" & UDP_Port'Image
              & " PID=" & PID'Image
              & " len=" & Pkt_Len'Image);
      exception
         when E : Socket_Error =>
            Log ("UDP TX error: " & Exception_Message (E));
      end;
      Close_Socket (Sock);

   exception
      when E : others =>
         Log ("Send_Frame: " & Exception_Message (E));
   end Send_Frame;

   ---------------------------------------------------------------------------
   --  Receiver task body
   ---------------------------------------------------------------------------

   task body Receiver is
      Sock      : Socket_Type;
      Bind_Addr : Sock_Addr_Type;
      Raw       : Stream_Element_Array (1 .. Max_Frame_Bytes);
      Last      : Stream_Element_Offset;
      From      : Sock_Addr_Type;
      Buf       : Frame_Buffer;
      Len       : Natural;
   begin
      Create_Socket (Sock, Family_Inet, Socket_Datagram);
      Set_Socket_Option
        (Sock, Socket_Level, (Name => Reuse_Address, Enabled => True));

      --  1-second receive timeout: lets the task poll for Shutdown each
      --  iteration without blocking indefinitely.
      Set_Socket_Option
        (Sock, Socket_Level, (Name => Receive_Timeout, Timeout => 1.0));

      Bind_Addr :=
        (Family => Family_Inet,
         Addr   => Any_Inet_Addr,
         Port   => UDP_Port);
      Bind_Socket (Sock, Bind_Addr);

      Log ("UDP Receiver: bound to *:" & UDP_Port'Image);

      loop
         --  Non-blocking poll: honour a Shutdown request immediately.
         select
            accept Shutdown;
            Log ("UDP Receiver: shutting down");
            Close_Socket (Sock);
            exit;
         else
            null;
         end select;

         --  Block for up to 1 second waiting for a datagram.
         begin
            Receive_Socket (Sock, Raw, Last, From);

            Len := Natural (Last);
            if Len > Max_Frame_Bytes then
               Len := Max_Frame_Bytes;
            end if;

            Buf := [others => 0];
            for I in 0 .. Len - 1 loop
               Buf (I) :=
                 Unsigned_8 (Raw (Stream_Element_Offset (I + 1)));
            end loop;

            Log ("UDP RX <- " & Image (From.Addr)
                 & ":" & From.Port'Image
                 & " PID=" & Buf (0)'Image
                 & " len=" & Len'Image);

            --  Hand the frame to the LIN driver layer.
            Rx_Buffer.Put (Buf, Len);

            --  Drive l_ifc_rx once per byte, simulating byte-at-a-time
            --  UART ISR behaviour.  When the state machine is implemented
            --  it will consume bytes via l_ifc_get_byte on each call.
            for J in 1 .. Len loop
               l_ifc_rx (i_ifc_default);
            end loop;

         exception
            when Socket_Error =>
               null;  --  receive timed out; loop and check Shutdown again
         end;
      end loop;

   exception
      when E : others =>
         Log ("UDP Receiver: fatal: " & Exception_Message (E));
   end Receiver;

end Demo_Slave_UDP;