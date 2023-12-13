#:error_logger.tty(false)
Application.ensure_all_started(:uuid)
:error_logger.warning_msg("Halting :error_log for noisy syn messaging")
#:error_logger.tty(false)
require Logger
Logger.error("test")
context = Noizu.ElixirCore.CallingContext.system()
Noizu.AdvancedPool.Support.TestManager.runner_start([epmd: :tap], context)


Noizu.AdvancedPool.Support.TestManager.start_cluster([epmd: :tap], context)

ExUnit.start(capture_log: true)
