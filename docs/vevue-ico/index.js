const { Qtum } = require("qtumjs")
const BN = require("bn.js")

const repoData = require("./solar.development.json")

const qtum = new Qtum("http://qtum:test@localhost:3889", repoData)

const mytoken = qtum.contract("VevueToken.sol")

let decimals = 8
function tokenAmount(bnumber) {
  const nstr = bnumber.toString()
  const amountUnit = nstr.substring(0, nstr.length - decimals)
  const amountDecimals = nstr.substring(nstr.length - decimals)

  return `${amountUnit === "" ? 0 : amountUnit}.${amountDecimals}`
}

async function showInfo() {
  const totalSupply = await mytoken.return("totalSupply")
  const saleAmount = await mytoken.return("saleAmount")
  const tokensSold = await mytoken.return("tokensSold")

  const tokenTotalSupply = (await mytoken.call("tokenTotalSupply")).outputs[0]

  console.log("supply cap:", tokenAmount(tokenTotalSupply))
  console.log("sales cap:", tokenAmount(saleAmount))
  console.log("current token supply:", tokenAmount(totalSupply))
  console.log("tokens sold:", tokenAmount(tokensSold))
}

/**
 *
 * @param {string} beneficiary address to send purchase tokens
 * @param {number} amount amount of qtum used to purchase tokens
 */
async function buyTokens(beneficiary, amount) {
  const tx = await mytoken.send("buyTokens", [beneficiary], {
    amount,
  })

  const res = await tx.confirm(1)
  console.log(res)
}

async function mintTokens(amount) {
  const tx = await mytoken.send("mintReservedTokens", [amount])
  const res = await tx.confirm(1)
  console.log(res)
}

async function tokenBalance(address) {
  const balance = await mytoken.return("balanceOf", [address])
  console.log(tokenAmount(balance))
}

async function main() {
  const argv = process.argv.slice(2)

  const cmd = argv[0]

  if (process.env.DEBUG) {
    console.log("argv", argv)
    console.log("cmd", cmd)
  }

  switch (cmd) {
    case "info":
      await showInfo()
      break
    case "buy":
      const buyAmount = parseFloat(argv[2])
      if (!buyAmount) {
        throw new Error(`Invalid amount: ${argv[2]}`)
      }
      await buyTokens(argv[1], buyAmount)
      break
    case "balanceOf":
      await tokenBalance(argv[1])
      break

    case "mint":
      const mintAmount = parseFloat(argv[1])
      if (!mintAmount) {
        throw new Error(`Invalid amount: ${argv[1]}`)
      }
      await mintTokens(mintAmount)
      break
    default:
      console.log("unrecognized command", cmd)
  }
}

main().catch((err) => {
  console.log("err", err)
})
