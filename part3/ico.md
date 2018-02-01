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
  * Price: 500 QTUM Satoshi ($0.05 in fiat)
  * Presale tokens: 10,000,000
  * 2000 MTK : 1 QTUM
  * Presale amount: 5000 QTUM ($500,000)
* Public ICO
  * Price: 1000 QTUM Satoshi ($0.1 in fiat)
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

Prefund it with 100 uxtos:

```
solar prefund qf292iYbjJ41oMoArA3PrHpxTdAHuQsuAu 0.1 100
```

Then we need to configure `solar` to use this address when creating contracts (otherwise a random UXTO would be selected as the owner). In the container shell, set the `QTUM_SENDER` environment variable:

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
solar deploy --force contracts/MintedTokenCappedCrowdsale.sol:Crowdsale '
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

Run the script:

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
