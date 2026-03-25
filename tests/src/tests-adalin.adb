with Tests.Adalin_Frame;
with Tests.Adalin_Core;
with Tests.Adalin_Signal;

package body Tests.Adalin is
   Frame  : aliased Tests.Adalin_Frame.Test;
   Core   : aliased Tests.Adalin_Core.Test;
   Signal : aliased Tests.Adalin_Signal.Test;

   function Suite return Access_Test_Suite is
      Ret : constant Access_Test_Suite := new Test_Suite;
   begin
      Tests.Adalin_Frame.Register_Tests (Frame);
      Ret.Add_Test (Frame'Access);
      Tests.Adalin_Core.Register_Tests (Core);
      Ret.Add_Test (Core'Access);
      Tests.Adalin_Signal.Register_Tests (Signal);
      Ret.Add_Test (Signal'Access);
      return Ret;
   end Suite;

end Tests.Adalin;
