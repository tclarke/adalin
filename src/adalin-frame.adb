package body Adalin.Frame is
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

end Adalin.Frame;
