with Tests.Adalin_Frame;

package body Tests.Adalin is
   T : aliased Tests.Adalin_Frame.Test;
   function Suite return Access_Test_Suite is
      Ret : constant Access_Test_Suite := new Test_Suite;

   begin
      Tests.Adalin_Frame.Register_Tests (T);
      Ret.Add_Test (T'Access);
      return Ret;
   end Suite;

end Tests.Adalin;