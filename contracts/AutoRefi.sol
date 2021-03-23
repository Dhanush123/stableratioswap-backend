//SPDX-License-Identifier: Unlicense
pragma solidity ^0.7.0;

import "hardhat/console.sol";

contract AutoRefi {

  address public owner;
  address[] public userAddresses;
  mapping(address => User) loanData;

  struct User {
    address owner;
    uint256 loan;
  }

  modifier onlyOwner {
    if (msg.sender == owner) {
       _;
    }
  }

  constructor(uint256 loan) {
    createUser(msg.sender, loan);
    owner = msg.sender;
  }

  function createUser(address _owner, uint256 _loan) internal {
    loanData[msg.sender].owner = _owner;
    loanData[msg.sender].loan = _loan;
    userAddresses.push(msg.sender);
  }

  function getAllUsers() external view returns (address[] memory) {
    return userAddresses;
  }

  function getCurrentLoanData() internal returns (uint256) {

  }

  function getLowestRateLoan() internal returns (uint256) {

  }

  function optToggle() public onlyOwner returns (bool) {

  }

  function refinance() public onlyOwner returns (bool) {

  }

}