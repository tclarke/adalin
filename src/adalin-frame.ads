with Interfaces;

package Adalin.Frame
  with SPARK_Mode => On
is

   --  Basic types for adaLIN frames
   subtype Byte is Interfaces.Unsigned_8;

   type Bits6 is mod 2 ** 6;
   for Bits6'Size use 6;

   type Bits2 is mod 2 ** 2;
   for Bits2'Size use 2;

   subtype Data_Length is Natural range 1 .. 8;
   --  Data array must be 1 to 8 bytes long
   type Data_Array is array (Data_Length) of Byte;

   --  Mode type for checksum calculation.
   type Mode_Type is (Classic, Enhanced);

   --  Frame record type. Packed so it can be directly copied to harware.
   --  These shouldn't be modified directly, use the provided procedures.
   type Frame is record
      frame_identifier : aliased Bits6;
      parity           : aliased Bits2;
      data             : Data_Array := [others => 0];
      length           : Data_Length;
      checksum         : aliased Byte;
   end record;

   --  Get the protected identifier (PID) from the frame
   --  (combines the FID and parity).
   function GetPID (F : Frame) return Byte;

   --  Set the FID and calculate the parity bits.
   procedure SetFrameIdentifier (F : in out Frame; ID : Bits6)
   with Pre => ID <= 63;

   --  Set the data bytes and calculate the checksum.
   procedure SetData (F : in out Frame;
      New_Data : Data_Array; Length : Natural; mode : Mode_Type)
   with Pre => Length >= 1 and then Length <= 8;

private
   procedure Calculate_FID_Parity (F : in out Frame);

   --  Precondition: F.length must be within Data_Length's declared range
   --  (1 .. 8) so the loop bound in the body is always valid and the
   --  running sum can be proved to stay <= 255 under strict overflow mode.
   function Calculate_Data_Checksum (F : Frame; mode : Mode_Type) return Byte
     with Pre => F.length in Data_Length;

end Adalin.Frame;
