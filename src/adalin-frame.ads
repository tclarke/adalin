package Adalin.Frame is

      type Byte is mod 256;
      for Byte'Size use 8;

      type Bits6 is mod 64;
      for Bits6'Size use 6;

      type Bits2 is mod 4;
      for Bits2'Size use 2;

      type Data_Array is array (Natural range <>) of aliased Byte;

      type Mode_Type is (Classic, Enhanced);

      type Frame is record
         frame_identifier : aliased Bits6;
         parity           : aliased Bits2;
         data             : Data_Array (1 .. 8) := (others => 0);
         length           : Natural range 1 .. 8;
         checksum         : aliased Byte;
      end record;

      function GetPID (Self : Frame) return Byte;

      procedure Calculate_FID_Parity (Self : in out Frame);

      procedure Calculate_Data_Checksum (Self : in out Frame;
         mode : Mode_Type)
         with Pre => Self.length >= 1 and then Self.length <= 8;

      procedure SetFrameIdentifier (Self : in out Frame; ID : Bits6)
      with Pre => ID <= 63;

      procedure SetData (Self : in out Frame; New_Data : Data_Array;
      mode : Mode_Type)
      with Pre => New_Data'Length >= 1 and then New_Data'Length <= 8;

end Adalin.Frame;
