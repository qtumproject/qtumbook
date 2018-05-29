# QTUM Docker Container（Docker容器）

本书中，我们创建一个docker image（docker镜像）来确保运行环境一致，这样就更容易按照下面的例子进行操作。 docker容器包括`qtumd`和本书其余部分中将用到的所有工具。

下载最新的容器镜像：

```
docker pull hayeah/qtumportal:latest
```

## 运行regtest模式

对于开发和测试，运行一个本地区块链是最方便的，因为在自己的电脑上处理生成的交易是很便宜的。 开发者可以很容易地使用`qtumd`内嵌的`regtest`模式 (regression test mode，回归测试模式)运行一个本地的区块链。

`regtest`和以太坊的`testrpc`类似，但在以下几个方面有所不同：

+ 区块链状态存储在磁盘上，并且在qtumd重新启动时仍然存在。
+ 区块不是立刻被挖出的，而是在一个半规律的时间间隔内。
+ 需要手动生成600个区块。

默认情况下，`hayeah/qtumportal`docker镜像启动`qtumd`的`regtest`模式:

```
docker run -it --rm \
  --name myapp \
  -v `pwd`:/dapp \
  -p 9899:9899 \
  -p 9888:9888 \
  -p 3889:3889 \
  hayeah/qtumportal
```

+ `--name` 容器的名称，可以将它改成任何名称。
+ `-it` 为容器分配一个终端设备。
+ `--rm` 退出后立刻删除容器。
+ `-v` 把当前目录映射为容器中的`/dapp`目录。
+ `-p` 显示容器端口，以便主机操作系统访问。

应该看到如下输出：

```
02:46:17 portal | Starting portal on port 5001
02:46:17  qtumd | Starting qtumd on port 5000
02:46:17 portal | time="2017-12-13T02:46:17Z" level=info msg="DApp service listening 0.0.0.0:9888"
02:46:17 portal | time="2017-12-13T02:46:17Z" level=info msg="Auth service listening 0.0.0.0:9899"
02:46:17  qtumd | 2017-12-13 02:46:17
02:46:17  qtumd | 2017-12-13 02:46:17 Qtum version v0.14.10.0-101922f-dirty
02:46:17  qtumd | 2017-12-13 02:46:17 InitParameterInteraction: parameter interaction: -whitelistforcerelay=1 -> setting -whitelistrelay=1
02:46:17  qtumd | 2017-12-13 02:46:17 Validating signatures for all blocks.
02:46:17  qtumd | 2017-12-13 02:46:17
02:46:17  qtumd | 2017-12-13 02:46:17 Default data directory /root/.qtum
02:46:17  qtumd | 2017-12-13 02:46:17 Using data directory /dapp/.qtum/regtest
...
02:46:22  qtumd | 2017-12-13 02:46:22 ERROR: Read: Failed to open file /dapp/.qtum/regtest/banlist.dat
02:46:22  qtumd | 2017-12-13 02:46:22 Invalid or missing banlist.dat; recreating
02:46:22  qtumd | 2017-12-13 02:46:22 init message: Starting network threads...
02:46:22  qtumd | 2017-12-13 02:46:22 net thread start
02:46:22  qtumd | 2017-12-13 02:46:22 addcon thread start
02:46:22  qtumd | 2017-12-13 02:46:22 init message: Done loading
02:46:22  qtumd | 2017-12-13 02:46:22 opencon thread start
02:46:22  qtumd | 2017-12-13 02:46:22 msghand thread start
02:46:22  qtumd | 2017-12-13 02:46:22 dnsseed thread start
02:46:22  qtumd | 2017-12-13 02:46:22 Loading addresses from DNS seeds (could take a while)
02:46:22  qtumd | 2017-12-13 02:46:22 0 addresses found from DNS seeds
02:46:22  qtumd | 2017-12-13 02:46:22 dnsseed thread exit
```

可在终端中按`ctrl-c` 来终止容器，并且能够看到一些更整洁的日志：

```
02:48:06  qtumd | 2017-12-13 02:48:06 tor: Thread interrupt
02:48:06  qtumd | 2017-12-13 02:48:06 torcontrol thread exit
02:48:06  qtumd | 2017-12-13 02:48:06 addcon thread exit
02:48:06  qtumd | 2017-12-13 02:48:06 opencon thread exit
02:48:06  qtumd | 2017-12-13 02:48:06 scheduler thread interrupt
02:48:06  qtumd | 2017-12-13 02:48:06 Shutdown: In progress...
02:48:06  qtumd | 2017-12-13 02:48:06 msghand thread exit
02:48:06  qtumd | 2017-12-13 02:48:06 net thread exit
02:48:06  qtumd | 2017-12-13 02:48:06 Dumped mempool: 0.001657s to copy, 0.00729s to dump
02:48:06  qtumd | 2017-12-13 02:48:06 ...  02:48:06.292|  Closing state DB
02:48:06  qtumd | 2017-12-13 02:48:06 ...  02:48:06.306|  Closing state DB
02:48:06  qtumd | 2017-12-13 02:48:06 Shutdown: done
02:48:06  qtumd | Terminating qtumd
```

你将看到`regtest`的区块链数据库已经创建在本地project目录的`.qtum/regtest`路径下：

```
ls .qtum/regtest

banlist.dat       chainstate        debug.log         mempool.dat       stateQtum         wallet.dat
blocks            db.log            fee_estimates.dat peers.dat         vm.log
```

