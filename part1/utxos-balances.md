# UXTOs & Balances

If you are a developer coming from Ethereum, the biggest practical difference is that QTUM's account model is built on Bitcoin's UXTOs.

In Ethereum, you'd typically have an account with an unique address that holds a balance. You'd be sending/receiving money and interacting with Smart Contracts using one account.

In QTUM, you don't really have accounts. Instead, you have a collection of UXTOs, each of which has its own address. An UXTO may be used only once when you send money or interact with a Smart Contract. If an UXTO has more value than you intend to use, it'd be splitted up into multiple UXTOs after a transaction.

In this chapter we'll explore the UXTO model by sending some money using the `qcli` command, and peeking into the transaction data.

Later in Part II we'll see how QTUM's Smart Contract implementation bridges Bitcoin's UXTO model with Ethereum's account model.

# UXTO Address

With UXTO, you *can* reuse a payment address. For better anonymity, though, you'd typically generate new addresses for each payment you'd like to receive.

Let's generate an address:

```
qcli getnewaddress
```

You get a new address:

```
qfsPCLrjjmqXptxWNXXg3wQruzC8bhPx63
```

Get as many as you want:

```
> qcli getnewaddress
qZWeFWECjKQ3KstHhCjxFj9hiM7jzXWw3p

> qcli getnewaddress
qJbSKruSXWnjSRZvSXMf2Y33gEw9FqHMHf

> qcli getnewaddress
qdiqg2mp646KhSQjVud3whv6C34hNHQnL2
```

