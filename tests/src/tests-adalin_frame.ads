with AUnit; use AUnit;
with AUnit.Test_Cases; use AUnit.Test_Cases;

package Tests.Adalin_Frame is

   type Test is new Test_Case with null record;

   overriding
   procedure Register_Tests (T : in out Test);

   overriding
   function Name (T : Test) return Message_String;

   procedure Test_Calculate_FID_Parity (T : in out Test_Case'Class);
   procedure Test_Calculate_Data_Checksum (T : in out Test_Case'Class);

end Tests.Adalin_Frame;