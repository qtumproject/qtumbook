solar deploy contracts/MyToken.sol --force

solar deploy contracts/MyCrowdsale.sol '
[
  1e15,
  1000,
  "60449ea1e779457a004e6a07a5ee2c1dc46acb75",
  ${contracts/MyToken.sol}
]
' --force
