defmodule Web3MoveExExample do
  @moduledoc """
    An Example that shows how to use the web3_move_ex library!
  """
  alias Web3AptosEx.Aptos
  import Web3AptosEx.Aptos
  require Logger

  @testnet_contract_addr "0xc71124a51e0d63cfc6eb04e690c39a4ea36774ed4df77c00f7cbcbc9d0505b2c"


  # def gen_acct_and_get_faucet(network_type) do
  #   {:ok, acct} = Aptos.generate_keys()
  #   {:ok, client} = Aptos.connect(network_type)
  #   {:ok, _res} = Aptos.get_faucet(client, acct)
  #   Process.sleep(2000)  # 用 2 秒等待交易成功
  #   %{res: Aptos.get_balance(client, acct), acct: acct}
  # end

  # +------+
  # | init |
  # +------+

  def call_func_init(client, acct, contract_addr, did_type, description) do
    do_call_func(client, acct, contract_addr, "init", "init", [did_type, description], [:u64, :string])
  end

  # +--------------------+
  # | address_aggregator |
  # +--------------------+

  # TODO.

  # +--------------------+
  # | service_aggregator |
  # +--------------------+

  @doc """
    generate a new acct and run all the funs in services module.
  """
  def test_services_module(contract_addr \\ @testnet_contract_addr) do
    # init acct
    {:ok, acct} = Aptos.generate_keys()
    {:ok, client} = Aptos.RPC.connect("https://fullnode.testnet.aptoslabs.com/v1")
    {:ok, _tx_id} = Aptos.get_faucet(client, acct)
    Logger.info("acct.addr generated random: #{acct.address_hex}")
    Logger.info("acct.priv generated random: #{acct.priv_key_hex}")
    Process.sleep(2000)  # 用 2 秒等待交易成功

    # +-----------------------+
    # | test init aggregators |
    # +-----------------------+
    # init aggregators
    call_func_init(client, acct, contract_addr, 0, "a Test DID.")
    Process.sleep(2000)  # 用 2 秒等待交易成功

    # check init events are success added.
    {:ok, events_create_addr_aggr} = Aptos.RPC.get_events(
      client,
      contract_addr,
      "#{contract_addr}::addr_aggregator::CreateAddrAggregatorEventSet",
      "create_addr_aggregator_events")
    res = Enum.find(events_create_addr_aggr, fn %{data: payload} ->
      payload.key_addr == acct.address_hex
    end)
    Logger.info("create_addr_aggregator_events: #{inspect(res)}")

    {:ok, events_create_addr_aggr} = Aptos.RPC.get_events(
      client,
      contract_addr,
      "#{contract_addr}::service_aggregator::CreateServiceAggregatorEventSet",
      "create_service_aggregator_events")
    res = Enum.find(events_create_addr_aggr, fn %{data: payload} ->
      payload.key_addr == acct.address_hex
    end)
    Logger.info("create_service_aggregator_events: #{inspect(res)}")

    # get services resources now.
    {:ok,
      %{
        data:
        %{
          add_service_events: %{counter: add_service_counter_now},
          update_service_events: %{counter: update_service_counter_now},
          delete_service_events: %{counter: delete_service_counter_now},
          services_map: %{handle: handle_key}}
      }
    } =
    Aptos.get_resource(client, acct, "#{contract_addr}::service_aggregator::ServiceAggregator")
    Logger.info("add_service_events counter when init: #{add_service_counter_now}")
    Logger.info("update_service_events counter when init: #{update_service_counter_now}")
    Logger.info("delete_service_events counter when init: #{delete_service_counter_now}")

    # +-------------------+
    # | add_service check |
    # +-------------------+
    call_func_add_service(
      client,
      acct,
      contract_addr,
      "github",
      "a github acct",
      "https://github.com/leeduckgo",
      "todo",
      "{\"str\": \"str\"}",
      0)

    Process.sleep(2000)  # 用 2 秒等待交易成功

    {:ok,
      %{
        data: %{add_service_events: %{counter: add_service_counter_after}}
      }
    } =
    Aptos.get_resource(client, acct, "#{contract_addr}::service_aggregator::ServiceAggregator")

    Logger.info("add_service_events counter after add service: #{add_service_counter_after}")

    # get item to make sure resource is correct.
    {:ok,
      %{
        description: "a github acct",
        expired_at: "0",
        spec_fields: "{\"str\": \"str\"}",
        url: "https://github.com/leeduckgo",
        verification_url: "todo"
      }
    } =
    Web3AptosEx.Aptos.get_table_item(
      client,
      handle_key,
      "0x1::string::String",
      "#{contract_addr}::service_aggregator::Service",
      "github"
    )

    # get event to make sure event is correct.
    {:ok,
      [
        %{
          data: %{
            description: "a github acct",
            expired_at: "0",
            name: "github",
            spec_fields: "{\"str\": \"str\"}",
            url: "https://github.com/leeduckgo",
            verification_url: "todo"
          }
        }
      ]
    } = Aptos.RPC.get_events(
      client,
      acct,
      "#{contract_addr}::service_aggregator::ServiceAggregator",
      "add_service_events")

    # +----------------------+
    # | update_service check |
    # +----------------------+

    call_func_update_service(
      client,
      acct,
      contract_addr,
      "github",
      "a github acct",
      "https://github.com/leeduckgo",
      "todotodo",
      "{\"str\": \"str\"}",
      100)

    Process.sleep(2000)  # 用 2 秒等待交易成功

    {:ok,
    %{
      data: %{update_service_events: %{counter: update_service_counter_after}}
    }
    } =
    Aptos.get_resource(client, acct, "#{contract_addr}::service_aggregator::ServiceAggregator")

    Logger.info("update_service_events counter after update service: #{update_service_counter_after}")

    # get item to make sure resource is correct.
    {:ok,
      %{
        description: "a github acct",
        expired_at: "100",
        spec_fields: "{\"str\": \"str\"}",
        url: "https://github.com/leeduckgo",
        verification_url: "todotodo"
      }
    } = Web3AptosEx.Aptos.get_table_item(
      client,
      handle_key,
      "0x1::string::String",
      "#{contract_addr}::service_aggregator::Service",
      "github"
    )

    # get event to make sure event is correct.
    {:ok,
    [
      %{
        data: %{
          description: "a github acct",
          expired_at: "100",
          name: "github",
          spec_fields: "{\"str\": \"str\"}",
          url: "https://github.com/leeduckgo",
          verification_url: "todotodo"
        }
      }
    ]
  } = Aptos.RPC.get_events(
    client,
    acct,
    "#{contract_addr}::service_aggregator::ServiceAggregator",
    "update_service_events")

  # +---------------------+
  # |delete service check |
  # +---------------------+

  call_func_delete_service(
    client,
    acct,
    contract_addr,
    "github")

  Process.sleep(2000)  # 用 2 秒等待交易成功

  {:ok,
  %{
    data: %{delete_service_events: %{counter: delete_service_counter_after}}
  }
  } =
  Aptos.get_resource(client, acct, "#{contract_addr}::service_aggregator::ServiceAggregator")

  Logger.info("delete_service_events counter after delete service: #{delete_service_counter_after}")
    {:ok, %{data: %{names: names}}} =
  Aptos.get_resource(client, acct, "#{contract_addr}::service_aggregator::ServiceAggregator")
  Logger.info("keys should be empty: #{inspect(names)}")

  # +--------------------------+
  # | batch_add_services check |
  # +--------------------------+

  %{
    res: true
  } =
    call_func_batch_add_services(
      client,
      acct,
      contract_addr,
      ["twitter", "youtube"],
      ["is twitter", "is youtube"],
      ["https://twitter.com/leeduckgo", "https://youtube.com/leeduckgo"],
      ["buzz", "bizz"],
      ["{\"str\": \"str\"}", "{\"buzz\": \"buzz\"}"],
      [100, 1000]
    )

  Process.sleep(2000)  # 用 2 秒等待交易成功
  {:ok, res} =
    Web3AptosEx.Aptos.get_table_item(
      client,
      handle_key,
      "0x1::string::String",
      "#{contract_addr}::service_aggregator::Service",
      "twitter"
    )
  Logger.info("resources after batch add services(it should be twitter & youtube here): #{inspect(res)}")

  {:ok, res} =
    Web3AptosEx.Aptos.get_table_item(
      client,
      handle_key,
      "0x1::string::String",
      "#{contract_addr}::service_aggregator::Service",
      "youtube"
    )
  Logger.info("resources after batch add services(it should be twitter & youtube here): #{inspect(res)}")

  {:ok, events} = Aptos.RPC.get_events(
    client,
    acct,
    "#{contract_addr}::service_aggregator::ServiceAggregator",
    "add_service_events")

  Logger.info("events after batch add services(it should be twitter & youtube here): #{inspect(events)}")

  # +-----------------------------+
  # | batch_update_services check |
  # +-----------------------------+

  %{
    res: true
  } =
    call_func_batch_update_services(
      client,
      acct,
      contract_addr,
      ["twitter", "youtube"],
      ["is twitter, aha", "is youtube, aha"],
      ["https://twitter.com/leeduckgo3", "https://youtube.com/leeduckgo3"],
      ["buzzbuzz", "bizzbizz"],
      ["{\"buzz\": \"buzz\"}", "{\"bizz\": \"bizz\"}"],
      [10000, 10000]
    )

    Process.sleep(2000)  # 用 2 秒等待交易成功
    {:ok, res} =
      Web3AptosEx.Aptos.get_table_item(
        client,
        handle_key,
        "0x1::string::String",
        "#{contract_addr}::service_aggregator::Service",
        "twitter"
      )
    Logger.info("resources after batch update services(it should be twitter & youtube here): #{inspect(res)}")

    {:ok, res} =
      Web3AptosEx.Aptos.get_table_item(
        client,
        handle_key,
        "0x1::string::String",
        "#{contract_addr}::service_aggregator::Service",
        "youtube"
      )
    Logger.info("resources after batch update services(it should be twitter & youtube here): #{inspect(res)}")

    {:ok, events} = Aptos.RPC.get_events(
      client,
      acct,
      "#{contract_addr}::service_aggregator::ServiceAggregator",
      "update_service_events")

    Logger.info("events after batch update services(it should be twitter & youtube here): #{inspect(events)}")
  end

  @doc """
      public entry fun add_service(
        acct: &signer,
        name: String,
        description: String,
        url: String,
        verification_url: String,
        spec_fields: String,
        expired_at: u64
    ) acquires ServiceAggregator {
        ……
    }
  """
  def call_func_add_service(client, acct, contract_addr, name, description, url, verification_url, spec_fields, expired_at) do
    do_call_func(
      client,
      acct,
      contract_addr,
      "service_aggregator",
      "add_service",
      [name, description, url, verification_url, spec_fields, expired_at],
      ["string", "string", "string", "string", "string", "u64"]
    )
  end

  def call_func_update_service(client, acct, contract_addr, name, new_description, new_url, new_verification_url, new_spec_fields, new_expired_at) do
    do_call_func(
      client,
      acct,
      contract_addr,
      "service_aggregator",
      "update_service",
      [name, new_description, new_url, new_verification_url, new_spec_fields, new_expired_at],
      ["string", "string", "string", "string", "string", "u64"]
    )
  end

  @doc """
    public entry fun batch_update_services(
     acct: &signer,
        names: vector<String>,
        descriptions: vector<String>,
        urls: vector<String>,
        verification_urls: vector<String>,
        spec_fieldss: vector<String>,
        expired_ats: vector<u64>) acquires ServiceAggregator {
          ……
        }
  """
  def call_func_batch_update_services(client, acct, contract_addr, names, descriptions, urls, verification_urls, spec_fieldss, expired_ats) do
    do_call_func(
      client,
      acct,
      contract_addr,
      "service_aggregator",
      "batch_update_services",
      [names, descriptions, urls, verification_urls, spec_fieldss, expired_ats],
      ["vector<string>", "vector<string>", "vector<string>", "vector<string>", "vector<string>", "vector<u64>"]
    )
  end

  @doc """
    public entry fun batch_add_services(
     acct: &signer,
        names: vector<String>,
        descriptions: vector<String>,
        urls: vector<String>,
        verification_urls: vector<String>,
        spec_fieldss: vector<String>,
        expired_ats: vector<u64>) acquires ServiceAggregator {
          ……
        }
  """
  def call_func_batch_add_services(client, acct, contract_addr, names, descriptions, urls, verification_urls, spec_fieldss, expired_ats) do
    do_call_func(
      client,
      acct,
      contract_addr,
      "service_aggregator",
      "batch_add_services",
      [names, descriptions, urls, verification_urls, spec_fieldss, expired_ats],
      ["vector<string>", "vector<string>", "vector<string>", "vector<string>", "vector<string>", "vector<u64>"]
    )
  end


  @doc """
    // Public entry fun delete service.
    public entry fun delete_service(
        acct: &signer,
        name: String) acquires ServiceAggregator {
          ……
        }
  """
  def call_func_delete_service(client, acct, contract_addr, name) do
    do_call_func(
      client,
      acct,
      contract_addr,
      "service_aggregator",
      "delete_service",
      [name],
      ["string"]
    )
  end

  # +-------+
  # | utils |
  # +-------+
  def do_call_func(client, acct, contract_addr, module_name, func_name, args, arg_types) do
    {:ok, f} = gen_func(contract_addr, module_name, func_name, arg_types)
    payload = Aptos.call_function(f, [], args)
    {:ok, %{hash: hash} = tx} = Aptos.submit_txn_with_auto_acct_updating(client, acct, payload)
    Process.sleep(2000)  # 用 2 秒等待交易成功
    res = Aptos.check_tx_res_by_hash(client, hash)
    %{res: res, tx: tx}
  end

  def gen_func(contract_addr, module_name, func_name, arg_types) do
    types = arg_types_to_arg_string(arg_types)
    init_func_str = "#{contract_addr}::#{module_name}::#{func_name}(#{types})"
    ~a"#{init_func_str}"
  end

  def arg_types_to_arg_string(arg_types) do
    arg_types_reduce_first_ele = Enum.drop(arg_types, 1)
    Enum.reduce(
      arg_types_reduce_first_ele,
      Enum.at(arg_types, 0),
      fn x, acc -> "#{acc}, #{x}"
    end)
  end

  def gen_func_init(contract_addr) do
    init_func_str = "#{contract_addr}::init::init(u64, string)"
    ~a"#{init_func_str}"
  end

end
