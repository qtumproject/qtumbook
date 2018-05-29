# QTUM Command Line Client

The `qtum-cli` tool is based on `bitcoin-cli`. Many command are inherited from [Bitcoin API calls](https://en.bitcoin.it/wiki/Original_Bitcoin_client/API_calls_list#References).

List all available commands:

```
qcli help

== Blockchain ==
callcontract "address" "data" ( address )
getaccountinfo "address"
getbestblockhash
getblock "blockhash" ( verbose )
getblockchaininfo
getblockcount
getblockhash height
getblockheader "hash" ( verbose )
getchaintips

...more
```

To support the EVM smart contract, there are a few QTUM specific commands:

```
callcontract "address" "data" ( address )
listcontracts (start maxDisplay)
createcontract "bytecode" (gaslimit gasprice "senderaddress" broadcast)
sendtocontract "contractaddress" "data" (amount gaslimit gasprice senderaddress broadcast)
```

## 🚫 Account (Deprecated) 🚫

The Bitcoin provided API to [organize addresses by "account"](https://en.bitcoin.it/wiki/Help:Accounts_explained) in its local wallet:

```
qcli help | grep account

getaccountinfo "address"
addmultisigaddress nrequired ["key",...] ( "account" )
getaccount "address"
getaccountaddress "account"
getaddressesbyaccount "account"
getbalance ( "account" minconf include_watchonly )
getnewaddress ( "account" )
getreceivedbyaccount "account" ( minconf )
listaccounts ( minconf include_watchonly)
listreceivedbyaccount ( minconf include_empty include_watchonly)
listtransactions ( "account" count skip include_watchonly)
move "fromaccount" "toaccount" amount ( minconf "comment" )
sendfrom "fromaccount" "toaddress" amount ( minconf "comment" "comment_to" )
sendmany "fromaccount" {"address":amount,...} ( minconf "comment" ["address",...] )
sendmanywithdupes "fromaccount" {"address":amount,...} ( minconf "comment" ["address",...] )
setaccount "address" "account"
```

This account feature is deprecated, please don't use it.

## Help For Specific Command

There are detailed documentation for most commands. Let's look at the help message for `listsinceblock`:

```
Get all transactions in blocks since block [blockhash], or all transactions if omitted

Arguments:
1. "blockhash"            (string, optional) The block hash to list transactions since
2. target_confirmations:    (numeric, optional) The confirmations required, must be 1 or more
3. include_watchonly:       (bool, optional, default=false) Include transactions to watch-only addresses (see 'importaddress')

Result:
{
  "transactions": [
    "account":"accountname",       (string) DEPRECATED. The account name associated with the transaction. Will be "" for the default account.
    "address":"address",    (string) The qtum address of the transaction. Not present for move transactions (category = move).
    ...
  ],
  "lastblock": "lastblockhash"     (string) The hash of the last block
}

Examples:
> qtum-cli listsinceblock
> qtum-cli listsinceblock "000000000000000bacf66f7497b7dc45ef753ee9a7d38571037cdb1a57f663ad" 6
> curl --user myusername --data-binary '{"jsonrpc": "1.0", "id":"curltest", "method": "listsinceblock", "params": ["000000000000000bacf66f7497b7d
c45ef753ee9a7d38571037cdb1a57f663ad", 6] }' -H 'content-type: text/plain;' http://127.0.0.1:3889/
```

