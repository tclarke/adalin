with AUnit.Assertions;
with Adalin.Frame; use Adalin.Frame;

package body Tests.Adalin_Frame is

   overriding
   procedure Register_Tests (T : in out Test) is
      use AUnit.Test_Cases.Registration;
   begin
      Register_Routine
        (T,
         Tests.Adalin_Frame.Test_Calculate_FID_Parity'Access,
         "Test Calculate FID Parity");
   end Register_Tests;

   overriding
   function Name (T : Test) return Message_String is
   begin
      return Format ("adaLIN Frame Tests");
   end Name;

   procedure Test_Calculate_FID_Parity (T : in out Test_Cases.Test_Case'Class)
   is
      F : Adalin.Frame.Frame;

      --  Expected values from LIN 2.2 specification
      Expected : constant array (0 .. 63) of Bits2 := (
         2#01#, 2#11#, 2#10#, 2#00#, 2#11#, 2#01#, 2#00#, 2#10#,
         2#00#, 2#10#, 2#11#, 2#01#, 2#10#, 2#00#, 2#01#, 2#11#,
         2#10#, 2#00#, 2#01#, 2#11#, 2#00#, 2#10#, 2#11#, 2#01#,
         2#11#, 2#01#, 2#00#, 2#10#, 2#01#, 2#11#, 2#10#, 2#00#,
         2#00#, 2#10#, 2#11#, 2#01#, 2#10#, 2#00#, 2#01#, 2#11#,
         2#01#, 2#11#, 2#10#, 2#00#, 2#11#, 2#01#, 2#00#, 2#10#,
         2#11#, 2#01#, 2#00#, 2#10#, 2#01#, 2#11#, 2#10#, 2#00#,
         2#10#, 2#00#, 2#01#, 2#11#, 2#00#, 2#10#, 2#11#, 2#01#);

   begin
      --  Exhaustive test for IDs 0..63
      for Id in 0 .. 63 loop
         F.frame_identifier := Adalin.Frame.Bits6 (Id);
         Adalin.Frame.Calculate_FID_Parity (F);

         AUnit.Assertions.Assert
           (Expected (Id) = F.parity,
            "Calculate_FID_Parity ID="
            & Integer'Image (Id) & " "
            & Bits2'Image (Expected (Id))
            & " != "
            & Bits2'Image (F.parity));
      end loop;
   end Test_Calculate_FID_Parity;

end Tests.Adalin_Frame;
