# Inspect Raw Transaction

In this chapter we will examine the raw transaction data to understand how payment transactions work.

In particular:

0. How the sender construct a transaction to express how much money transfer, and to whom
1. How the sender proves ownership of an UTXO
2. How the sender creates new UTXO as payment, and make sure that only the intended receiver can cliam it

# Money Transfer

Let's generate a new address to receive fund

```
qcli getnewaddress

qNUAQzJCy4UZXTsUWLdBsgMDfS8yF4nuGD
```

For testing, let's send some money from our own wallet to this address:

```
qcli sendtoaddress qNUAQzJCy4UZXTsUWLdBsgMDfS8yF4nuGD 10
```

The transaction id is returned:

```
f2cb9a0cac73b7bf9dd1ba2fcfddfe91ae2f6d1e8083f8a848e61427a85d830d
```

Once the transaction is confirmed, we can see that the receiving address has money:

```
qcli getreceivedbyaddress qNUAQzJCy4UZXTsUWLdBsgMDfS8yF4nuGD

10.00000000
```

# Look Up The Send Transaction

Use the transaction id to look up information about it:

```
qcli gettransaction \
  f2cb9a0cac73b7bf9dd1ba2fcfddfe91ae2f6d1e8083f8a848e61427a85d830d
```

```json
{
  "amount": 0.00000000,
  "fee": -0.00076800,
  "confirmations": 4,
  "blockhash": "f7567e97f8c7d0145592b04f9913b1005226913b391f55428accce1624ddd871",
  "blockindex": 2,
  "blocktime": 1523947568,
  "txid": "f2cb9a0cac73b7bf9dd1ba2fcfddfe91ae2f6d1e8083f8a848e61427a85d830d",
  "walletconflicts": [
  ],
  "time": 1523947557,
  "timereceived": 1523947557,
  "bip125-replaceable": "no",
  "details": [
    {
      "account": "",
      "address": "qNUAQzJCy4UZXTsUWLdBsgMDfS8yF4nuGD",
      "category": "send",
      "amount": -10.00000000,
      "label": "",
      "vout": 1,
      "fee": -0.00076800,
      "abandoned": false
    },
    {
      "account": "",
      "address": "qNUAQzJCy4UZXTsUWLdBsgMDfS8yF4nuGD",
      "category": "receive",
      "amount": 10.00000000,
      "label": "",
      "vout": 1
    }
  ],
  "hex": "0200000001a65a0dad79515e70b2ee1406aa0bc083704b4d4a7528d7d4511210d6abbcb93902000000494830450221008c2f779baa08239d707f758068346b15b4c3b6a0cfc7ccb361bcc69f01eebfb2022018f2e38074c2f8673ebcb30358da6822c30a74a26b7feb852bab44e4ec5c40dd01feffffff02002aae6dd10100001976a914722b74ca801e90be5240d2f084440d71c3c2572488ac00ca9a3b000000001976a91435dbe99b7be1e43463e0fec2d431b67bcc6ef67e88ac98040000"
}
```

# Deciphering The Raw Transaction

The `gettransaction` command presents the transaction data in a more human friendly form. We can see the underlying bitcoin data structure by decoding the raw data of a transaction.

This data structure is key to understanding how the bitcoin ledger works.

The `hex` property returned previously is the raw transaction data. Or we could also look it up with `getrawtransaction`:

```
qcli getrawtransaction f2cb9a0cac73b7bf9dd1ba2fcfddfe91ae2f6d1e8083f8a848e61427a85d830d
```

Let's now decode the raw tx data:

```
qcli decoderawtransaction \
0200000001a65a0dad79515e70b2ee1406aa0bc083704b4d4a7528d7d4511210d6abbcb93902000000494830450221008c2f779baa08239d707f758068346b15b4c3b6a0cfc7ccb361bcc69f01eebfb2022018f2e38074c2f8673ebcb30358da6822c30a74a26b7feb852bab44e4ec5c40dd01feffffff02002aae6dd10100001976a914722b74ca801e90be5240d2f084440d71c3c2572488ac00ca9a3b000000001976a91435dbe99b7be1e43463e0fec2d431b67bcc6ef67e88ac98040000
```

