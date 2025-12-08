with AUnit; use AUnit;
with AUnit.Test_Cases; use AUnit.Test_Cases;

package Tests.Adalin_Core is

   type Test is new Test_Case with null record;

   overriding
   procedure Register_Tests (T : in out Test);

   overriding
   function Name (T : Test) return Message_String;

   overriding
   procedure Set_Up (T : in out Test);

   procedure Test_Driver_Management (T : in out Test_Case'Class);
   procedure Test_Signal (T : in out Test_Case'Class);
   procedure Test_Notification (T : in out Test_Case'Class);
   procedure Test_Interface (T : in out Test_Case'Class);
   procedure Test_Interrupts (T : in out Test_Case'Class);

end Tests.Adalin_Core;
