//SPDX-License-Identifier: Unlicense
pragma solidity ^0.7.0;

import "hardhat/console.sol";

contract User {
  address owner;

  modifier onlyOwner {
    if (msg.sender == owner) {
       _;
    }
  }

  constructor() {
    owner = msg.sender;
  }

  function getCurrentLoanData() internal returns (uint) {

  }

  function getLowestRateLoan() internal returns (uint) {

  }

  function optToggle() public onlyOwner returns (bool) {

  }

  function refinance() public onlyOwner returns (bool) {

  }

}