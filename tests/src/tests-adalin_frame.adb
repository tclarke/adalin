with AUnit.Assertions;
with Adalin.Frame; use Adalin.Frame;

package body Tests.Adalin_Frame is

   overriding
   procedure Register_Tests (T : in out Test) is
      use Registration;
   begin
      Register_Routine
        (T,
         Tests.Adalin_Frame.Test_Calculate_FID_Parity'Access,
         "Test Calculate FID Parity");
      Register_Routine
        (T,
         Tests.Adalin_Frame.Test_Calculate_Data_Checksum'Access,
         "Test Calculate Data Checksum");
   end Register_Tests;

   overriding
   function Name (T : Test) return Message_String is
   begin
      return Format ("adaLIN Frame Tests");
   end Name;

   procedure Test_Calculate_FID_Parity (T : in out Test_Case'Class) is
      pragma Unreferenced (T);

      F : Adalin.Frame.Frame;

      --  Expected values from LIN 2.2 specification
      Expected : constant array (0 .. 63) of Bits2 :=
        (2#01#, 2#11#, 2#10#, 2#00#, 2#11#, 2#01#, 2#00#, 2#10#,
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
         SetFrameIdentifier (F, Adalin.Frame.Bits6 (Id));

         AUnit.Assertions.Assert
           (Expected (Id) = F.parity,
            "Calculate_FID_Parity ID="
            & Integer'Image (Id)
            & " "
            & Bits2'Image (Expected (Id))
            & " != "
            & Bits2'Image (F.parity));
      end loop;
   end Test_Calculate_FID_Parity;

   procedure Test_Calculate_Data_Checksum (T : in out Test_Case'Class) is
      pragma Unreferenced (T);

      F : Adalin.Frame.Frame;

      procedure run_test
        (mode : Mode_Type; ID : Bits6; data : Data_Array; expected : Byte) is
      begin
         SetFrameIdentifier (F, ID);
         SetData (F, data, mode);
         AUnit.Assertions.Assert
           (F.checksum = expected,
            "Calculate_Data_Checksum ("
            & mode'Image
            & ") failed for ID="
            & F.frame_identifier'Image
            & ": expected "
            & expected'Image
            & ", got "
            & F.checksum'Image);
      end run_test;
      tmp : Byte;
   begin
      --  Classic
      --  From the LIN 2.1 specification
      run_test (Classic, 0, (16#4a#, 16#55#, 16#93#, 16#e5#), 16#e6#);
      --  Remaining test vectors calculated
      --  using https://linchecksumcalculator.machsystems.cz
      run_test (Classic, 16#22#, (1 => 16#c5#), 16#3a#);
      run_test (Classic, 16#3b#, (16#66#, 16#cf#, 16#09#, 16#67#), 16#59#);
      run_test
        (Classic,
         16#1c#,
         (16#83#, 16#a2#, 16#bd#, 16#69#, 16#89#, 16#bd#, 16#22#, 16#09#),
         16#40#);
      --  Enhanced
      run_test (Enhanced, 16#22#, (1 => 16#c5#), 16#57#);
      run_test (Enhanced, 16#3b#, (16#66#, 16#cf#, 16#09#, 16#67#), 16#5d#);
      run_test
        (Enhanced,
         16#1c#,
         (16#83#, 16#a2#, 16#bd#, 16#69#, 16#89#, 16#bd#, 16#22#, 16#09#),
         16#e3#);
      --  Enhanced special case
      run_test (Enhanced, 16#3c#, (16#6d#, 16#6d#, 16#0b#, 16#3e#), 16#db#);
      run_test (Enhanced, 16#3d#, (16#6b#, 16#7f#, 16#7f#, 16#48#), 16#4d#);
   end Test_Calculate_Data_Checksum;

end Tests.Adalin_Frame;
