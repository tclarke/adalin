package Adalin.Slave is

   type Slave is abstract tagged null record;

   procedure sys_irq_disable (Self : in out Slave) is abstract;

	procedure sys_irq_restore (Self : in out Slave) is abstract;

private
   type LinState_Type is (
      off,
      detected_break,
      wait_sync_byte,
      get_id,
      get_data,
      get_chksm,
      reply_to_id_empty_and_terminate,
      empty_and_terminate,
      empty_and_terminate_wrongchecksum,
      empty_and_terminate_timeout,
      empty_and_terminate_no_id_match
   );

   type SlaveState_Type is (
      frame_processing,
      frame_valid,
      frame_slot_timeout,
      frame_wrong_checksum,
      frame_no_id_match,
      frame_id_replied
   );

   type BreakState_Type is (
      waiting,
      pindown_indicated,
      valid
   );

end Adalin.Slave;