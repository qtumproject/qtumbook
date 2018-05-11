const { Qtum } = require("qtumjs")

const repoData = require("./solar.development.json")

const qtum = new Qtum("http://qtum:test@localhost:3889", repoData)

const mytoken = qtum.contract("contracts/MyToken.sol")
const crowdsale = qtum.contract("contracts/MyCrowdsale.sol")

async function setupCrowdsale() {
  const mint = await mytoken.send("mint", [crowdsale.address, 10000 * 1000 * 1e8])
  console.log("minted", await mint.confirm(1))
}

async function testCrowdsaleTransfer() {
  console.log("address", crowdsale.info.sender)
  const transfer = await mytoken.send("transfer", ["c71437556c8d9dcb14e8bf51b55e2660fe4f294e", 0.1 * 1e8], {
    senderAddress: "qNDh5XN6gpVEMnwTQ2d66jaEENtkVx3Q8n",
  })
  console.log("transferred", await transfer.confirm(1))
}

async function buyTokens() {
  const callres = await crowdsale.call("buyTokens", ["c71437556c8d9dcb14e8bf51b55e2660fe4f294e"], {
    amount: 0.1,
    senderAddress: "qSLQEDyJBLPYxwPEAWy7UcjeBtfHgzr86g",
  })

  console.log("callres", JSON.stringify(callres, null, 2))

  // const tx = await crowdsale.send("buyTokens", ["c71437556c8d9dcb14e8bf51b55e2660fe4f294e"], {
  //   amount: 0.1,
  //   senderAddress: "qSLQEDyJBLPYxwPEAWy7UcjeBtfHgzr86g",
  // })
  // const res = await tx.confirm(1)
  // console.log(res)
}

async function main() {
  const argv = process.argv.slice(2)

  const cmd = argv[0]

  if (process.env.DEBUG) {
    console.log("argv", argv)
    console.log("cmd", cmd)
  }

  switch (cmd) {
    case "setup":
      await setupCrowdsale()
      break
    case "buy":
      await buyTokens()
      break
    case "transfer":
      await testCrowdsaleTransfer()
      break
    default:
      console.log("unrecognized command", cmd)
  }
}

main().catch((err) => {
  console.log("err", err)
})
