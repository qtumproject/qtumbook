# Holding A Crowdsale

In this chapter, we'll hold an hypothetical crowdsale for an ERC20 token. We will use the crowdsale contracts developed [TokenMarketNet](https://github.com/TokenMarketNet/ico). These contracts are significantly more complex than the toy examples we have seen up to now. There are many configurable options you may tweak to suit your needs.

# The ICO Design

The TokenMarketNet contracts cover many common scenarios for ICOs, providing support for different types of tokens, different caps, and different pricing strategies.

Our crowdsale will have the following configuration:

+ BurnableCrowdsaleToken

This is essentially a mintable token. It also provides the option to burn tokens, for example if you'd like to lower the percentage of tokens the team holds if the crowdsale did not reach the maximum sales goal.

+ FlatPricing

Everyone that participates in the public sale gets the same price. There are other pricing strategies like [TokenTranchePricing](https://github.com/TokenMarketNet/ico/blob/master/contracts/TokenTranchePricing.sol) or [MilestonePricing](https://github.com/TokenMarketNet/ico/blob/master/contracts/MilestonePricing.sol).

The prices are specified in satoshi (10^-8) per token.

+ MintedTokenCappedCrowdsale

This is a crowdsale capped by number of tokens sold.

## Supply, Allocation, And Pricing

Let's now determine the parameters for this crowdsale. For simplicity, we'll assume that qtum's price is $100 USD.

The name:

* Token name: MyToken
* Token symbol: MTK
* Decimals: 0 (for indivisible tokens. See: [Understanding ERC20](https://medium.com/@jgm.orinoco/understanding-erc-20-token-contracts-a809a7310aa5)).


The supply allocation is as follows:

* Total Supply: 100,000,000 MTK
* Team: 10%
* Foundation: 20%
* Presale: 10%, at 50% discount
* Public ICO: 60%

The prices are:

* Presale
  * Price: 50000 QTUM Satoshi ($0.05 in fiat)
  * Presale tokens: 10,000,000
  * 2000 MTK : 1 QTUM
  * Presale amount: 5000 QTUM ($500,000)
* Public ICO
  * Price: 100000 QTUM Satoshi ($0.1 in fiat)
  * ICO tokens: 60,000,000
  * 1000 MTK : 1 QTUM
  * ICO funding: 60000 QTUM ($6,000,000)

The valuation of the token is 10M post ICO.

# Running The Code

Clone contracts:

```
git clone --recursive https://github.com/TokenMarketNet/ico.git
```

## Running QTUMD

Run qtumd in regtest mode:

```
docker run -it --rm \
  --name myico \
  -v `pwd`:/dapp \
  -p 3889:3889 \
  -p 9899:9899 \
  -p 9888:9888 \
  hayeah/qtumportal
```

Then generate some initial blocks:

```
docker exec -it myico sh
```

```
qcli generate 600
```

# Configure The ICO Owner Address

We'll need to create an address that "owns" all the contracts related to this ICO.

```
qcli getnewaddress
qf292iYbjJ41oMoArA3PrHpxTdAHuQsuAu

qcli gethexaddress qf292iYbjJ41oMoArA3PrHpxTdAHuQsuAu
eb6a149ec16aaaa6e47b6c0048520f7d9563b20a
```

Prefund it with 100 UTXOs:

```
solar prefund qf292iYbjJ41oMoArA3PrHpxTdAHuQsuAu 0.1 100
```

Then we need to configure `solar` to use this address when creating contracts (otherwise a random UTXO would be selected as the owner). In the container shell, set the `QTUM_SENDER` environment variable:

```
export QTUM_SENDER=qf292iYbjJ41oMoArA3PrHpxTdAHuQsuAu
```

We will also use the owner address to receive the crowdsale investment.

# Deploy Library

The crowdsale contracts rely on the `SafeMathLib` library for arithemetics, so that integer overflows would raise errors.

Use the `lib` option to deploy a contract as library:

```
solar deploy contracts/SafeMathLib.sol --lib

🚀  All contracts confirmed
   deployed contracts/SafeMathLib.sol => 26fe40c433b4d109299660284eaa475b95462342
```

Once deployed, other contracts that reference the `SafeMathLib` library are automatically linked to the library instance deployed at the address `26fe40c433b4d109299660284eaa475b95462342`.

# Deploy The Crowdsale Contracts

There are four contracts to deploy.

## The ERC20 Token

The constructor for the ERC20 token:

```
BurnableCrowdsaleToken(
  string _name,
  string _symbol,
  uint _initialSupply,
  uint _decimals,
  bool _mintable)
```

https://github.com/TokenMarketNet/ico/blob/master/contracts/BurnableCrowdsaleToken.sol#L18

Per the supply allocation plan, we allocate 10% to team and 20% to foundation, for a total of 30,000,000 tokens.

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

The initial supply is set to 30M, with the tokens assigned to the contract owner. These tokens may later be transferred to the foundation and team vesting vault as necessary.

## Pricing Strategy

The constructor for the `FlatPricing` strategy is straightforward:

```
function FlatPricing(uint _oneTokenInWei)
```

https://github.com/TokenMarketNet/ico/blob/f5b3ac6b5773f707943289b6ab1914a6b4e30683/contracts/FlatPricing.sol#L22

Note that this contract was written for Ethereum, whose smallest unit is `wei` (10^-9). However, QTUM inherits its ledger from Bitcoin, whose smallest unit is `satoshi` (10^-8).

So even though the constructor parameter name is `_oneTokenInWei`, what it really means is `_oneTokenInSatoshi`.

The price for the public ICO is 100000 qtum satoshi (1000 MTK : 1 qtum).

```
solar deploy contracts/FlatPricing.sol '
[
  100000
]
'
```

## Crowdsale Contract

The crowdsale contract has a more complicated constructor:

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

We'll need the start and end time, in [unix time](https://en.wikipedia.org/wiki/Unix_time):

```
> new Date('2018-01-15T00:00:00Z') / 1000
1515974400
> new Date('2018-03-01T00:00:00Z') / 1000
1519862400
```

The deploy command:

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

The constructor parameters are described below:

* `_token`
  * Use `${MyToken}` to interpolate the address of the `MyToken` contract.
* `_pricingStrategy`
  * Use `${contracts/FlatPricing.sol}` to interpolate the address of pricing strategy.
* `_multisigWallet`
  * `0xeb6a149ec16aaaa6e47b6c0048520f7d9563b20a`, the owner address.
* `_minimumFundingGoal`, specified in satoshi.
  * Let's set it to 20% of the funding cap.
  * 60000 qtum * 20% == 12000 qtum == 12000 * 10^8 satoshi == 1200000000000 satoshi
* `_maximumSellableTokens`
  * 60,000,000 tokens

## Finalize Agent

The finalize agent is a way to specify a callback that should execute when the crowdsale is successful. The least it needs to do is to release the tokens so holders are free to transfer tokens.

In this example we use the `DefaultFinalizeAgent`, which releases the token, and does nothing else:

```
function DefaultFinalizeAgent(
  ReleasableToken _token,
  Crowdsale _crowdsale
)
```

To deploy it:

```
solar deploy contracts/DefaultFinalizeAgent.sol:FinalizeAgent '
[
  ${MyToken},
  ${Crowdsale}
]
'
```

# Sanity Check

You should now have four contracts deployed:

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

Make sure that all of them share the same owner. If not, make sure that the environment variable `QTUM_SENDER` is set to the owner address, and try again.

You may query for the basic information about these contracts using qtumjs:

```ts
console.log("token supply:", await mytoken.return("totalSupply"))
console.log("crowdsale state:", await crowdsale.returnAs(stateName, "getState"))
console.log("crowdsale start date:", await crowdsale.returnDate("startsAt"))
console.log("crowdsale end date:", await crowdsale.returnDate("endsAt"))

console.log("investor count:", await crowdsale.return("investorCount"))
console.log("qtum raised:", await crowdsale.returnCurrency("qtum", "weiRaised"))
console.log("tokens sold:", await crowdsale.return("tokensSold"))
```

Run the CLI script to print the info:

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

Note that the state is in `Preparing`, not quite ready for action.

# Crowdsale Setup

There is just a bit more setup, to grant permissions to different contracts to do their jobs.

The setup script:

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

Run the script with node:

```
node index.js setup

releaseAgent coinfigured
finalizeAgent coinfigured
mintAgents coinfigured
```

Getting the info again, you should see that the crowdsale state have transitioned to `PreFunding`:

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

> The info shows the state as `PreFunding` even if the current time had past the start date. The actual state should be `Funding`. This problem will be fixed by [qtum #480](https://github.com/qtumproject/qtum/issues/480)

# Preallocate

According to our ICO plan, we have already sold 10% of the token supply (10,000,000) to early investors. We'd like to record their investments on the ledger.

We assume that there are two investors, who invested at the same price:

```yaml
- address: "77913e470293e72c1e93ed8dda8c1372dfc0274f"
  tokens: 6000000
  price: 50000

- address: "78d55bb60f8c0e80fda479b02e40407ee0a88ab1"
  tokens: 4000000
  price: 50000
```

The [preallocate](https://github.com/TokenMarketNet/ico/blob/2835f331fd9a9356131dfcf0ddd2cee471b9e32f/contracts/Crowdsale.sol#L65) method allows the crowdsale owner to assign tokens to investor addresses. It is assumed that the investment money had already been transfered to the owner privately.

```
function preallocate(
  address receiver,
  uint fullTokens,
  uint weiPrice
) public onlyOwner;
```

To invoke `preallocate` with qtumjs:

```ts
async function preallocate(receiverAddress, tokens, price) {
  const tx = await crowdsale.send("preallocate", [receiverAddress, tokens, price])
  console.log("preallocate txid", tx.txid)

  const receipt = await tx.confirm(1)
  console.log("preallocate receipt:")

  console.log(JSON.stringify(receipt, null, 2))
}
```

Let's use the CLI script to allocate tokens to the first investor:

```
node index.js preallocate \
  77913e470293e72c1e93ed8dda8c1372dfc0274f \
  6000000 \
  50000
```

After the transaction confirms, you should see that the events `Transfer` and `Invested` are generated:

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

Check that the ledger had indeed allocated the tokens to this investor:

```
node index.js investedBy \
  77913e470293e72c1e93ed8dda8c1372dfc0274f

invested by: 77913e470293e72c1e93ed8dda8c1372dfc0274f
amount (qtum): 3000
token balance: 6000000
```

We've finished allocation for one investor, let's repeat it for the second investor:

```
node index.js preallocate \
  78d55bb60f8c0e80fda479b02e40407ee0a88ab1 \
  4000000 \
  50000
```

Check the ledger:

```
node index.js investedBy 78d55bb60f8c0e80fda479b02e40407ee0a88ab1

invested by: 78d55bb60f8c0e80fda479b02e40407ee0a88ab1
amount (qtum): 2000
token balance: 4000000
```

After preallocation, the crowdsale info should have changed accordingly:

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

> Note: the investor count is still 0 because the contract implementation assumes that one preallocation address may in fact distribute the tokens further to an arbitrary number of a smaller investors.

# Invest

Once the crowdsale is in the `Funding` state, public investors may start to send in money. We'll let the investors use the [invest](https://github.com/TokenMarketNet/ico/blob/2835f331fd9a9356131dfcf0ddd2cee471b9e32f/contracts/Crowdsale.sol#L104) method.

> The precise conditions that determines the state of the crowdsale is defined in the [getState](https://github.com/TokenMarketNet/ico/blob/2835f331fd9a9356131dfcf0ddd2cee471b9e32f/contracts/CrowdsaleBase.sol#L361) method.

The `invest` method sends in an amount of qtum, and receive a corresponding amount of tokens as determined by the pricing strategy. This method is more expensive to compute, so we set a higher gas limit of 300,000:

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

Invoke the CLI tool to invest 7000 QTUMs:

```
node index.js invest \
  6607919dd81d8e958b31e2ef089139505faada4d \
  7000
```

After confirmation, we should see that this address had received 3000 MTKs:

```
node index.js investedBy 6607919dd81d8e958b31e2ef089139505faada4d

invested by: 6607919dd81d8e958b31e2ef089139505faada4d
amount (qtum): 7000
token balance: 7000000
```

And the crowdsale info should have updated as well:

```
node index.js info

investor count: 1
qtum raised: 12000
tokens sold: 17000000
minimum funding goal: 12000
minimum funding goal reached: true
```

This single investor had helped us reach the funding goal!

## The Default Payment Method

By default an investor is not allowed to invest by sending money to this contract directly. The default action is to throw:

```
/**
  * Don't expect to just send in money and get tokens.
  */
function() payable {
  throw;
}
```

If this is a desired behaviour, you could override the default method in your on subclass of the `Crowdsale` contract.

# Ending The Crowdsale

There are two ways to end a crowdsale once the end date is reached, depending on whether the sale was successful.

1. If the minimum funding goal was reached, finalize the crowdsale, so investors can start to transfer and trade the tokens.
2. If the minimum funding goal was not reached, refund each investor the amount they sent.

## Ending Early

We can set the `endsAt` property of the contract to either extend the deadline or to end the crowdsale early.

For our example, we'll end the crowdsale early. Invoke the [setEndsAt](https://github.com/TokenMarketNet/ico/blob/2835f331fd9a9356131dfcf0ddd2cee471b9e32f/contracts/CrowdsaleBase.sol#L265) method to end the crowdsale 60 seconds from now:

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

Run the CLI script:

```json
node index.js endnow
```

The expected output:

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

## Success: Finalize The Crowdsale

Suppose the funding goal was reached, invoking [finalize](https://github.com/TokenMarketNet/ico/blob/2835f331fd9a9356131dfcf0ddd2cee471b9e32f/contracts/CrowdsaleBase.sol#L226) will release the token for transferring.

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

Run the CLI script:

```
node index.js finalize
```

The output:

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

### Testing Token Transfer

After finalizing, the tokens should become transferrable. Let's generate a new address and try to send it some tokens:

```
qcli getnewaddress
qdobbjdAGJmi4Syu7EjDN7XcdE8nFpbgCm

qcli gethexaddress qdobbjdAGJmi4Syu7EjDN7XcdE8nFpbgCm
de12b9e72a21394a405ce1830e223beaf2dc1a40
```

One of the investor should have 7000000 tokens from the ICO:

```
node index.js balanceOf 6607919dd81d8e958b31e2ef089139505faada4d

balance: 7000000
```

We need to prefund the sender address with UTXOs to pay for transactions:

```
$ qcli fromhexaddress 6607919dd81d8e958b31e2ef089139505faada4d
qSrs9VHVveZpiYojiaZc8VAz8JJFDu9y7o

$ solar prefund qSrs9VHVveZpiYojiaZc8VAz8JJFDu9y7o 0.1 100
```

Now, transfer 1000 tokens to the address `de12b9e72a21394a405ce1830e223beaf2dc1a40`:

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

And the balance of the original sender should have decremented by 1000:

```
node index.js balanceOf \
  6607919dd81d8e958b31e2ef089139505faada4d
balance: 6999000
```

Congrats, you have completed a successful crowdsale!

## Failure: Refund The Crowdsale

Suppose the crowdsale ended but the minimum funding goal was not reached:

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

We could extend the end date to give investors more time. But in this demostration we'll just refund everyone.

To initiate the refund process:

1. The crowdsale owner invokes [loadRefund](https://github.com/TokenMarketNet/ico/blob/2835f331fd9a9356131dfcf0ddd2cee471b9e32f/contracts/CrowdsaleBase.sol#L315) to fund the contract with the total amount raised so far.
2. Individual investor invoke [refund](https://github.com/TokenMarketNet/ico/blob/2835f331fd9a9356131dfcf0ddd2cee471b9e32f/contracts/CrowdsaleBase.sol#L326) to claim the fund.

### Owner Loading Refund

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

### Investor Claiming Fund

The amount invested by `6607919dd81d8e958b31e2ef089139505faada4d` should be 7000 qtum:

```
node index.js investedBy \
 6607919dd81d8e958b31e2ef089139505faada4d

invested by: 6607919dd81d8e958b31e2ef089139505faada4d
amount (qtum): 7000
token balance: 7000000
```

The investory can invoke [refund](https://github.com/TokenMarketNet/ico/blob/2835f331fd9a9356131dfcf0ddd2cee471b9e32f/contracts/CrowdsaleBase.sol#L326) like this:

```js
async function refund(addr) {
  const tx = await crowdsale.send("refund", [], {
    senderAddress: addr,
  })
  const receipt = await tx.confirm(1)
  console.log("receipt", receipt)
}
```

Running the CLI:

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

Use the `listunspent` command to check if the fund had indeed been returned:

```
qcli listunspent 0 999990 \
  '["qSrs9VHVveZpiYojiaZc8VAz8JJFDu9y7o"]'
```

There should be an UTXO created for this address with 7000 qtum:

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