```
{
  "txid": "f2cb9a0cac73b7bf9dd1ba2fcfddfe91ae2f6d1e8083f8a848e61427a85d830d",
  "hash": "f2cb9a0cac73b7bf9dd1ba2fcfddfe91ae2f6d1e8083f8a848e61427a85d830d",
  "size": 192,
  "vsize": 192,
  "version": 2,
  "locktime": 1176,
  "vin": [
    {
      "txid": "39b9bcabd6101251d4d728754a4d4b7083c00baa0614eeb2705e5179ad0d5aa6",
      "vout": 2,
      "scriptSig": {
        "asm": "30450221008c2f779baa08239d707f758068346b15b4c3b6a0cfc7ccb361bcc69f01eebfb2022018f2e38074c2f8673ebcb30358da6822c30a74a26b7feb852bab44e4ec5c40dd[ALL]",
        "hex": "4830450221008c2f779baa08239d707f758068346b15b4c3b6a0cfc7ccb361bcc69f01eebfb2022018f2e38074c2f8673ebcb30358da6822c30a74a26b7feb852bab44e4ec5c40dd01"
      },
      "sequence": 4294967294
    }
  ],
  "vout": [
    {
      "value": 19989.99923200,
      "n": 0,
      "scriptPubKey": {
        "asm": "OP_DUP OP_HASH160 722b74ca801e90be5240d2f084440d71c3c25724 OP_EQUALVERIFY OP_CHECKSIG",
        "hex": "76a914722b74ca801e90be5240d2f084440d71c3c2572488ac",
        "reqSigs": 1,
        "type": "pubkeyhash",
        "addresses": [
          "qTy4FHpEsGkwXGfzSUDirCQf8RCHsJSPhH"
        ]
      }
    },
    {
      "value": 10.00000000,
      "n": 1,
      "scriptPubKey": {
        "asm": "OP_DUP OP_HASH160 35dbe99b7be1e43463e0fec2d431b67bcc6ef67e OP_EQUALVERIFY OP_CHECKSIG",
        "hex": "76a91435dbe99b7be1e43463e0fec2d431b67bcc6ef67e88ac",
        "reqSigs": 1,
        "type": "pubkeyhash",
        "addresses": [
          "qNUAQzJCy4UZXTsUWLdBsgMDfS8yF4nuGD"
        ]
      }
    }
  ]
}
```

This transaction has one vins (input value) and two vouts (output values).

### Transaction Vins

When constructing a transaction, the wallet finds an UTXO that satifies the amount requested.

The input refers to an UTXO, which is the second output of the transaction `39b9...5aa6`. This particular UTXO is worth 20,000.

Since we are only sending 10 qtums, this input is more than enough pay for the transfer itself, as well as the fees.

### Transaction Vouts

The UTXO used is worth 20,000, but we actually only want to spend a smart part of it. Unlike a bank account, it is not possible to partially spend the value of the UTXO.

So what we do is that we spend 10 qtums by sending it to the receiving address, and "spend" the rest of the amount by sending it back to ourself.

The result is that are two outputs in this transaction, creating two new UTXOs.

+ 19989.99923200 is the change returning to sender.
+ 10 is the amount sent to receiver.

### Transaction Fee

The sum of the two outputs is less than the input.

```
20000 - 19989.99923200 - 10 = 0.000768000
```

This difference is given to the miner as the fee.

# Cryptographic Proof of Ownership

By decoding the raw transaction, we can see that Vins and Vouts specifies where the money come from, and where it should go.

But how does the network know who has the authority to spend what money?

