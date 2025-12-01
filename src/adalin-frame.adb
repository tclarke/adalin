package body Adalin.Frame is
   function GetPID (Self : Frame) return Byte is
   begin
      return Byte (Self.frame_identifier) + Byte (Self.parity) * 2**6;
   end GetPID;

   procedure Calculate_FID_Parity (Self : in out Frame) is
      ID     : constant Bits6 := Self.frame_identifier;
      --  Helper to test bit N (0..5)
      function Bit_Of (V : Bits6; N : Natural) return Boolean is
      begin
         return (V and Bits6 (2**N)) /= 0;
      end Bit_Of;
      P0, P1 : Boolean;
   begin
      P0 :=
        Bit_Of (ID, 0)
        xor Bit_Of (ID, 1)
        xor Bit_Of (ID, 2)
        xor Bit_Of (ID, 4);
      P1 := not (
        Bit_Of (ID, 1)
        xor Bit_Of (ID, 3)
        xor Bit_Of (ID, 4)
        xor Bit_Of (ID, 5));

      Self.parity := Bits2 ((if P0 then 2 else 0) + (if P1 then 1 else 0));
   end Calculate_FID_Parity;

   procedure Calculate_Data_Checksum (Self : in out Frame;
                                      mode : Mode_Type) is
      sum : Integer := 0;
   begin
      if mode = Enhanced
        and then (not (Self.frame_identifier in 16#3C# .. 16#3D#))
      then
         sum := Integer (GetPID (Self));
      end if;

      for I in 1 .. Self.length loop
         sum := sum + Integer (Self.data (I));
         if sum > 255 then
            sum := sum - 255;
         end if;
      end loop;

      --  One's complement
      Self.checksum := not Byte (sum);
   end Calculate_Data_Checksum;

   procedure SetFrameIdentifier (Self : in out Frame; ID : Bits6) is
   begin
      Self.frame_identifier := ID;
      Calculate_FID_Parity (Self);
   end SetFrameIdentifier;

   procedure SetData (Self : in out Frame; New_Data : Data_Array;
      mode : Mode_Type) is
   begin
      Self.length := New_Data'Length;
      Self.data (1 .. New_Data'Length) := New_Data;
      Calculate_Data_Checksum (Self, mode);
   end SetData;

end Adalin.Frame;
