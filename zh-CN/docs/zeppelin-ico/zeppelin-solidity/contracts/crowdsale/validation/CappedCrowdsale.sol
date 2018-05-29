pragma solidity ^0.4.21;

import "../../math/SafeMath.sol";
import "../Crowdsale.sol";


/**
 * @title CappedCrowdsale
 * @dev Crowdsale with a limit for total contributions.
 */
contract CappedCrowdsale is Crowdsale {
  using SafeMath for uint256;

  uint256 public cap;

  /**
   * @dev Constructor, takes maximum amount of wei accepted in the crowdsale.
   * @param _cap Max amount of wei to be contributed
   */
  function CappedCrowdsale(uint256 _cap) public {
    require(_cap > 0);
    cap = _cap;
  }

  /**
   * @dev Checks whether the cap has been reached.
   * @return Whether the cap was reached
   */
  function capReached() public view returns (bool) {
    return weiRaised >= cap;
  }

  /**
   * @dev Extend parent behavior requiring purchase to respect the funding cap.
   * @param _beneficiary Token purchaser
   * @param _weiAmount Amount of wei contributed
   */
  function _preValidatePurchase(address _beneficiary, uint256 _weiAmount) internal returns(bool) {
    if (!super._preValidatePurchase(_beneficiary, _weiAmount)) {
      return false;
    }


    if (weiRaised.add(_weiAmount) > cap) {
      emit ErrorLog("crowdsale cap exceeded");
      return false;
    }

    return true;
  }

}
