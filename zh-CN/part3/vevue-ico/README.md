# 简单的众筹

在本章中，我们将使用Vevue的ICO的合约发起一个众筹。它本质上是一个ERC20 token，再加上一个`buyTokens` method。当用户使用`buyTokens`将钱发送给合约时，根据一个固定兑换比率得到的一定数量的token会被铸造出来，并且会被计入在买方名下。

本章使用的源代码在 [qtumproject/qtumjs-vevue-ico](https://github.com/qtumproject/qtumjs-vevue-ico) 中。

在token合约中有一些写死的参数，开发者可以根据自己的token的一些特定的设计来调整这些参数。

部分合约参数如下：

+ `decimals`: 一个单位的token是如何分割的。
  + 小数点后8位，就像比特币一样分割。最小的单位是satoshi。
+ `tokenTotalSupply`: token的最大供应量。
  + 总共1亿个token
+ `saleAmount`: 出售的token数量。
  + 出售4千万个token
+ `_initialExchangeRate`: 兑换比率。
  + 设置1个qtum兑换100个token。

为了简单起见，我们禁用了众筹的开始和结束时间（以区块号指定）。

下面就开始我们的众筹！

# 创建一个Owner地址

首先，生成一个地址作为合约owner的地址。众筹的收入将会进入这个地址。

```
qcli getnewaddress
qJtdUF9ko4Hk95cqTzq7SDs18dapNwjRNS

qcli gethexaddress qJtdUF9ko4Hk95cqTzq7SDs18dapNwjRNS
0e9bfa516890f857beaba3eba35cc478ab10bce4
```

给owner地址发送一些资金用于支付gas费用：

```
qcli sendtoaddress qJtdUF9ko4Hk95cqTzq7SDs18dapNwjRNS 1
```

然后配置`solar`，使得在部署合约时能够使用该地址。

```
export QTUM_SENDER=qJtdUF9ko4Hk95cqTzq7SDs18dapNwjRNS
```

# 部署Token合约

使用solar部署合约：

```
solar deploy VevueToken.sol --force

🚀  All contracts confirmed
   deployed VevueToken.sol => 09b97cc71a300f1bdad44711f4ce9f25bd404d8b
```

验证合约owner是我们前面已经设置的`QTUM_SENDER`的地址：

```
solar status

✅  VevueToken.sol
        txid: 08528ef006f05fdfe1d6eb3006bac7dfc21d6f854822081575b9ff8b61950cdd
     address: 09b97cc71a300f1bdad44711f4ce9f25bd404d8b
   confirmed: true
       owner: qJtdUF9ko4Hk95cqTzq7SDs18dapNwjRNS
```

## 初始化众筹状态

可以使用自带的qtumjs脚本打印众筹的相关信息：

```
node index.js info

supply cap: 100000000.00000000
sales cap: 40000000.00000000
current token supply: 0.0
tokens sold: 0.0
```

* 验证supply cap（供应量限额）和sales cap（销售限额）是否已指定
  * 小数点后有8位
* 目前的supply为0

# 购买Token

生成另一个地址，并使用该地址来接收购买的token：

```
qcli getnewaddress
qgMR2N4ANuswodFh8T4gYMD3a3VNAd11Jt
```

```
qcli gethexaddress qgMR2N4ANuswodFh8T4gYMD3a3VNAd11Jt
fa0775ed07771e390c5a3bd2f00cef05bc4185f2
```

现在，花费1个qtum来购买token（可以获得100个token）：

```
node index.js buy fa0775ed07771e390c5a3bd2f00cef05bc4185f2 1
```

交易确认后，token的supply增加100：

```
node index.js info

supply cap: 100000000.00000000
sales cap: 40000000.00000000
current token supply: 100.00000000
tokens sold: 100.00000000
```

同样也可以检查用于购买token的特定地址的余额是否正确：

```
node index.js balanceOf fa0775ed07771e390c5a3bd2f00cef05bc4185f2
100.00000000
```
