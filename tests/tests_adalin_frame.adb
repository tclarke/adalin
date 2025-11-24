with AUnit.Test_Cases;
with AUnit.Assertions;
with Adalin.Frame;
with Ada.Text_IO;

package body Tests.Adalin_Frame is

   procedure Test_Calculate_FID_Parity is
      -- Helper returns the N-th bit of V (0..)
      function Bit (V : Integer; N : Integer) return Boolean is
      begin
         return ((V / (2 ** N)) rem 2) = 1;
      end Bit;

      -- Set frame identifier (mod type) from integer value (0..63)
      procedure Set_Frame_ID (F : in out Adalin.Frame.Frame; Id : Integer) is
      begin
         F.frame_identifier := Adalin.Frame.Bits6 (Id);
      end Set_Frame_ID;

      -- Convert parity Bits2 to integer value
      function Parity_To_Int (P : Adalin.Frame.Bits2) return Integer is
      begin
         return Integer (P);
      end Parity_To_Int;

      F : Adalin.Frame.Frame;
      Expected : Integer;
      P0, P1 : Boolean;
   begin
      -- Exhaustive test for IDs 0..63
      for Id in 0 .. 63 loop
         Set_Frame_ID (F, Id);
         -- clear parity
         F.parity := Adalin.Frame.Bits2 (0);

         Adalin.Frame.Calculate_FID_Parity (F);

         P0 := Bit (Id, 0) xor
               Bit (Id, 1) xor
               Bit (Id, 2) xor
               Bit (Id, 4);

         P1 := Bit (Id, 1) xor
               Bit (Id, 3) xor
               Bit (Id, 4) xor
               Bit (Id, 5);

         Expected := (if P1 then 2 else 0) + (if P0 then 1 else 0);

         AUnit.Assertions.Assert_Equal (
            Expected,
            Parity_To_Int (F.parity),
            "Calculate_FID_Parity produced unexpected parity for ID = " & Integer'Image (Id)
         );
      end loop;
   end Test_Calculate_FID_Parity;

   procedure Register is
   begin
      AUnit.Test_Cases.The_Test_Cases.Add ("Adalin.Frame.Calculate_FID_Parity",
                                           Test_Calculate_FID_Parity'Access);
   end Register;

begin
   Register;
end Tests.Adalin_Frame;
