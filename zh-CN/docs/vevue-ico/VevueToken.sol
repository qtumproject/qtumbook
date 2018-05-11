pragma solidity ^0.4.11;

import "./StandardToken.sol";
import "./Ownable.sol";

contract VevueToken is StandardToken, Ownable {
  // Token configurations
  string public constant name = "Vevue Token";
  string public constant symbol = "Vevue";
  uint256 public constant nativeDecimals = 8;
  uint256 public constant decimals = 8;

  // uint256 public constant _fundingStartBlock = 500;
  // 604800 seconds is 7 days. about 5040 blocks
  // uint256 public constant _fundingEndBlock = 10000;
  uint256 public constant _initialExchangeRate = 100;

  /// the founder address can set this to true to halt the crowdsale due to emergency
  bool public halted = false;

  /// @notice 40 million Vevue tokens for sale
  uint256 public constant saleAmount = 40 * (10**6) * (10**decimals);

  /// @notice 100 million Vevue tokens will ever be created
  uint256 public constant tokenTotalSupply = 100 * (10**6) * (10**decimals);

  // number of tokens sold
  uint256 public tokensSold;

  // Crowdsale parameters
  // uint256 public fundingStartBlock;
  // uint256 public fundingEndBlock;
  uint256 public initialExchangeRate;

  // Events
  event Mint(uint256 supply, address indexed to, uint256 amount);
  event TokenPurchase(address indexed purchaser, address indexed beneficiary, uint256 value, uint256 amount);

  // Modifiers
  modifier validAddress(address _address) {
    require(_address != 0x0);
    _;
  }

  modifier validPurchase() {
    // require(block.number >= fundingStartBlock);
    // require(block.number <= fundingEndBlock);
    require(msg.value > 0);
    _;
  }

  modifier validUnHalt(){
    require(halted == false);
    _;
  }

  /// @notice Creates new Vevue Token contract
  function VevueToken() public
    Ownable()
  {
    // require(_fundingStartBlock >= block.number);
    // require(_fundingEndBlock >= _fundingStartBlock);
    require(_initialExchangeRate > 0);
    assert(nativeDecimals >= decimals);

    // fundingStartBlock = _fundingStartBlock;
    // fundingEndBlock = _fundingEndBlock;
    initialExchangeRate = _initialExchangeRate;
  }

  /// @notice Fallback function to purchase tokens
  function() external payable {
    buyTokens(msg.sender);
  }

  /// @notice Allows buying tokens from different address than msg.sender
  /// @param _beneficiary Address that will contain the purchased tokens
  function buyTokens(address _beneficiary)
    public
    payable
    validAddress(_beneficiary)
    validPurchase
    validUnHalt
  {
    uint256 tokenAmount = getTokenExchangeAmount(msg.value, initialExchangeRate, nativeDecimals, decimals);

    tokensSold = tokensSold.add(tokenAmount);

    // Ensure new token increment does not exceed the sale amount
    assert(tokensSold <= saleAmount);

    mint(_beneficiary, tokenAmount);
    TokenPurchase(msg.sender, _beneficiary, msg.value, tokenAmount);

    forwardFunds();
  }

  /// @notice Allows contract owner to mint tokens at any time
  /// @param _amount Amount of tokens to mint in lowest denomination of VEVUE
  function mintReservedTokens(uint256 _amount) public onlyOwner {
    uint256 checkedSupply = totalSupply.add(_amount);
    require(checkedSupply <= tokenTotalSupply);

    mint(owner, _amount);
  }

  /// @notice Shows the amount of Vevue the user will receive for amount of exchanged chong
  /// @param _Amount Exchanged chong amount to convert
  /// @param _exchangeRate Number of Vevue per exchange token
  /// @param _nativeDecimals Number of decimals of the token being exchange for Vevue
  /// @param _decimals Number of decimals of Vevue token
  /// @return The amount of Vevue that will be received
  function getTokenExchangeAmount(
    uint256 _Amount,
    uint256 _exchangeRate,
    uint256 _nativeDecimals,
    uint256 _decimals)
    public
    constant
    returns(uint256)
  {
    require(_Amount > 0);

    uint256 differenceFactor = (10**_nativeDecimals) / (10**_decimals);
    return _Amount.mul(_exchangeRate).div(differenceFactor);
  }

  /// @dev Sends Qtum to the contract owner
  function forwardFunds() internal {
    owner.transfer(msg.value);
  }

  /// @dev Mints new tokens
  /// @param _to Address to mint the tokens to
  /// @param _amount Amount of tokens that will be minted
  /// @return Boolean to signify successful minting
  function mint(address _to, uint256 _amount) internal returns (bool) {
    totalSupply += _amount;
    balances[_to] = balances[_to].add(_amount);
    Mint(totalSupply, _to, _amount);
    return true;
  }

  /// Emergency Stop ICO
  function halt() public onlyOwner {
    halted = true;
  }

  function unhalt() public onlyOwner {
    halted = false;
  }
}
