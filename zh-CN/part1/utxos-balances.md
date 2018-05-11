# UTXOs & 余额

如果你之前是一个以太坊的开发者，那么QTUM和以太坊开发实际最大的区别就是QTUM的账户模型是基于比特币的UTXOs。

在以太坊中，通常会有一个账户，该账户对应一个唯一的地址并且记录着账户的余额。可以通过账户来发送/接收资金以及和智能合约进行交互。

在QTUM中，用户没有账户，而是许多的UTXO，每个UTXO都有一个对应的地址。在发送资金或与智能合约交互时，一个UTXO只能使用一次。如果一个UTXO中的资金数量大于用户想要使用的资金数量，那么在一个交易后该UTXO会被分成多个UTXO。

本章中，我们将通过使用`qcli`命令发送资金来探索UTXO模型，并且查看交易数据。

在第二部分中，我们将看到QTUM智能合约实现是如何将比特币的UTXO模型和以太坊的账户模型连接起来的。

# UTXO地址

在UTXO模型中，用户可以重用一个支付地址。但是，为了更好的匿名性，用户通常会为每个期望收到的支付生成新的地址。

首先生成一个地址：

```
qcli getnewaddress
```

这样就得到一个新的地址：

```
qfsPCLrjjmqXptxWNXXg3wQruzC8bhPx63
```

可以根据需要生成任意多个地址：

```
> qcli getnewaddress
qZWeFWECjKQ3KstHhCjxFj9hiM7jzXWw3p

> qcli getnewaddress
qJbSKruSXWnjSRZvSXMf2Y33gEw9FqHMHf

> qcli getnewaddress
qdiqg2mp646KhSQjVud3whv6C34hNHQnL2
```

一个UTXO地址的长度是20字节(160比特)，[base58 encoded](https://en.bitcoin.it/wiki/Base58Check_encoding)，和以太坊地址的长度一样。可以将它转换为以太坊兼容的十六进制地址：

```
qcli gethexaddress qdiqg2mp646KhSQjVud3whv6C34hNHQnL2

dd2c6512563e4274dafd8312e0e738ede48f3046
```

也可以将它转换回base58编码的UTXO地址：

```
qcli fromhexaddress dd2c6512563e4274dafd8312e0e738ede48f3046

qdiqg2mp646KhSQjVud3whv6C34hNHQnL2
```

# 发送资金交易

现在我们开始把资金发送到一个UTXO地址上。可以把资金发送给自己，这和把资金发送给其他人的过程是完全一样的。

首先生成一个新的接收地址：

```
qcli getnewaddress

qdiqg2mp646KhSQjVud3whv6C34hNHQnL2
```

(在自己电脑上运行时，用自己生成的地址替换下列命令中的地址。)

下一步，发送10个qtum给该地址：

```
qcli sendtoaddress qdiqg2mp646KhSQjVud3whv6C34hNHQnL2 10
```

针对该次资金转移会返回一个交易ID（txid）：

```
11e790d26d6996803960ef1586cbaeb54af20fd3e1f41508843c36f2ef60bb9d
```

等待交易被确认，大概需要1或2分钟。然后就能在容器的日志中看到类似下面的内容：

```
07:25:54  qtumd | CTransaction(hash=11e790d26d, ver=2, vin.size=1, vout.size=2, nLockTime=1680)
07:25:54  qtumd |     CTxIn(COutPoint(5ada2447bc, 1), scriptSig=473044022063b61ff64f6340, nSequence=4294967294)
07:25:54  qtumd |     CScriptWitness()
07:25:54  qtumd |     CTxOut(nValue=19979.99832800, scriptPubKey=76a914dc41025b0c419681bffc3446)
07:25:54  qtumd |     CTxOut(nValue=10.00000000, scriptPubKey=76a914dd2c6512563e4274dafd8312)
```

使用`gettransaction`获取该交易的一些基本信息：

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

目前为止，该交易已经获得2次确认：

```
"confirmations": 2,
```

接下来，我们使用`listunspent`列出最近创建的UTXO。列出的为确认次数少于20次的UTXO：

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

注意到这两个UTXO具有相同的txid。换句话说，一个发送资金的交易创建了两个新的UTXO：

+ `qdiqg2mp646KhSQjVud3whv6C34hNHQnL2`: 接收地址，资金数量为10。
+ `qddyh9oMU44qZ28bEY9WhCDbmCaALVDr1k`: 原始的发送方UTXO有2万个qtum，即生成的数量。而这是一个新创建的UTXO，用于存放减去交易手续费后的找零。

## 解析交易数据

可以对交易数据进行更深入地挖掘，看看QTUM是否和比特币具有相同的UTXO数据结构。从前面的`gettransaction`输出结果中，可以看到十六进制的原始交易数据(例如，`02000000017d2...ac90060000`).

对交易数据进行解析：

```
qcli decoderawtransaction \
02000000017d2c908ccf224c7204024699fa9bee9cafc4319297e3c682b2d2d4bc4724da5a010000006a473044022063b61ff64f63407a7ef1e2060d6f54cae987a10b30d20b55d722f69e0bcc225e0220340fa34885cb0bdf056067d90f16b53318d44861872635051963237623c63699012102dd47f2c6e005fdc2182135ffe72c985a095ca9c59000d7f1576ed8717ef6e017feffffff02e0fe1132d10100001976a914dc41025b0c419681bffc3446ee8b506dde59e18e88ac00ca9a3b000000001976a914dd2c6512563e4274dafd8312e0e738ede48f304688ac90060000
```

解析出来的交易如下：

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

正如你所看到的，这是一个 [Pay-to-PubkeyHash](https://en.bitcoin.it/wiki/Transaction#Pay-to-PubkeyHash) 交易!

# 总结

QTUM使用比特币的UTXO模型来管理资产。QTUM钱包不是使用账户来记录余额，而是通过追踪UTXO的集合。当一个交易被创建时，钱包通过搜索UTXO的集合来找到加起来足够支付转账金额和交易费用的多个UTXO。
