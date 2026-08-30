with AUnit;            use AUnit;
with AUnit.Test_Cases; use AUnit.Test_Cases;

package Tests.Adalin_Slave is

   type Test is new Test_Case with null record;

   overriding procedure Register_Tests (T : in out Test);
   overriding function Name (T : Test) return Message_String;

   --  Registration and queries
   procedure Test_Register_And_Count  (T : in out Test_Case'Class);
   procedure Test_Is_Ready            (T : in out Test_Case'Class);
   procedure Test_Get_Entry_Found     (T : in out Test_Case'Class);
   procedure Test_Get_Entry_Not_Found (T : in out Test_Case'Class);
   procedure Test_Register_Overflow   (T : in out Test_Case'Class);

   --  State machine - sync detection
   procedure Test_Initial_State_Is_Idle (T : in out Test_Case'Class);
   procedure Test_Non_Sync_Byte_Ignored (T : in out Test_Case'Class);
   procedure Test_Sync_Byte_Advances    (T : in out Test_Case'Class);

   --  State machine - PID handling
   procedure Test_Unknown_PID_Returns_Idle (T : in out Test_Case'Class);
   procedure Test_Bad_Parity_Returns_Idle  (T : in out Test_Case'Class);
   procedure Test_Subscribe_PID_Recv_Data  (T : in out Test_Case'Class);
   procedure Test_Publish_PID_Tx_Data      (T : in out Test_Case'Class);

   --  Full subscribe frames
   procedure Test_Subscribe_U8_Full_Frame  (T : in out Test_Case'Class);
   procedure Test_Subscribe_U16_Full_Frame (T : in out Test_Case'Class);
   procedure Test_Subscribe_Arr_Full_Frame (T : in out Test_Case'Class);

   --  Checksum and publish
   procedure Test_Bad_Checksum_No_Commit   (T : in out Test_Case'Class);
   procedure Test_Publish_Full_Frame       (T : in out Test_Case'Class);

   --  Sequencing
   procedure Test_Returns_To_Idle_After_Frame (T : in out Test_Case'Class);
   procedure Test_Two_Frames_In_Sequence      (T : in out Test_Case'Class);

end Tests.Adalin_Slave;