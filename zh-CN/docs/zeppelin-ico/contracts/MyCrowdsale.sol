pragma solidity ^0.4.18;

// import "zeppelin-solidity/contracts/token/ERC20/ERC20.sol";
// import "zeppelin-solidity/contracts/crowdsale/validation/CappedCrowdsale.sol";

import "./MyToken.sol";

contract MyCrowdsale
{
  // event ErrorLog(string message);
  // event TraceLog(string message);

  // event BuyTokensLog(address _beneficiary, address _token);

  MyToken public token;

  function MyCrowdsale(
    uint256 _cap, uint256 _rate, address _wallet, MyToken _token) public
    // CappedCrowdsale(_cap)
    // Crowdsale(_rate, _wallet, _token)
  {
    token = _token;
  }

  function buyTokens(address _beneficiary) public {
    // emit TraceLog("enter buyTokens");

    // emit BuyTokensLog(_beneficiary, token);

    // token.transfer(_beneficiary, 1);

    // token.foo(_beneficiary, 1);

    token.bar();
  }
}
