# Simple Crowdsale

In this chapter we will hold a crowdsale using the contracts from Vevue's ICO. It is essentially an ERC20 token, with the addition of an `buyTokens` method. When a user sends money into the contract using `buyTokens`, tokens are minted and credited to the purchaser according to a fixed exchange rate.

The source code for this chapter is at [qtumproject/qtumjs-vevue-ico](https://github.com/qtumproject/qtumjs-vevue-ico).

There are a few hard codeed parameters in the token contract, and you could tweak them to suit your particular token design.

Some of the contract parameters are:

+ `decimals`: How "divisble" one unit token is.
  + 8 decimal places, to be as divisible as Bitcoin. The smallest unit is satoshi.
+ `tokenTotalSupply`: The maximum token supply.
  + 100M tokens in total.
+ `saleAmount`: amount of tokens to sell.
  + 40M tokens for sell
+ `_initialExchangeRate`: the exchange rate.
  + Set to 1 qtum for 100 tokens.

For simplicity, we disabled the start and end time of the crowdsale (specified in block number).

Without further ado, let's launch our crowdsale!

# Create An Owner Address

Let's generate an address to be the owner of the contract. The crowdsale proceeds will go into this address.

```
qcli getnewaddress
qJtdUF9ko4Hk95cqTzq7SDs18dapNwjRNS

qcli gethexaddress qJtdUF9ko4Hk95cqTzq7SDs18dapNwjRNS
0e9bfa516890f857beaba3eba35cc478ab10bce4
```

Send some fund to the owner address pay for gas:

```
qcli sendtoaddress qJtdUF9ko4Hk95cqTzq7SDs18dapNwjRNS 1
```

Then we should configure `solar` to use this address when we deploy new contracts.

```
export QTUM_SENDER=qJtdUF9ko4Hk95cqTzq7SDs18dapNwjRNS
```

# Deploy The Token Contract

Use solar to deploy the contract:

```
solar deploy VevueToken.sol --force

🚀  All contracts confirmed
   deployed VevueToken.sol => 09b97cc71a300f1bdad44711f4ce9f25bd404d8b
```

Verify that the contract owner is the `QTUM_SENDER` address that we've set before:

```
solar status

✅  VevueToken.sol
        txid: 08528ef006f05fdfe1d6eb3006bac7dfc21d6f854822081575b9ff8b61950cdd
     address: 09b97cc71a300f1bdad44711f4ce9f25bd404d8b
   confirmed: true
       owner: qJtdUF9ko4Hk95cqTzq7SDs18dapNwjRNS
```

## Initial Crowdsale State

We can use the included qtumjs script to print out information about the crowdsale:

```
node index.js info

supply cap: 100000000.00000000
sales cap: 40000000.00000000
current token supply: 0.0
tokens sold: 0.0
```

* Verify that the supply and sales cap are as specified
  * There are 8 decimal places
* The current supply is 0

# Buy Tokens

Let's generate another address and use it to receive the purchased tokens:

```
qcli getnewaddress
qgMR2N4ANuswodFh8T4gYMD3a3VNAd11Jt
```

```
qcli gethexaddress qgMR2N4ANuswodFh8T4gYMD3a3VNAd11Jt
fa0775ed07771e390c5a3bd2f00cef05bc4185f2
```

Now, spend 1 qtum to buy tokens (geting 100 tokens in return):

```
node index.js buy fa0775ed07771e390c5a3bd2f00cef05bc4185f2 1
```

After the tx confirms, the token's supply should have incremented by 100:

```
node index.js info

supply cap: 100000000.00000000
sales cap: 40000000.00000000
current token supply: 100.00000000
tokens sold: 100.00000000
```

We can also check that the particular address we bought the tokens for have received the correct balance:

```
node index.js balanceOf fa0775ed07771e390c5a3bd2f00cef05bc4185f2
100.00000000
```
