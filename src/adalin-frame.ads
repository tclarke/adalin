package Adalin.Frame is

   type Bits6 is mod 64;
   for Bits6'Size use 6;

   type Bits2 is mod 4;
   for Bits2'Size use 2;

   type Frame is record
      frame_identifier : aliased Bits6;
      parity           : aliased Bits2;
   end record;

   procedure Calculate_FID_Parity (Self : in out Frame);

end Adalin.Frame;
