with AUnit; use AUnit;
with AUnit.Test_Cases; use AUnit.Test_Cases;

package Tests.Adalin_Signal is

   type Test is new Test_Case with null record;

   overriding
   procedure Register_Tests (T : in out Test);

   overriding
   function Name (T : Test) return Message_String;

   --  One test procedure per instantiation / concern for full coverage.

   --  Make: handle, name, default value, updated = False
   procedure Test_Make_Bool        (T : in out Test_Case'Class);
   procedure Test_Make_U8          (T : in out Test_Case'Class);
   procedure Test_Make_U16         (T : in out Test_Case'Class);
   procedure Test_Make_Byte_Array  (T : in out Test_Case'Class);

   --  Set_Value: new value stored, Is_Updated becomes True
   procedure Test_Set_Value_Bool        (T : in out Test_Case'Class);
   procedure Test_Set_Value_U8          (T : in out Test_Case'Class);
   procedure Test_Set_Value_U16         (T : in out Test_Case'Class);
   procedure Test_Set_Value_Byte_Array  (T : in out Test_Case'Class);

   --  Mask_To_Size: bits/bytes beyond declared size are discarded
   procedure Test_Mask_U8           (T : in out Test_Case'Class);
   procedure Test_Mask_U16          (T : in out Test_Case'Class);
   procedure Test_Mask_Byte_Array   (T : in out Test_Case'Class);
   procedure Test_Mask_Default_Value (T : in out Test_Case'Class);

   --  Clear_Updated: flag cleared, value and identity unchanged
   procedure Test_Clear_Updated_Bool        (T : in out Test_Case'Class);
   procedure Test_Clear_Updated_U8          (T : in out Test_Case'Class);
   procedure Test_Clear_Updated_U16         (T : in out Test_Case'Class);
   procedure Test_Clear_Updated_Byte_Array  (T : in out Test_Case'Class);

   --  Set_Value called twice: latest value wins, flag stays set
   procedure Test_Overwrite_Value (T : in out Test_Case'Class);

   --  Round-trip: Set_Value then Clear_Updated then Set_Value again
   procedure Test_Round_Trip (T : in out Test_Case'Class);

end Tests.Adalin_Signal;
