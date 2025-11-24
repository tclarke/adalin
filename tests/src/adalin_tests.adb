with AUnit.Run;
with AUnit.Reporter.Text;
with Tests.Adalin;

procedure Adalin_Tests is
   procedure Run is new AUnit.Run.Test_Runner (Tests.Adalin.Suite);
   Reporter : AUnit.Reporter.Text.Text_Reporter;
begin
   Run (Reporter);
end Adalin_Tests;