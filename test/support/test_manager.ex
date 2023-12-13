defmodule Noizu.AdvancedPool.Support.TestManager do

  def rebase(options) do
    if options[:epmd] == :tap do
      {"", 0} = System.cmd("epmd", ["-daemon"],[])
    end
    Node.start(:"nap_test_runner@localhost", :shortnames)
  end

  def start_cluster(options) do
    if options[:epmd] == :tap do
    {"", 0} = System.cmd("epmd", ["-daemon"],[])
    end

    ebs = %{id: :erl_boot_server, start: {:erl_boot_server, :start_link, [[]]}}
    opts = [strategy: :one_for_one, name: Noizu.AdvancedPool.TestSupervisor]
    Supervisor.start_link([ebs],opts)

    :slave.start(:localhost, :nap_test_member_a, "-setcookie #{Node.get_cookie()}" |> String.to_charlist())
    :slave.start(:localhost, :nap_test_member_b, "-setcookie #{Node.get_cookie()}" |> String.to_charlist())
    :slave.start(:localhost, :nap_test_member_c, "-setcookie #{Node.get_cookie()}" |> String.to_charlist())
    :slave.start(:localhost, :nap_test_member_d, "-setcookie #{Node.get_cookie()}" |> String.to_charlist())
    :slave.start(:localhost, :nap_test_member_e, "-setcookie #{Node.get_cookie()}" |> String.to_charlist())
    :rpc.call(:"nap_test_member_a@localhost", :code, :add_paths, [:code.get_path])
    :rpc.call(:"nap_test_member_b@localhost", :code, :add_paths, [:code.get_path])
    :rpc.call(:"nap_test_member_c@localhost", :code, :add_paths, [:code.get_path])
    :rpc.call(:"nap_test_member_d@localhost", :code, :add_paths, [:code.get_path])
    :rpc.call(:"nap_test_member_e@localhost", :code, :add_paths, [:code.get_path])
    
  end

end
