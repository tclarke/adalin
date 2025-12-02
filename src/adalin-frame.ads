package Adalin.Frame with SPARK_Mode => On is

   --  Basic types for adaLIN frames
   type Byte is mod 256;
   for Byte'Size use 8;

   type Bits6 is mod 64;
   for Bits6'Size use 6;

   type Bits2 is mod 4;
   for Bits2'Size use 2;

   --  Data array must be 1 to 8 bytes long
   type Data_Array is array (Natural range <>) of Byte;

   --  Mode type for checksum calculation.
   type Mode_Type is (Classic, Enhanced);

   --  Frame record type. Packed so it can be directly copied to harware.
   --  These shouldn't be modified directly, use the provided procedures.
   type Frame is record
      frame_identifier : aliased Bits6;
      parity           : aliased Bits2;
      data             : Data_Array (1 .. 8) := (others => 0);
      length           : Natural range 1 .. 8;
      checksum         : aliased Byte;
   end record;

   --  Get the protected identifier (PID) from the frame
   --  (combines the FID and parity).
   function GetPID (F : Frame) return Byte;

   --  Set the FID and calculate the parity bits.
   procedure SetFrameIdentifier (F : in out Frame; ID : Bits6)
   with Pre => ID <= 63;

   --  Set the data bytes and calculate the checksum.
   procedure SetData (F : in out Frame; New_Data : Data_Array;
   mode : Mode_Type)
   with Pre => New_Data'Length >= 1 and then New_Data'Length <= 8;

private
   procedure Calculate_FID_Parity (F : in out Frame);
   function Calculate_Data_Checksum (F : Frame; mode : Mode_Type)
      return Byte;

end Adalin.Frame;