An UXTO address is 20 bytes (160 bits) long, [base58 encoded](https://en.bitcoin.it/wiki/Base58Check_encoding). This is the same length as Ethereum's address. We can convert it to an Ethereum compatible hexadecimal address:

```
qcli gethexaddress qdiqg2mp646KhSQjVud3whv6C34hNHQnL2

dd2c6512563e4274dafd8312e0e738ede48f3046
```

And to convert it back to base58 UXTO address:

```
qcli fromhexaddress dd2c6512563e4274dafd8312e0e738ede48f3046

qdiqg2mp646KhSQjVud3whv6C34hNHQnL2
```

# Send Money Transaction

Now let's send money to an UXTO address. You'd be sending money to yourself, but this is exactly the same process as when you send money to somebody else.

First generate a new receiving address:

```
qcli getnewaddress

qdiqg2mp646KhSQjVud3whv6C34hNHQnL2
```

(You should replace the following commands with the address you've generated.)

Next, send 10 qtums to this address:

```
qcli sendtoaddress qdiqg2mp646KhSQjVud3whv6C34hNHQnL2 10
```

A transaction ID (txid) is returned for this transfer:

```
11e790d26d6996803960ef1586cbaeb54af20fd3e1f41508843c36f2ef60bb9d
```

Wait for a minute or two for the transaction be be confirmed. You should see something like this in the container's log:

```
07:25:54  qtumd | CTransaction(hash=11e790d26d, ver=2, vin.size=1, vout.size=2, nLockTime=1680)
07:25:54  qtumd |     CTxIn(COutPoint(5ada2447bc, 1), scriptSig=473044022063b61ff64f6340, nSequence=4294967294)
07:25:54  qtumd |     CScriptWitness()
07:25:54  qtumd |     CTxOut(nValue=19979.99832800, scriptPubKey=76a914dc41025b0c419681bffc3446)
07:25:54  qtumd |     CTxOut(nValue=10.00000000, scriptPubKey=76a914dd2c6512563e4274dafd8312)
```

Use `gettransaction` to get some general information about this transaction:

```
qcli gettransaction 11e790d26d6996803960ef1586cbaeb54af20fd3e1f41508843c36f2ef60bb9d

{
  "amount": 0.00000000,
  "fee": -0.00090400,
  "confirmations": 2,
  "blockhash": "63b646290e7924a15073b7a2b1bde9f35c40d8de73a15eeea00d80a3ee7f7f70",
  "blockindex": 2,
  "blocktime": 1513149968,
  "txid": "11e790d26d6996803960ef1586cbaeb54af20fd3e1f41508843c36f2ef60bb9d",
  "walletconflicts": [
  ],
  "time": 1513149954,
  "timereceived": 1513149954,
  "bip125-replaceable": "no",
  "details": [
    {
      "account": "",
      "address": "qdiqg2mp646KhSQjVud3whv6C34hNHQnL2",
      "category": "send",
      "amount": -10.00000000,
      "label": "",
      "vout": 1,
      "fee": -0.00090400,
      "abandoned": false
    },
    {
      "account": "",
      "address": "qdiqg2mp646KhSQjVud3whv6C34hNHQnL2",
      "category": "receive",
      "amount": 10.00000000,
      "label": "",
      "vout": 1
    }
  ],
  "hex": "02000000017d2c908ccf224c7204024699fa9bee9cafc4319297e3c682b2d2d4bc4724da5a010000006a473044022063b61ff64f63407a7ef1e2060d6f54cae987a10b30d20b55d722f69e0bcc225e0220340fa34885cb0bdf056067d90f16b53318d44861872635051963237623c63699012102dd47f2c6e005fdc2182135ffe72c985a095ca9c59000d7f1576ed8717ef6e017feffffff02e0fe1132d10100001976a914dc41025b0c419681bffc3446ee8b506dde59e18e88ac00ca9a3b000000001976a914dd2c6512563e4274dafd8312e0e738ede48f304688ac90060000"
}
```

This transaction had been confirmed twice so far:

```
"confirmations": 2,
```

Let's now use `listunspent` to list recently created UXTOs. List UXTOs that had been confirmed less than 20 times:

```
qcli listunspent 0 20

[
  {
    "txid": "11e790d26d6996803960ef1586cbaeb54af20fd3e1f41508843c36f2ef60bb9d",
    "vout": 0,
    "address": "qddyh9oMU44qZ28bEY9WhCDbmCaALVDr1k",
    "scriptPubKey": "76a914dc41025b0c419681bffc3446ee8b506dde59e18e88ac",
    "amount": 19989.99923200,
    "confirmations": 11,
    "spendable": true,
    "solvable": true
  },
  {
    "txid": "11e790d26d6996803960ef1586cbaeb54af20fd3e1f41508843c36f2ef60bb9d",
    "vout": 1,
    "address": "qdiqg2mp646KhSQjVud3whv6C34hNHQnL2",
    "account": "",
    "scriptPubKey": "76a914dd2c6512563e4274dafd8312e0e738ede48f304688ac",
    "amount": 10.00000000,
    "confirmations": 11,
    "spendable": true,
    "solvable": true
  }
]
```

Note that both of these UXTOs share the same txid. In other words, one send money transaction created two new UXTOs:

+ `qdiqg2mp646KhSQjVud3whv6C34hNHQnL2`: Receiving address, holding value of 10.
+ `qddyh9oMU44qZ28bEY9WhCDbmCaALVDr1k`: The original sender UXTO had 20k qtum, the amount generated. This a new UXTO created to hold the change, minus fees.

## Decoding Transaction Data

We can dig a little deeper into the transaction data to see that QTUM really shares the same UXTO data structure as Bitcoin. From the earlier `gettransaction` output, we got the raw transaction data in hexadecimals (i.e. `02000000017d2...ac90060000`).

Let's decode the transaction data:

```
qcli decoderawtransaction \
02000000017d2c908ccf224c7204024699fa9bee9cafc4319297e3c682b2d2d4bc4724da5a010000006a473044022063b61ff64f63407a7ef1e2060d6f54cae987a10b30d20b55d722f69e0bcc225e0220340fa34885cb0bdf056067d90f16b53318d44861872635051963237623c63699012102dd47f2c6e005fdc2182135ffe72c985a095ca9c59000d7f1576ed8717ef6e017feffffff02e0fe1132d10100001976a914dc41025b0c419681bffc3446ee8b506dde59e18e88ac00ca9a3b000000001976a914dd2c6512563e4274dafd8312e0e738ede48f304688ac90060000
```

The decoded transaction:

```
{
  "txid": "11e790d26d6996803960ef1586cbaeb54af20fd3e1f41508843c36f2ef60bb9d",
  "hash": "11e790d26d6996803960ef1586cbaeb54af20fd3e1f41508843c36f2ef60bb9d",
  "size": 225,
  "vsize": 225,
  "version": 2,
  "locktime": 1680,
  "vin": [
    {
      "txid": "5ada2447bcd4d2b282c6e3979231c4af9cee9bfa99460204724c22cf8c902c7d",
      "vout": 1,
      "scriptSig": {
        "asm": "3044022063b61ff64f63407a7ef1e2060d6f54cae987a10b30d20b55d722f69e0bcc225e0220340fa34885cb0bdf056067d90f16b53318d44861872635051963237623c63699[ALL] 02dd47f2c6e005fdc2182135ffe72c985a095ca9c59000d7f1576ed8717ef6e017",
        "hex": "473044022063b61ff64f63407a7ef1e2060d6f54cae987a10b30d20b55d722f69e0bcc225e0220340fa34885cb0bdf056067d90f16b53318d44861872635051963237623c63699012102dd47f2c6e005fdc2182135ffe72c985a095ca9c59000d7f1576ed8717ef6e017"
      },
      "sequence": 4294967294
    }
  ],
  "vout": [
    {
      "value": 19989.99923200,
      "n": 0,
      "scriptPubKey": {
        "asm": "OP_DUP OP_HASH160 dc41025b0c419681bffc3446ee8b506dde59e18e OP_EQUALVERIFY OP_CHECKSIG",
        "hex": "76a914dc41025b0c419681bffc3446ee8b506dde59e18e88ac",
        "reqSigs": 1,
        "type": "pubkeyhash",
        "addresses": [
          "qddyh9oMU44qZ28bEY9WhCDbmCaALVDr1k"
        ]
      }
    },
    {
      "value": 10.00000000,
      "n": 1,
      "scriptPubKey": {
        "asm": "OP_DUP OP_HASH160 dd2c6512563e4274dafd8312e0e738ede48f3046 OP_EQUALVERIFY OP_CHECKSIG",
        "hex": "76a914dd2c6512563e4274dafd8312e0e738ede48f304688ac",
        "reqSigs": 1,
        "type": "pubkeyhash",
        "addresses": [
          "qdiqg2mp646KhSQjVud3whv6C34hNHQnL2"
        ]
      }
    }
  ]
}
```

As you can see, this is a [Pay-to-PubkeyHash](https://en.bitcoin.it/wiki/Transaction#Pay-to-PubkeyHash) transaction!

# Summary

QTUM manages money using Bitcoin's UXTO model. Instead of using accounts to track balances, a QTUM wallet keeps track of the collection of UXTOs. When a transaction is created, the wallet searches the collection to find UXTOs that add up to enough value to pay for the amount transferred and the fees.
