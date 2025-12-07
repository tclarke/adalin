with AUnit; use AUnit;
with AUnit.Test_Cases; use AUnit.Test_Cases;

package Tests.Adalin_Managers is

   type Test is new Test_Case with null record;

   overriding
   procedure Register_Tests (T : in out Test);

   overriding
   function Name (T : Test) return Message_String;

   procedure Test_Irq_Manager (T : in out Test_Case'Class);

end Tests.Adalin_Managers;
