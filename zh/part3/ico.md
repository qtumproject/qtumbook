# 发起一个众筹

在本章中，我们将为一个ERC20 token进行一次众筹。我们将使用 [TokenMarketNet](https://github.com/TokenMarketNet/ico) 开发的众筹合约。这些合约明显比我们已经看过的简单示例要复杂的多。

在这个设置中，有六种不同的角色。

人类的角色：

+ 众筹的owner。
+ 预售投资者。
+ ICO投资者。

智能合约的角色：

+ token minter（铸币者）。
+ token release agent（发行代理）。
+ 众筹finalizing agent（最终代理）。

完整的例子可以在 [qtumproject/qtumjs-crowdsale-cli](https://github.com/qtumproject/qtumjs-crowdsale-cli) 中找到。

## TL;DR

众筹的流程如下：

1. [设计众筹和token的分配](#ICO设计)
1. [部署SafeMathLib库](#部署库)
1. [部署合约](#部署众筹合约)
1. [配置合约](#众筹设置)
1. [分配用于预售的token](#Presale预分配）)
1. [允许公众进行投资](#公众投资)
1. [众筹结束](#结束众筹)
    + [如果成功，则结束](#众筹成功：结束众筹)。
    + [如果失败，则退款](#众筹失败：退回众筹的资金)。

想快速浏览整个众筹过程运行的所有命令，请查看：[recipe.sh](https://github.com/qtumproject/qtumjs-crowdsale-cli/blob/master/recipe.sh) 。

与该众筹交互的NodeJS脚本是 [index.js](https://github.com/qtumproject/qtumjs-crowdsale-cli/blob/master/index.js) 。

所涉及的合约的部署数据的示例参见：[solar.development.json](https://github.com/qtumproject/qtumjs-crowdsale-cli/blob/master/solar.development.json.example) 。


# ICO设计

TokenMarketNet合约涵盖了许多常见的ICO场景，可为不同类型的token，不同的cap以及不同的定价策略提供支持。

我们的众筹有以下配置：

+ BurnableCrowdsaleToken

这本质上是一种可铸造的token。它也提供了毁掉token的选项，例如，当众筹没有达到最大的销售目标，并且你想降低团队持有token的比例。

+ FlatPricing

参与公共销售的每个人都得到相同的价格。当然，也有其他的定价策略如 [TokenTranchePricing](https://github.com/TokenMarketNet/ico/blob/master/contracts/TokenTranchePricing.sol) 或 [MilestonePricing](https://github.com/TokenMarketNet/ico/blob/master/contracts/MilestonePricing.sol)。

价格指定为每个token一个satoshi（即10^-8）。

+ MintedTokenCappedCrowdsale

这是一个被售出的token数量所限制的众筹。

## 供应量，分配，以及定价

下面确定众筹的这些参数。为了简单起见，我们假设qtum的价格为100美元。

名称：

* Token名称： MyToken
* Token符号： MTK
* 小数位数： 0 (f用于不可分割的token。参见：[Understanding ERC20](https://medium.com/@jgm.orinoco/understanding-erc-20-token-contracts-a809a7310aa5)).


供应量分配如下：

* 总供应量：1亿个MTK
* 团队： 10%
* 基金会： 20%
* 预售：10%，有50%的折扣
* 公开ICO： 60%

价格：

* 预售
  * 价格：50000 QTUM Satoshi (法币0.05美元)
  * 预售tokens：1千万个
  * 2000 MTK：1 QTUM
  * 预售金额：5000 QTUM (50万美元)
* 公开ICO
  * 价格：100000 QTUM Satoshi (法币0.1美元)
  * ICO tokens：6千万个
  * 1000 MTK : 1 QTUM
  * ICO资金：6万个QTUM（6百万美元）

ICO发行后，该token的估值为1千万美元。

# 运行代码

复制合约：

```
git clone --recursive \
  https://github.com/qtumproject/qtumjs-crowdsale-cli
```

## 运行QTUMD

运行qtumd的regtest模式：

```
docker run -it --rm \
  --name myico \
  -v `pwd`:/dapp \
  -p 3889:3889 \
  -p 9899:9899 \
  -p 9888:9888 \
  hayeah/qtumportal
```

然后生成一些初始的区块：

```
docker exec -it myico sh
```

```
qcli generate 600
```

# 配置ICO Owner地址

我们需要创建一个拥有所有与该ICO相关的合约的地址，即owner地址。

```
qcli getnewaddress
qf292iYbjJ41oMoArA3PrHpxTdAHuQsuAu

qcli gethexaddress qf292iYbjJ41oMoArA3PrHpxTdAHuQsuAu
eb6a149ec16aaaa6e47b6c0048520f7d9563b20a
```

先给该地址提供100个UTXO：

```
solar prefund qf292iYbjJ41oMoArA3PrHpxTdAHuQsuAu 0.1 100
```

然后，配置`solar`使得在创建合约时会用该地址作为owner（否则将选择一个随机的UTXO作为owner）。在容器shell中，设置`QTUM_SENDER`环境变量：

```
export QTUM_SENDER=qf292iYbjJ41oMoArA3PrHpxTdAHuQsuAu
```

owner地址将会被用来接收众筹的投资资金。

# 部署库

众筹合约依赖于用于数学计算的`SafeMathLib`库，因此，整形溢出会引起错误。

使用`lib`选项将合约部署为库：

```
solar deploy contracts/SafeMathLib.sol --lib

🚀  All contracts confirmed
   deployed contracts/SafeMathLib.sol => 26fe40c433b4d109299660284eaa475b95462342
```

一旦部署，其他引用`SafeMathLib`库的合约将自动链接到部署在地址`26fe40c433b4d109299660284eaa475b95462342`上的库实例。

# 部署众筹合约

需要部署的合约有以下4个。

## ERC20 Token

ERC20 token的构造函数：

```
BurnableCrowdsaleToken(
  string _name,
  string _symbol,
  uint _initialSupply,
  uint _decimals,
  bool _mintable)
```

https://github.com/TokenMarketNet/ico/blob/master/contracts/BurnableCrowdsaleToken.sol#L18

根据供应量分配计划，分配10%给团队，分配20%给基金会，总共3千万个token。

```
solar deploy contracts/BurnableCrowdsaleToken.sol:MyToken '
[
  "MyToken",
  "MTK",
  30000000,
  0,
  true
]
'

🚀  All contracts confirmed
   deployed MyToken => 92105c87931dea43d9901bd944a48d3b8a0268ad
```

初始的供应量设置为3千万，并将token分配给合约owner。这些token后续可能会转账给团队和基金会。

## 定价策略

`FlatPricing`策略的构造函数很简单：

```
function FlatPricing(uint _oneTokenInWei)
```

https://github.com/TokenMarketNet/ico/blob/f5b3ac6b5773f707943289b6ab1914a6b4e30683/contracts/FlatPricing.sol#L22

注意，该合约是使用以太坊平台写的，以太坊最小的单位是`wei`（10^-9）。然而，QTUM继承了比特币的账本，其最小单位是`satoshi`（10^-8）。

因此，即使构造函数中参数的名称是`_oneTokenInWei`，但它实际的意思是`_oneTokenInSatoshi`。

公开ICO的价格是10万qtum satoshi（1000MTK价值为1个qtum）。

```
solar deploy contracts/FlatPricing.sol '
[
  100000
]
'
```

## 众筹合约

众筹合约的构造函数比较复杂：

```
function MintedTokenCappedCrowdsale(
  address _token,
  PricingStrategy _pricingStrategy,
  address _multisigWallet,
  uint _start,
  uint _end,
  uint _minimumFundingGoal,
  uint _maximumSellableTokens)
  Crowdsale(
    _token, _pricingStrategy, _multisigWallet,
    _start, _end, _minimumFundingGoal) {
    maximumSellableTokens = _maximumSellableTokens;
}
```

众筹的开始和结束时间是需要的，并且时间的格式为 [unix time](https://en.wikipedia.org/wiki/Unix_time)：

```
> new Date('2018-01-15T00:00:00Z') / 1000
1515974400
> new Date('2018-03-01T00:00:00Z') / 1000
1519862400
```

部署的命令为：

```
solar deploy contracts/MintedTokenCappedCrowdsale.sol:Crowdsale '
[
  ${MyToken},
  ${contracts/FlatPricing.sol},
  "0xeb6a149ec16aaaa6e47b6c0048520f7d9563b20a",
  1515974400,
  1519862400,
  1200000000000,
  60000000
]
'
```

构造函数的参数描述如下：

* `_token`
  * 使用`${MyToken}`来插入`MyToken`合约的地址。
* `_pricingStrategy`
  * 使用`${contracts/FlatPricing.sol}`来插入定价策略的地址。
* `_multisigWallet`
  * `0xeb6a149ec16aaaa6e47b6c0048520f7d9563b20a`，owner地址。
* `_minimumFundingGoal`，以satoshi为单位。
  * 将该参数设置为资金限额的20%
  * 60000 qtum * 20% == 12000 qtum == 12000 * 10^8 satoshi == 1200000000000 satoshi
* `_maximumSellableTokens`
  * 6千万个tokens

## Finalize Agent（最终代理）

finalize agent是用于指定众筹成功时应该运行的回调函数的一种方法。它至少需要做的是释放token，以便持有者可以自由地转移token。

在本例中，我们使用`DefaultFinalizeAgent`，它的作用只是释放token，并不处理其他事情：

```
function DefaultFinalizeAgent(
  ReleasableToken _token,
  Crowdsale _crowdsale
)
```

部署该finalize agent：

```
solar deploy contracts/DefaultFinalizeAgent.sol:FinalizeAgent '
[
  ${MyToken},
  ${Crowdsale}
]
'
```

# Sanity Check（完整性检查）

现在应该有4个已经部署的合约：

```
solar status

✅  MyToken
        txid: b11f5def8559a5c351a153f8f3b8eead23fb73bfc218fe951ac7de3205205972
     address: 92105c87931dea43d9901bd944a48d3b8a0268ad
   confirmed: true
       owner: qf292iYbjJ41oMoArA3PrHpxTdAHuQsuAu

✅  contracts/FlatPricing.sol
        txid: 2c327ebcbda2fae979b9d1c0a99973535c22bdec2bb9c96d80dea57b10c9b8ea
     address: 8f52355c4de8dc1d3104b3773aa8c3ca31f890d1
   confirmed: true
       owner: qf292iYbjJ41oMoArA3PrHpxTdAHuQsuAu

✅  FinalizeAgent
        txid: 4d56e06efe5ef4b124421cbc1bc6ff399e1fbce9175b58221f802bf12742835d
     address: c1ac5d69763da27e9c8fe319427c80a167298a6d
   confirmed: true
       owner: qf292iYbjJ41oMoArA3PrHpxTdAHuQsuAu

✅  Crowdsale
        txid: c99daf64a18fac29f006d88644e3e7d3c9abc8950d23f5f467b18a7da1766d26
     address: f96403c9431ed464dd0063d18756718ac78f1edb
   confirmed: true
       owner: qf292iYbjJ41oMoArA3PrHpxTdAHuQsuAu
```

确保所有上述合约都具有相同的owner。如果不是的话，请确保环境变量`QTUM_SENDER`设置为owner地址，并再次尝试。

可以使用qtumjs查询这些合约的基本信息：

```ts
console.log("token supply:", await mytoken.return("totalSupply"))
console.log("crowdsale state:", await crowdsale.returnAs(stateName, "getState"))
console.log("crowdsale start date:", await crowdsale.returnDate("startsAt"))
console.log("crowdsale end date:", await crowdsale.returnDate("endsAt"))

console.log("investor count:", await crowdsale.return("investorCount"))
console.log("qtum raised:", await crowdsale.returnCurrency("qtum", "weiRaised"))
console.log("tokens sold:", await crowdsale.return("tokensSold"))
```

运行CLI脚本，将信息打印出来：

```
node index.js info

token supply: 30000000
crowdsale state: Preparing
crowdsale start date: 2018-01-15T00:00:00.000Z
crowdsale end date: 2018-03-01T00:00:00.000Z
investor count: 0
qtum raised: 0
tokens sold: 0
```

注意到，众筹的状态为`Preparing`，还没有完全准备就绪。

# 众筹设置

还需要进行一些设置，给不同的合约授予权限使它们可以完成自己的工作。

设置的脚本如下：

```ts
async function setupCrowdsale() {
  // Set the finalize agent as token's release agent
  if (await mytoken.return("releaseAgent") !== finalizeAgent.address) {
    let tx = await mytoken.send("setReleaseAgent", [finalizeAgent.address])
    console.log("confirming mytoken.setReleaseAgent:", tx.txid)
    let receipt = await tx.confirm(1)
    console.log("mytoken.setReleaseAgent receipt", receipt)
  }
  console.log("releaseAgent coinfigured")

  // Set crowdsale's finalize agent
  if (await crowdsale.return("finalizeAgent") !== finalizeAgent.address) {
    tx = await crowdsale.send("setFinalizeAgent", [finalizeAgent.address])
    console.log("confirming crowdsale.setFinalizeAgent:", tx.txid)
    receipt = await tx.confirm(1)
    console.log("crowdsale.setFinalizeAgent receipt", receipt)
  }
  console.log("finalizeAgent coinfigured")

  // The mint agent of the token should be the crowdsale contract.
  // `true` means this address is allow to mint. `false` to disable a mint agent.
  if (await mytoken.return("mintAgents", [crowdsale.address]) !== true) {
    tx = await mytoken.send("setMintAgent", [crowdsale.address, true])
    console.log("confirming mytoken.setMintAgent:", tx.txid)
    receipt = await tx.confirm(1)
    console.log("mytoken.setMintAgent receipt", receipt)
  }
  console.log("mintAgents coinfigured")
}
```

使用node运行脚本：

```
node index.js setup

releaseAgent coinfigured
finalizeAgent coinfigured
mintAgents coinfigured
```

再次将信息打印出来，可以看到众筹的状态已经变为`PreFunding`：

```
node index.js info

token supply: 30000000
crowdsale state: PreFunding
crowdsale start date: 2018-01-15T00:00:00.000Z
crowdsale end date: 2018-03-01T00:00:00.000Z
investor count: 0
qtum raised: 0
tokens sold: 0
```

> 该信息显示状态为`PreFunding`，即使当前时间已经超过了众筹的开始日期。实际的状态应该是`Funding`。 这个问题将会在 [qtum #480](https://github.com/qtumproject/qtum/issues/480) 里解决。

# Presale预分配

按照我们的ICO计划，我们已经将token供应量的10%（1千万个token）出售给早期的投资者。我们希望将他们的投资记录在账本上。

假设有两个投资者，他们以相同的价格进行投资：

```yaml
- address: "77913e470293e72c1e93ed8dda8c1372dfc0274f"
  tokens: 6000000
  price: 50000

- address: "78d55bb60f8c0e80fda479b02e40407ee0a88ab1"
  tokens: 4000000
  price: 50000
```

[preallocate](https://github.com/TokenMarketNet/ico/blob/2835f331fd9a9356131dfcf0ddd2cee471b9e32f/contracts/Crowdsale.sol#L65) 方法允许众筹owner分配token给投资者的地址。假设投资资金已经私下转移给owner。

```
function preallocate(
  address receiver,
  uint fullTokens,
  uint weiPrice
) public onlyOwner;
```

使用qtumjs调用`preallocate`：

```ts
async function preallocate(receiverAddress, tokens, price) {
  const tx = await crowdsale.send("preallocate", [receiverAddress, tokens, price])
  console.log("preallocate txid", tx.txid)

  const receipt = await tx.confirm(1)
  console.log("preallocate receipt:")

  console.log(JSON.stringify(receipt, null, 2))
}
```

下面使用CLI脚本将token分配给第一个投资者：

```
node index.js preallocate \
  77913e470293e72c1e93ed8dda8c1372dfc0274f \
  6000000 \
  50000
```

交易确认后，将会看到`Transfer`和`Invested` events已经生成：

```
"logs": [
  {
    "value": "5b8d80",
    "from": "0000000000000000000000000000000000000000",
    "to": "77913e470293e72c1e93ed8dda8c1372dfc0274f",
    "type": "Transfer"
  },
  {
    "investor": "77913e470293e72c1e93ed8dda8c1372dfc0274f",
    "weiAmount": "45d964b800",
    "tokenAmount": "5b8d80",
    "customerId": "0",
    "type": "Invested"
  }
]
```

检查账本是否确实已经将token分配给了该投资者：

```
node index.js investedBy \
  77913e470293e72c1e93ed8dda8c1372dfc0274f

invested by: 77913e470293e72c1e93ed8dda8c1372dfc0274f
amount (qtum): 3000
token balance: 6000000
```

这样，给第一个投资者分配token的过程就结束了。下面重复上述过程，给第二个投资者分配token：

```
node index.js preallocate \
  78d55bb60f8c0e80fda479b02e40407ee0a88ab1 \
  4000000 \
  50000
```

检查账本：

```
node index.js investedBy 78d55bb60f8c0e80fda479b02e40407ee0a88ab1

invested by: 78d55bb60f8c0e80fda479b02e40407ee0a88ab1
amount (qtum): 2000
token balance: 4000000
```

在预分配后，众筹信息也会相应地发生改变：

```
node index.js info

token supply: 40000000
crowdsale state: PreFunding
crowdsale start date: 2018-01-15T00:00:00.000Z
crowdsale end date: 2018-03-01T00:00:00.000Z
investor count: 0
qtum raised: 5000
tokens sold: 10000000
```

> 注意：投资者的数量仍然为0，因为合约的实现是假定一个预分配地址实际上可能将token进一步分配给任意数量的小额投资者的。

# 公众投资

一旦众筹处于`Funding`状态，公众投资者可能就会开始投入资金。投资者可以使用 [invest](https://github.com/TokenMarketNet/ico/blob/2835f331fd9a9356131dfcf0ddd2cee471b9e32f/contracts/Crowdsale.sol#L104) method。

> 在 [getState](https://github.com/TokenMarketNet/ico/blob/2835f331fd9a9356131dfcf0ddd2cee471b9e32f/contracts/CrowdsaleBase.sol#L361) method中定义了确定众筹状态的精确条件。

`invest` method发送大量的qtum，并根据已确定的定价策略获得相应数量的token。该method进行计算时会消耗比较多的gas，因此我们设定的gas上限为300000：

```ts
async function invest(address, amount) {
  console.log("invest", address, amount)
  const tx = await crowdsale.send("invest", [address], {
    amount,
    gasLimit: 300000,
  })
  console.log("invest txid", tx.txid)
  const receipt = await tx.confirm(1)
  console.log("invest receipt:")
  console.log(JSON.stringify(receipt, null, 2))
}
```

调用CLI工具进行投资，投资金额为7000个QTUM：

```
node index.js invest \
  6607919dd81d8e958b31e2ef089139505faada4d \
  7000
```

交易确认后，可以看到该地址已经接收到了MTK：

```
node index.js investedBy 6607919dd81d8e958b31e2ef089139505faada4d

invested by: 6607919dd81d8e958b31e2ef089139505faada4d
amount (qtum): 7000
token balance: 7000000
```

众筹信息也应该已经更新：

```
node index.js info

investor count: 1
qtum raised: 12000
tokens sold: 17000000
minimum funding goal: 12000
minimum funding goal reached: true
```

这一个投资者就帮我们达到了融资目标。

## 默认的支付Method

默认情况下，不允许投资者直接通过将钱发送给合约的方法进行投资，默认的方法是通过throw：

```
/**
  * Don't expect to just send in money and get tokens.
  */
function() payable {
  throw;
}
```

如果需要的话，可以在`Crowdsale`合约的子类中重写该默认方法。

# 结束众筹

在结束日期到达后，有两种方式结束一个众筹，这取决于该众筹是否成功。

1. 如果最小的融资目标达成，众筹结束，这样投资者就可以对token进行转移和交易。
2. 如果最小的融资目标没有达成，将每个投资者发送的金额退回。

## 提前结束

我们可以设置合约的`endsAt`属性来延长众筹的期限或者提前结束众筹。

下面，我们举一个提前结束众筹的例子。调用 [setEndsAt](https://github.com/TokenMarketNet/ico/blob/2835f331fd9a9356131dfcf0ddd2cee471b9e32f/contracts/CrowdsaleBase.sol#L265) method 在60秒内结束众筹：

```ts
async function endCrowdsaleNow() {
  const nowDate = new Date()
  // You may need to choose a larger delay than 60s on a
  // real network, where there may be a larger clock skew.
  const now = Math.floor(nowDate / 1000) + 60
  const tx = await crowdsale.send("setEndsAt", [now])
  const receipt = await tx.confirm(1)
  console.log("end now receipt:")
  console.log(JSON.stringify(receipt, null, 2))
}
```

运行CLI脚本：

```json
node index.js endnow
```

输出为：

```json
{
  "blockHash": "66f22e1eb5baa344393de75b8133fadd81aa06b9697ef89eb5fcc5d4f1146507",
  "blockNumber": 6351,
  "transactionHash": "ea267d815839a89db017b8c9f83dfa7c15d9b83cff3893c6ca1831e0525dd975",
  "transactionIndex": 1,
  "from": "eb6a149ec16aaaa6e47b6c0048520f7d9563b20a",
  "to": "d7329343d159af9b628212e4ec6986d54882b3f3",
  "cumulativeGasUsed": 29025,
  "gasUsed": 29025,
  "contractAddress": "d7329343d159af9b628212e4ec6986d54882b3f3",
  "logs": [
    {
      "newEndsAt": "5a7c063b",
      "type": "EndsAtChanged"
    }
  ],
  "rawlogs": [
    {
      "address": "d7329343d159af9b628212e4ec6986d54882b3f3",
      "topics": [
        "d34bb772c4ae9baa99db852f622773b31c7827e8ee818449fef20d30980bd310"
      ],
      "data": "000000000000000000000000000000000000000000000000000000005a7c063b"
    }
  ]
}
```

## 众筹成功：结束众筹

假设融资目标达到了，调用 [finalize](https://github.com/TokenMarketNet/ico/blob/2835f331fd9a9356131dfcf0ddd2cee471b9e32f/contracts/CrowdsaleBase.sol#L226) 释放token，这样token可以用于传输和交易。

```js
async function finalize() {
  const finalized = await crowdsale.return("finalized")

  if (finalized) {
    throw new Error("crowdsale is already finalized")
  }

  const tx = await crowdsale.send("finalize")
  const receipt = await tx.confirm(1)
  console.log("finalize receipt:", receipt)
}
```

运行CLI脚本：

```
node index.js finalize
```

输出为：

```
finalize receipt:

{ blockHash: '1bb4bce0b258eb5cb7fa99cc59d1c3e8eca7fabdba98bf1ddcf329ba35943f00',
  blockNumber: 6468,
  transactionHash: '460942ae789a0c86674663fe9740bfbe5db843efec64a8074d35bcba31eb7d7c',
  transactionIndex: 1,
  from: 'eb6a149ec16aaaa6e47b6c0048520f7d9563b20a',
  to: '004fece7860cfa26a5be3009020430440e4784a4',
  cumulativeGasUsed: 83254,
  gasUsed: 83254,
  contractAddress: '004fece7860cfa26a5be3009020430440e4784a4',
  logs: [],
  rawlogs: [] }
```

### 测试Token转移功能

众筹结束后，token应该变得可以转移了。下面我们生成一个新的地址，并尝试给这个地址发送一些token：

```
qcli getnewaddress
qdobbjdAGJmi4Syu7EjDN7XcdE8nFpbgCm

qcli gethexaddress qdobbjdAGJmi4Syu7EjDN7XcdE8nFpbgCm
de12b9e72a21394a405ce1830e223beaf2dc1a40
```

众筹的过程中，有一个投资者从ICO中获得了7百万个token：

```
node index.js balanceOf 6607919dd81d8e958b31e2ef089139505faada4d

balance: 7000000
```

我们需要预先为发送方地址提供UTXO以支付交易费用：

```
$ qcli fromhexaddress 6607919dd81d8e958b31e2ef089139505faada4d
qSrs9VHVveZpiYojiaZc8VAz8JJFDu9y7o

$ solar prefund qSrs9VHVveZpiYojiaZc8VAz8JJFDu9y7o 0.1 100
```

现在，转1000个token给地址`de12b9e72a21394a405ce1830e223beaf2dc1a40`：

```
node index.js transfer \
  qSrs9VHVveZpiYojiaZc8VAz8JJFDu9y7o \
  de12b9e72a21394a405ce1830e223beaf2dc1a40 \
  1000
```

After confirmation, the balance of the receiving address should be 1000:

```
node index.js balanceOf \
  de12b9e72a21394a405ce1830e223beaf2dc1a40
```

交易确认后，接收地址的余额应该为1000：

```
node index.js balanceOf \
  6607919dd81d8e958b31e2ef089139505faada4d
balance: 6999000
```

恭喜，到这一步，你已经成功地完成了一个众筹！

## 众筹失败：退回众筹的资金

假设众筹结束了，但是最小的融资目标并没有达到:

```
node index.js info
token supply: 37000000
crowdsale state: PreFunding
crowdsale start date: 2018-01-15T00:00:00.000Z
crowdsale end date: 2018-02-08T09:43:00.000Z
investor count: 1
qtum raised: 7000
tokens sold: 7000000
minimum funding goal: 12000
minimum funding goal reached: false
```
我们可以延长众筹的结束日期来给投资者更多的时间。但是在这个示例中，我们将资金退回给所有的投资者。

启动退款流程：

1. 众筹的owner调用 [loadRefund](https://github.com/TokenMarketNet/ico/blob/2835f331fd9a9356131dfcf0ddd2cee471b9e32f/contracts/CrowdsaleBase.sol#L315) 来退还目前为止所筹集到的所有金额。
2. 个人投资者调用 [refund](https://github.com/TokenMarketNet/ico/blob/2835f331fd9a9356131dfcf0ddd2cee471b9e32f/contracts/CrowdsaleBase.sol#L326) 来认领资产。

### Owner Loading Refund（Owner加载退款进程）

```js
async function loadRefund() {
  const amountRaised = await crowdsale.returnCurrency("qtum", "weiRaised")

  const loadedRefund = await crowdsale.returnCurrency("qtum", "loadedRefund")

  const amountToLoad = amountRaised - loadedRefund

  console.log("amount to load as refund", amountToLoad)

  if (amountToLoad > 0) {
    const tx = await crowdsale.send("loadRefund", [], {
      amount: amountToLoad,
    })
    console.log("tx:", tx)
    const receipt = await tx.confirm(1)
    console.log("receipt", receipt)
  }
}
```

```
node index.js loadRefund
```

### 投资者认领资产

地址`6607919dd81d8e958b31e2ef089139505faada4d`投资的金额应该是7000qtum：

```
node index.js investedBy \
 6607919dd81d8e958b31e2ef089139505faada4d

invested by: 6607919dd81d8e958b31e2ef089139505faada4d
amount (qtum): 7000
token balance: 7000000
```

投资者可以采用如下方式调用 [refund](https://github.com/TokenMarketNet/ico/blob/2835f331fd9a9356131dfcf0ddd2cee471b9e32f/contracts/CrowdsaleBase.sol#L326) ：

```js
async function refund(addr) {
  const tx = await crowdsale.send("refund", [], {
    senderAddress: addr,
  })
  const receipt = await tx.confirm(1)
  console.log("receipt", receipt)
}
```

运行CLI：

```
node index.js refund \
  qSrs9VHVveZpiYojiaZc8VAz8JJFDu9y7o

{ blockHash: '09ea6c4cdf9e0007d21d43f9a3f6fe9fd124621118d8384bb9c6575a04320faa',
  blockNumber: 6641,
  transactionHash: '11290f6e8809a94273d12fe202c5f2898e14be3f51edf81c43b73bf4259c412d',
  transactionIndex: 1,
  from: '6607919dd81d8e958b31e2ef089139505faada4d',
  to: '8a4e597e966b9c8886c006ce84168b9fc6734c22',
  cumulativeGasUsed: 53815,
  gasUsed: 53815,
  contractAddress: '8a4e597e966b9c8886c006ce84168b9fc6734c22',
  logs:
   [ Result {
       investor: '6607919dd81d8e958b31e2ef089139505faada4d',
       weiAmount: <BN: a2fb405800>,
       type: 'Refund' } ],
  rawlogs:
   [ { address: '8a4e597e966b9c8886c006ce84168b9fc6734c22',
       topics: [Array],
       data: '0000000000000000000000006607919dd81d8e958b31e2ef089139505faada4d000000000000000000000000000000000000000000000000000000a2fb405800' } ] }
```

使用`listunspent`命令查看资金是否确实已经被退回：

```
qcli listunspent 0 999990 \
  '["qSrs9VHVveZpiYojiaZc8VAz8JJFDu9y7o"]'
```

针对这个具有7000个qtum的地址，将有一个UTXO被创建：

```
[
  // other UTXOs ...

  {
    "txid": "e0afc2742ffa636c6ff788fbb808f5b34276206d713bb25874cb0e48a0070974",
    "vout": 0,
    "address": "qSrs9VHVveZpiYojiaZc8VAz8JJFDu9y7o",
    "account": "",
    "scriptPubKey": "76a9146607919dd81d8e958b31e2ef089139505faada4d88ac",
    "amount": 7000.00000000,
    "confirmations": 5,
    "spendable": true,
    "solvable": true
  }
]
```