重启容器， `qtumd`应该能够复用保存在`.qtum`的区块链数据库。

```
docker run -it --rm \
  --name myapp \
  -v `pwd`:/dapp \
  -p 9899:9899 \
  -p 9888:9888 \
  -p 3889:3889 \
  hayeah/qtumportal
```

#### 运行测试网络

开发者可以通过设置容器内QTUM_NETWORK的环境变量来运行测试网路，例如：

```
docker run -it --rm \
  --name myapp \
  -e "QTUM_NETWORK=testnet" \
  -v `pwd`:/dapp \
  -p 9899:9899 \
  -p 9888:9888 \
  -p 3889:3889 \
  -p 13888:13888 \
  hayeah/qtumportal
```

## 使用Shell访问容器

验证容器是否正在运行：

```
docker ps
```

```
CONTAINER ID        IMAGE               COMMAND                  CREATED              STATUS              PORTS                                                                      NAMES
72d7b2c22f97        hayeah/qtumportal   "/bin/sh -c 'mkdir..."   About a minute ago   Up About a minute   0.0.0.0:9888->9888/tcp, 0.0.0.0:9899->9899/tcp, 0.0.0.0:13889->13889/tcp   myapp
```

容器的名称是`myapp`。可以获得shell访问：

```
docker exec -it myapp sh
```

容器内的`/dapp`目录应该和你的project目录一样。

在容器内，可以使用`qcli`命令和qtumd交互。获取一些区块链状态的基本信息，可以使用如下命令：

```
qcli getinfo

{
  "version": 141000,
  "protocolversion": 70016,
  "walletversion": 130000,
  "balance": 0.00000000,
  "stake": 0.00000000,
  "blocks": 0,
  "timeoffset": 0,
  "connections": 0,
  "proxy": "",
  "difficulty": {
    "proof-of-work": 4.656542373906925e-10,
    "proof-of-stake": 4.656542373906925e-10
  },
  "testnet": false,
  "moneysupply": 0,
  "keypoololdest": 1513133181,
  "keypoolsize": 100,
  "paytxfee": 0.00000000,
  "relayfee": 0.00400000,
  "errors": ""
}
```

# 生成新区块

链初始时是空的。正如我们在`getinfo`中看到的，目前还没有区块：

```
"blocks": 0
```

并且初始的钱包余额也是0：

```
qcli getbalance

0.00000000
```

在`regtest`模式下，允许挖掘新的区块用于测试。这在以下两方面是很有用的：

1. 能够产生足够的余额来支付交易费用。
2. 能快速确认交易而不需要等一个新的区块被挖掘出来。

生成600个区块的方法如下：

```
qcli generate 600
```

```
[
  // more ...
  "43e9c190679a4d040d07c6d0d5d34c1d49f7b6b6539ceb87eea76af3ef39eed5",
  "7d5b6a0e5e76cf18e35ac18d4534155a0fd96201feaefc720118452dd50bcd5b",
  "70013fa6e01ad527e1f71033ebf59c5233877fcd0fd8233ea032ddaface3cbbc",
  "6c73fe21f7c7874b550e190dcc69320c13a96f188bfb89ab858bc42adc0a1398",
  "5b48289b22fbf073f6a345d97968c3b8ee44381e8e10e6f940d31b7355684968",
  "4f9444d8bd3ece4f6839d7bcfc7f964e95187e2868128681b7bc4cb42d719b41"
]
```

此时，钱包的余额不再是0：

```
qcli getbalance

2000000.00000000
```

并且区块的数量大约是600：

```
qcli getinfo

"blocks": 603,
```

> 注意：QTUM的POS挖矿奖励是不能立即花费的，直到500个区块之后才会“成熟”并能被使用。通过产生600个区块，可以获得100个“成熟”的区块奖励，每个区块奖励都是2万个QTUM。

# 总结

在本章中，我们在docker容器中运行了qtumd：

```
docker run -it --rm \
  --name myapp \
  -v `pwd`:/dapp \
  -p 9899:9899 \
  -p 9888:9888 \
  -p 3889:3889 \
  hayeah/qtumportal
```

shell进入容器中：

```
docker exec -it myapp sh
```

一旦进入容器中，使用`qcli`命令和qtumd交互，例如：

```
qcli getinfo
```

获取可用的`qcli`命令和参数列表，可以使用：

```
qcli help
```

```
... more
listsinceblock ( "blockhash" target_confirmations include_watchonly)
listtransactions ( "account" count skip include_watchonly)
listunspent ( minconf maxconf  ["addresses",...] [include_unsafe] )
lockunspent unlock ([{"txid":"txid","vout":n},...])
move "fromaccount" "toaccount" amount ( minconf "comment" )
removeprunedfunds "txid"
reservebalance [<reserve> [amount]]
sendfrom "fromaccount" "toaddress" amount ( minconf "comment" "comment_to" )
sendmany "fromaccount" {"address":amount,...} ( minconf "comment" ["address",...] )
sendmanywithdupes "fromaccount" {"address":amount,...} ( minconf "comment" ["address",...] )
sendtoaddress "address" amount ( "comment" "comment_to" subtractfeefromamount )
sendtocontract "contractaddress" "data" (amount gaslimit gasprice senderaddress broadcast)
setaccount "address" "account"
settxfee amount
signmessage "address" "message"
```