In the old financial world, the bank acts as the authority that decides whether a transaction can go through. Bitcoin, however, uses cryptogrpahy to distribute the authority to its end users.

The "authority" to spend money is like a uniquely shaped lock. If a person can present the key that has the correct shape to unlock it, the network then allows the money to be spent.


* The sender must have the key to unlock the UTXOs used as inputs.
* The sender create new locks as outputs, that only the receiver can unlock.

# BTC Standard Pay Scripts

The cryptographic "lock" alluded to are just simple fragments of BTC scripts. The sender needs to provide the correct input, so the script evaluates to true.

## Pay To Public Key

The UTXO that's used as input is the second output of the transaction `39b9bcabd6101251d4d728754a4d4b7083c00baa0614eeb2705e5179ad0d5aa6`. Let's decode that transaction:

```
qcli decoderawtransaction \
  `qcli getrawtransaction 39b9bcabd6101251d4d728754a4d4b7083c00baa0614eeb2705e5179ad0d5aa6`
```

The data for this UTXO is:

```
{
  // ...
  "vout": [
    // ...
    {
      "value": 20000.00000000,
      "n": 2,
      "scriptPubKey": {
        "asm": "03795cd550a584caf7818cbe2d71cbc05bbf59fdb6bacb876969b319c4d07a0211 OP_CHECKSIG",
        "hex": "2103795cd550a584caf7818cbe2d71cbc05bbf59fdb6bacb876969b319c4d07a0211ac",
        "reqSigs": 1,
        "type": "pubkey",
        "addresses": [
          "qNdjKvCjBLUwb2RuWxEXLSgpVtLSanQ7Cu"
        ]
      }
    }
  ]
}
```

The "lock" is the script:

```
03795cd550a584caf7818cbe2d71cbc05bbf59fdb6bacb876969b319c4d07a0211
OP_CHECKSIG
```

This script says that whoever that can produce a cryptographic signature attributable to the public key "03795cd550a584caf7818cbe2d71cbc05bbf59fdb6bacb876969b319c4d07a0211" may spend this output.

To unlock the script, the sender creates a cryptographic signature that signs the outputs (i.e. how much money and to whom).

The script is the lock, and signature is the key. Combine the two, we get a script that evaluates to "true":

```
30450221008c2f779baa08239d707f758068346b15b4c3b6a0cfc7ccb361bcc69f01eebfb2022018f2e38074c2f8673ebcb30358da6822c30a74a26b7feb852bab44e4ec5c40dd[ALL]

03795cd550a584caf7818cbe2d71cbc05bbf59fdb6bacb876969b319c4d07a0211

OP_CHECKSIG
```

The [OP_CHECKSIG](https://bitcoin.org/en/developer-reference#opcodes) operation does two things:

1. It verifies that the signature is attributable to the public key `03795cd550a584caf7818cbe2d71cbc05bbf59fdb6bacb876969b319c4d07a0211`
2. Verifies the transaction outputs against the signature. If a miner tries to tamper with the outputs in anyway (adjusting the amount of recipient), the check would fail.

A Pay-To-Public-Key UTXOs are typically created as mining/staking rewards and gas refunds. For payment to addresses, another type of script is more frequently seen.

## Pay To Public Hash

When sending money to an address, the output created is usually a "Pay To Public Hash" (P2PKH) script.

In the raw transaction above we see that an output has a script like this:

```
OP_DUP
OP_HASH160
35dbe99b7be1e43463e0fec2d431b67bcc6ef67e
OP_EQUALVERIFY
OP_CHECKSIG
```

This script is essentially saying "whoever that can create a signature attributable to a public key that hashes to 35dbe99b7be1e43463e0fec2d431b67bcc6ef67e can spend this output".

This script is the same as `Pay To Public Key`, except for the extra indirection introduced by the public key hashing.

See [pay to public hash validation](https://bitcoin.org/en/developer-guide#p2pkh-script-validation) for details on how this type of script can be validated.
