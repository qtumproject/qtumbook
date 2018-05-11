# 原始交易数据

在本章中，我们将解析原始的交易数据，以了解支付交易是如何工作的。

尤其是以下几方面：

0. 发送方如何构建一个交易来表达转账的金额，以及发送给谁
1. 发送方如何证明自己对一个UTXO的拥有权
2. 发送方如何创建新的UTXO用于支付，并且如何确保只有预期的接受者可以认领它。

# 转账

生成一个地址用于接收资金。

```
qcli getnewaddress

qNUAQzJCy4UZXTsUWLdBsgMDfS8yF4nuGD
```

为了测试转账功能，从我们自己的钱包发送一些资金到这个地址：

```
qcli sendtoaddress qNUAQzJCy4UZXTsUWLdBsgMDfS8yF4nuGD 10
```

返回的交易id如下：

```
f2cb9a0cac73b7bf9dd1ba2fcfddfe91ae2f6d1e8083f8a848e61427a85d830d
```

一旦交易被确认，就可以看到该接收地址上已经有了这笔资金：

```
qcli getreceivedbyaddress qNUAQzJCy4UZXTsUWLdBsgMDfS8yF4nuGD

10.00000000
```

# 查询交易信息

使用交易id查询交易相关信息：

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

# 解析原始交易数据

`gettransaction`命令以更人性化的形式呈现交易数据。通过解析交易的原始数据，我们可以看到底层的比特币数据结构。

数据结构对于我们理解比特币账本如何工作是很重要的。

前面返回的`hex`项就是原始的交易数据。或者我们也可以用`getrawtransaction`来查询：

```
qcli getrawtransaction f2cb9a0cac73b7bf9dd1ba2fcfddfe91ae2f6d1e8083f8a848e61427a85d830d
```

接下来，解析该原始交易数据：

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

该交易有一个vins（输入值）和两个vouts（输出值）。

### 交易输入

在创建一个交易时，钱包会找到一个满足请求的金额数量的UTXO。

输入值即为该UTXO，该输入值同时也是交易`39b9...5aa6`的第二个输出值。这个UTXO的资金数为2万个qtum。

因为我们只需发送10个qtum，因此这个输入是足够支付该转账本身，以及交易费用。

### 交易输出

我们使用的UTXO的资金数为2万个qtum，但实际只需使用它的一小部分。与银行账户不同的是，我们无法只花费UTXO的一部分金额。

因此，我们要做的就是将10个qtum发送到接收地址，然后把剩余的金额发送回我们自己。

导致的结果就是该交易中有两个输出，并创造了两个新的UTXO。

+ 19989.99923200 是交易找回的零钱，需返还给发送方。
+ 10 是发送给接收方的金额。

### 交易费用

两个输出值的总和是小于输入值的。

```
20000 - 19989.99923200 - 10 = 0.000768000
```

这个差值就是付给矿工的费用。

# 所有权的加密证明

通过对原始数据的解析，可以看到Vins和Vouts指定了资金的来源以及去处。

但是网络怎么知道谁有权利花哪些钱？

在现实的金融世界里，银行充当了这个权威机构，银行可以决定一个交易是否可以通过。然而，比特币使用加密技术将该决定权分配给了它的终端用户。

这个花钱的“决定权”就像一把形状独特的锁。如果一个人能拿出形状正确的钥匙打开它，网络就允许钱被花出去。


* 发送方必须具有能够打开作为输入值UTXO的钥匙。
* 发送方创建新的锁作为输出值，并且只有接收方才能打开。

# 比特币标准支付脚本

前面用作比喻的加密“锁”只是比特币脚本中的一个简单的片段。发送方需提供正确的输入值，脚本计算的结果才能为true。

## Pay To Public Key（支付给公钥）

作为输入值的UTXO同时也是交易`39b9bcabd6101251d4d728754a4d4b7083c00baa0614eeb2705e5179ad0d5aa6`的第二个输出。下面对该交易进行解析：

```
qcli decoderawtransaction \
  `qcli getrawtransaction 39b9bcabd6101251d4d728754a4d4b7083c00baa0614eeb2705e5179ad0d5aa6`
```

该UTXO的数据为:

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

上述脚本中，“锁”的部分如下

```
03795cd550a584caf7818cbe2d71cbc05bbf59fdb6bacb876969b319c4d07a0211
OP_CHECKSIG
```

该脚本表达的意思是，任何可以生成属于公钥“03795cd550a584caf7818cbe2d71cbc05bbf59fdb6bacb876969b319c4d07a0211”的加密签名的人都可以使用该输出值。

为了解锁该脚本，发送方创建一个加密签名用于签署该输出值（例如，发送金额为多少以及发送给谁）。

这段脚本就是“锁”，签名就是钥匙。将二者结合，我们得到一个计算结果为“true”的脚本：

```
30450221008c2f779baa08239d707f758068346b15b4c3b6a0cfc7ccb361bcc69f01eebfb2022018f2e38074c2f8673ebcb30358da6822c30a74a26b7feb852bab44e4ec5c40dd[ALL]

03795cd550a584caf7818cbe2d71cbc05bbf59fdb6bacb876969b319c4d07a0211

OP_CHECKSIG
```

[OP_CHECKSIG](https://bitcoin.org/en/developer-reference#opcodes) 操作会完成两件事情：

1. 验证签名是属于公钥`03795cd550a584caf7818cbe2d71cbc05bbf59fdb6bacb876969b319c4d07a0211`的。
2. 根据签名验证交易输出。如果矿工试图篡改交易输出值（例如，调整接收的金额），这个验证就会失败。

一个Pay-To-Public-Key UTXO通常被创建用于挖矿奖励以及多余gas返还。对于支付给地址的交易，另一种类型的脚本更常见。

## Pay To Public Hash（支付给公钥哈希）

当发送资金给一个地址时，创建的输出通常是一个“Pay To Public Hash”（P2PKH）脚本。

在上面的原始交易数据中，我们看到有一个输出值具有如下脚本：

```
OP_DUP
OP_HASH160
35dbe99b7be1e43463e0fec2d431b67bcc6ef67e
OP_EQUALVERIFY
OP_CHECKSIG
```

该脚本基本的意思是，谁可以创建一个属于哈希结果为35dbe99b7be1e43463e0fec2d431b67bcc6ef67e的公钥的签名，谁就可以花费该输出值。

该脚本和`Pay To Public Key`的脚本一样，除了公钥哈希引入了额外的间接运算。

关于这类脚本如何验证的详细信息，参见 [pay to public hash validation](https://bitcoin.org/en/developer-guide#p2pkh-script-validation) 。
