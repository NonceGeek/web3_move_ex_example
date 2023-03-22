defmodule Web3MoveExExample do
  @moduledoc """
    An Example that shows how to use the web3_move_ex library!
  """
  alias Web3MoveEx.Aptos
  import Web3MoveEx.Aptos

  def gen_acct_and_get_faucet(network_type) do
    {:ok, acct} = Aptos.generate_keys()
    {:ok, client} = Aptos.connect(network_type)
    {:ok, _res} = Aptos.get_faucet(client, acct)
    Process.sleep(2000)  # 用 2 秒等待交易成功
    %{res: Aptos.get_balance(client, acct), acct: acct}
  end

  def call_fun_init(client, acct, contract_addr,  did_type, description) do
    {:ok, f} = gen_func_init(contract_addr)
    payload = Aptos.call_function(f, [], [did_type, description])
    {:ok, %{hash: hash} = tx} = Aptos.submit_txn_with_auto_acct_updating(client, acct, payload)
    Process.sleep(2000)  # 用 2 秒等待交易成功
    res = Aptos.check_tx_res_by_hash(client, hash)
    %{res: res, tx: tx}
  end
  def gen_func_init(contract_addr) do
    init_func_str = "#{contract_addr}::init::init(u64, string)"
    ~a"#{init_func_str}"
  end
end
