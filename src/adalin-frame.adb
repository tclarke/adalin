pragma Overflow_Mode (General => Strict, Assertions => Eliminated);
package body Adalin.Frame with SPARK_Mode => On is
   function GetPID (F : Frame) return Byte is
   begin
      return Byte (F.frame_identifier) + Byte (F.parity) * 2**6;
   end GetPID;

   procedure Calculate_FID_Parity (F : in out Frame) is

      ID     : constant Bits6 := F.frame_identifier;
      P0, P1 : Boolean;

      --  Helper to test bit N (0..5)
      function Bit_Of (V : Bits6; N : Natural) return Boolean
      with Pre => N < 6
      is
      begin
         return (V and Bits6 (2**N)) /= 0;
      end Bit_Of;

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

      F.parity := Bits2 ((if P0 then 2 else 0) + (if P1 then 1 else 0));
   end Calculate_FID_Parity;

   --  Calculate the checksum for the data in the frame.
   --  Per the spec, mode is set to Classic if FID is 0x3C or 0x3D.
   function Calculate_Data_Checksum (F : Frame;
                                     mode : Mode_Type) return Byte is
      sum : Integer := 0;
   begin
      if mode = Enhanced
        and then (not (F.frame_identifier in 16#3C# .. 16#3D#))
      then
         sum := Integer (GetPID (F));
      end if;

      for I in 1 .. F.length loop
         sum := sum + Integer (F.data (I));
         if sum > 255 then
            sum := sum - 255;
         end if;
      end loop;
      pragma Assert (sum <= 255);

      --  One's complement
      return not Byte (sum);
   end Calculate_Data_Checksum;

   procedure SetFrameIdentifier (F : in out Frame; ID : Bits6) is
   begin
      F.frame_identifier := ID;
      Calculate_FID_Parity (F);
   end SetFrameIdentifier;

   procedure SetData (F : in out Frame; New_Data : Data_Array;
      mode : Mode_Type) is
   begin
      F.length := New_Data'Length;
      F.data (1 .. New_Data'Length) := New_Data;
      F.checksum := Calculate_Data_Checksum (F, mode);
   end SetData;

end Adalin.Frame;
