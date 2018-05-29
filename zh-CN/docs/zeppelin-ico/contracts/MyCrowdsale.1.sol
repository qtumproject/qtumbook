pragma solidity ^0.4.21;

import "zeppelin-solidity/contracts/token/ERC20/ERC20.sol";
import "zeppelin-solidity/contracts/crowdsale/validation/CappedCrowdsale.sol";

import "./MyToken.sol";

contract MyCrowdsale is CappedCrowdsale
{

  function MyCrowdsale(
    uint256 _cap, uint256 _rate, address _wallet, ERC20 _token) public
    CappedCrowdsale(_cap)
    Crowdsale(_rate, _wallet, _token)
  {
  }
}
