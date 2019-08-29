# ERC20 Token

本章中，我们将在 QTUM 上部署一个 ERC20 token。所有遵循 ERC20 标准的 token 都支持一组通用的方法：

```
contract ERC20 {
    function totalSupply() constant returns (uint totalSupply);
    function balanceOf(address _owner) constant returns (uint balance);
    function transfer(address _to, uint _value) returns (bool success);
    function transferFrom(address _from, address _to, uint _value) returns (bool success);
    function approve(address _spender, uint _value) returns (bool success);
    function allowance(address _owner, address _spender) constant returns (uint remaining);

    event Transfer(address indexed _from, address indexed _to, uint _value);
    event Approval(address indexed _owner, address indexed _spender, uint _value); }
}
```

所有的 token 拥有相同的接口，因此钱包和交易所可以更方便地支持所有不同种类的 token。

接下来，我们将部署
[CappedToken](https://github.com/OpenZeppelin/zeppelin-solidity/blob/4ce0e211c500aa756120c4f2851cc75518123309/contracts/token/CappedToken.sol)，使用 [OpenZeppelin](https://github.com/OpenZeppelin)实现。不需要对合约进行任何的修改就可以使其运行在 QTUM 上。

`CappedToken`是一种遵循 ERC20 标准的 token，它继承了[StandardToken](https://github.com/OpenZeppelin/zeppelin-solidity/blob/4ce0e211c500aa756120c4f2851cc75518123309/contracts/token/StandardToken.sol) 和 [MintableToken](https://github.com/OpenZeppelin/zeppelin-solidity/blob/master/contracts/token/MintableToken.sol) 的基本功能。

具体地，

- `StandardToken` 实现了 ERC20 的接口。
- `MintableToken` 添加了 `mint(address _to, uint256 _amount)` 方法用于创造新的 token。
- `CappedToken` 对可铸造的 token 的最大供应量进行了限制。

# 部署 CappedToken

创建 project 目录，并将 [zeppelin-solidity](https://github.com/OpenZeppelin/zeppelin-solidity) 库复制到 project 目录下：

```
mkdir mytoken && cd mytoken

git clone https://github.com/OpenZeppelin/openzeppelin-solidity.git --branch v1.5.0
```

对于这个练习，我们将从头开始。首先以 regtest 模式启动`qtumd`：

```
docker run -it --rm \
  --name myapp \
  -v `pwd`:/dapp \
  -p 9899:9899 \
  -p 9888:9888 \
  hayeah/qtumportal
```

进入容器：

```
docker exec -it myapp sh
```

生成一些初始的余额：

```
qcli generate 600
```

# Owner 地址

一个特定的 UTXO 地址将会拥有我们部署的 ERC20 token。为了使 token 只能被合约的 owner 所使用，ERC20 中使用了一些管理 method。

这些 method 由`onlyOwner` modifier（修改器）进行保护，onlyOwner modifier 可以检查`msg.sender`是否为合约的`owner`:

```
modifier onlyOwner() {
  require(msg.sender == owner);
  _;
}
```

例如，`mint`函数可以确保只有 owner 才能使用 token：

```
function mint(address _to, uint256 _amount) onlyOwner canMint public returns (bool)
```

## 创建 Owner 地址并给它发送资金

首先生成一个地址作为 owner 的地址：

```
qcli getnewaddress
qdgznat81MfTHZUrQrLZDZteAx212X4Wjj
```

这个地址没有什么特别之处，开发者也可以使用钱包中任意一个地址。

给这个 owner 地址发送 10 个 QTUM 的资金，用于后面部署合约时支付 gas 费用：

```
qcli sendtoaddress qdgznat81MfTHZUrQrLZDZteAx212X4Wjj 10
cf652f54e6a6dde3e60fa4e38eee1c529bf4ecf3f8424c7ac7ef9717850cc984
```

支付被确认后，就能查询到该 owner 地址上有一个 UTXO：

```
qcli listunspent 1 99999 '["qdgznat81MfTHZUrQrLZDZteAx212X4Wjj"]'
[
  {
    "txid": "cf652f54e6a6dde3e60fa4e38eee1c529bf4ecf3f8424c7ac7ef9717850cc984",
    "vout": 1,
    "address": "qdgznat81MfTHZUrQrLZDZteAx212X4Wjj",
    "account": "",
    "scriptPubKey": "76a91437158152a9768477770ecb7a9e55a5875b9f35b088ac",
    "amount": 10.00000000,
    "confirmations": 1,
    "spendable": true,
    "solvable": true
  }
]
```

最后，配置部署工具`solar`使该特定地址成为合约的 owner：

```
export QTUM_SENDER=qdgznat81MfTHZUrQrLZDZteAx212X4Wjj
```

现在就可以开始部署 token 合约了。

## 部署 Token 合约

`CappedToken`构造函数需要`_capacity`参数来指定可以铸造的 token 的最大数量：

```
function CappedToken(uint256 _capacity)
```

部署一个合约通常需要以下几个步骤：

1. 使用 [solidity compiler](https://github.com/ethereum/solidity) 将合约编译成 bytecode（字节码）。
2. [ABI encode](https://github.com/ethereum/wiki/wiki/Ethereum-Contract-ABI) 将`_capacity`参数编码成字节。
3. 将 1 和 2 连接在一起，然后对 qtumd 进行一个`createcontract` RPC（远程过程调用）调用。
4. 等待交易被确认。
5. 记录合约的地址以及合约的 owner，供后续使用。

智能合约部署工具 [solar](https://github.com/qtumproject/solar.git) （置于容器内的）会处理所有上述步骤。

部署 CappedToken 合约时，通过在构造函数参数中传递一个 JSON 数组，指定该合约的容量为 2100 万 (记住要设置`QTUM_SENDER`):

```
solar deploy zeppelin-solidity/contracts/token/ERC20/CappedToken.sol \
  '[21000000]'
```

然后 solar 等待确认：

```
🚀  All contracts confirmed
   deployed zeppelin-solidity/contracts/token/CappedToken.sol =>
      a778c05f1d0f70f1133f4bbf78c1a9a7bf84aed3
```

现在，合约已经部署到`a778c05f1d0f70f1133f4bbf78c1a9a7bf84aed3`地址上了。（在自己电脑上操作时，你可能会得到一个不同的地址）。

`solar status`命令可以用于显示所有使用 solar 部署的合约：

```
solar status

✅  zeppelin-solidity/contracts/token/CappedToken.sol
        txid: 457a5afe15686c0bd596635aeb78d4ff7d2bf6a75df66c7251e89ce4d9c8f6d3
     address: 3db297ee4c225b45219d2a7aa68afea7f4e68832
   confirmed: true
       owner: qdgznat81MfTHZUrQrLZDZteAx212X4Wjj
```

注意，合约的 owner 应该被设置为我们前面提到的`QTUM_SENDER` 值。如果没有设置`QTUM_SENDER`，那么就会从钱包中随机选择一个 UTXO 作为合约的 owner。

在`solar.development.json`中，可以找到关于已部署合约的更多信息。

# Owner 的 UTXO 地址作为发送方

QTUM 和以太坊的主要区别就是 QTUM 是基于比特币的 UTXO 模型，而以太坊有自己的账户模型，这点我们在前面的 [QTUM UTXO](../part1/UTXOs-balances.md) 章节中已经提到了。

在以太坊中，交易的花费由账户进行支付。支付的金额会从账户中扣除，但是账户仍然存在。

然而，UTXO 只能被使用一次。因此，我们之前使用的是一个 UTXO 来部署合约，该 UTXO 的地址为`qdgznat81MfTHZUrQrLZDZteAx212X4Wjj`。现在该 UTXO 已经消失，它的全部金额也被花光。

因此每次作为一个合约的 owner，就会毁灭这个 owner 的 UTXO。下次想要成为该合约的 owner，将需要一个有着相同地址的新的 UTXO。如果这些都需要手动操作，那将是很烦人的。

幸运的是，在与合约交互时，QTUM 总是创建一个有着相同地址的新的 UTXO 来替换已经使用的 UTXO。

列出 owner 地址`qdgznat81MfTHZUrQrLZDZteAx212X4Wjj`对应的 UTXO。可以看到，即使我们已经花费了一个 UTXO，这里仍然只有一个 UTXO：

```
qcli listunspent 1 99999 '["qdgznat81MfTHZUrQrLZDZteAx212X4Wjj"]'
[
  {
    "txid": "457a5afe15686c0bd596635aeb78d4ff7d2bf6a75df66c7251e89ce4d9c8f6d3",
    "vout": 1,
    "address": "qdgznat81MfTHZUrQrLZDZteAx212X4Wjj",
    "account": "",
    "scriptPubKey": "76a91437158152a9768477770ecb7a9e55a5875b9f35b088ac",
    "amount": 8.78777200,
    "confirmations": 61,
    "spendable": true,
    "solvable": true
  }
]
```

然而，注意到交易 id `457a...f6d3` 和之前的 UTXO 的交易 id`cf65...c984`是不相同的。这是一个完全不同的 UTXO，并且它的金额为 10 减去为部署合约支付的费用。

金额`8.78777200`为找回的零钱（change）。对于一个与合约有交互的交易，找零（change）是支付给发送方的。而在一个典型的支付交易中，找零是支付给一个由钱包控制的新生成的地址。

其结果是，尽管比特币 UTXO 和以太坊账户的记账模型差别很大，但是在 QTUM 中，两者的行为方式很类似。

# 使用 ABIPlayer

`solar.development.json`文件存储了关于已部署的 CappedToken 合约的信息。开发者可以将该文件加载到 ABIPlayer 中，这样就可以和使用 solar 部署的任何合约进行交互。

确保 docker 容器正在运行，访问：[http://localhost:9899/abiplay/](http://localhost:9899/abiplay/)

![](./erc20-token/abiplayer-empty.jpg)

加载 solar.development.json 文件后，可以看到可用的合约以及 method 的列表：

![](./erc20-token/abiplayer-loaded.jpg)

灰色按钮是只读的 method（只能 call（调用）），而蓝色按钮对应的 method 既支持 send（发送）也支持 call（调用）。

点击`owner`按钮，获取该合约的`owner`信息：

![](./erc20-token/owner-call.jpg)

可以看到，返回的 owner 地址为一个十六进制地址：

![](./erc20-token/owner-call-result.jpg)

可以将其转换回 base58 编码的 UTXO 地址:

```
qcli fromhexaddress dcd32b87270aeb980333213da2549c9907e09e94

qdgznat81MfTHZUrQrLZDZteAx212X4Wjj
```

# 使用 ABIPlayer 铸造 token

下面让我们为合约的 owner 铸造一些币。由于接收方的地址需要发送给智能合约，因此地址的格式应该转换为十六进制而不是 base58 编码格式。

铸造 1000 个 token：

![](./erc20-token/mint-send.jpg)

点击发送，你将看到交易正在等待授权（waiting authorization）：

![](./erc20-token/mint-waiting-authorization.jpg)

这个请求需要你的授权，因为它会花费 QTUM。访问授权 UI([http://localhost:9899/](http://localhost:9899/))来批准该请求：

![](./erc20-token/mint-auth.jpg)

等待确认，并且你将看到交易信息，如下：

![](./erc20-token/mint-result.jpg)

现在，可以调用`balanceOf`和`totalSupply`检查 owner 是否已经接收到 token，以及供应量是否相应地增加了：

![](./erc20-token/mint-balance-supply.jpg)

# 总结

在本章中，我们部署了一个基本的 ERC20 token，并且在此过程中，我们使用了一些工具：

- `solar deploy` 编译&创建一个合约。
- `solar prefund` 创建和合约 owner 具有相同地址的 UTXOs。
- 使用 ABIPlayer 和已部署的合约进行交互：[http://localhost:9899/abiplay/](http://localhost:9899/abiplay/)
- 对花费资金的请求进行授权：[http://localhost:9899/](http://localhost:9899/)
