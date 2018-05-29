pragma solidity ^0.4.22;


contract Foo {
  function foo() public {
    require(0 == 1, "here be a revert message");
  }
}
