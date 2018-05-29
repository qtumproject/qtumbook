* on purchase, will send token from wallet to investor
* has fallback function, calls buyTokens
* oh fuck. cap is specified in wei/satoshi

* how about setting decimals to 1e-8?

* 1 QTUM to 1000 MYT
* rate = 1000 (1 qtum satoshi for 1000 MYT satoshi)
* cap = 10000 QTUM
  *  cap = 10000 * 1e5 = 10000000000 = 1e15

+ cap
* let's say we wanna raise 10000 qtum.
  * 10000 * 1e8 = 10000000000000 = 1e15


```
qcli getnewaddress
qSLQEDyJBLPYxwPEAWy7UcjeBtfHgzr86g

qcli gethexaddress qSLQEDyJBLPYxwPEAWy7UcjeBtfHgzr86g
60449ea1e779457a004e6a07a5ee2c1dc46acb75
```

```
export QTUM_SENDER=qSLQEDyJBLPYxwPEAWy7UcjeBtfHgzr86g
```

```
qcli sendtoaddress qSLQEDyJBLPYxwPEAWy7UcjeBtfHgzr86g 10
```


```
solar deploy contracts/MyToken.sol

solar deploy contracts/MyCrowdsale.sol '
[
  1e15,
  1000,
  "60449ea1e779457a004e6a07a5ee2c1dc46acb75",
  ${contracts/MyToken.sol}
]
' --force
```

# mint tokens

* total supply 20,000,000
* sell 50% 10000 * 1000 * 1e8
  * 1000000000000000
* mint 2000000000000000
  * to 60449ea1e779457a004e6a07a5ee2c1dc46acb75

# buy tokens

Let's generate another address and use it as the investor.

* lame. there needs to be a way for the crowdsale to act as minting or transfer agent
 * i see. mint the tokens for the crowdsale -.-

```
qcli getnewaddress
qbi1qr9FBoXrAXavQ1BScM9zkjCPU4qvxD

qcli gethexaddress qbi1qr9FBoXrAXavQ1BScM9zkjCPU4qvxD
c71437556c8d9dcb14e8bf51b55e2660fe4f294e

qcli sendtoaddress qSLQEDyJBLPYxwPEAWy7UcjeBtfHgzr86g 100
```

```
qcli sendtocontract 538d26b05e898378ac089d6c785a028a091ae30f \
  ec8ac4d8000000000000000000000000c71437556c8d9dcb14e8bf51b55e2660fe4f294e \
  0.1 \
  200000 \
  0.0000004 \
  qSLQEDyJBLPYxwPEAWy7UcjeBtfHgzr86g
```

1 * 1e8

# transfer token

* transfer to: c71437556c8d9dcb14e8bf51b55e2660fe4f294e

```
qcli sendtocontract \
  62baf6e0e9b1f651924f202eaa39cf7b363c3797 \
  a9059cbb000000000000000000000000c71437556c8d9dcb14e8bf51b55e2660fe4f294e0000000000000000000000000000000000000000000000000000000000002710 \
  1 \
  200000 \
  0.0000004 \
  qSLQEDyJBLPYxwPEAWy7UcjeBtfHgzr86g
```
