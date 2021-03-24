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
    bool flag;
  }

  modifier onlyOwner {
    if (msg.sender == owner) {
       _;
    }
  }

  constructor() {
    //_createUser(msg.sender, loan);
    owner = msg.sender;
  }

  function _createUser(address _owner, uint256 _loan) internal {
    loanData[msg.sender].owner = _owner;
    loanData[msg.sender].loan = _loan;
    loanData[msg.sender].flag = false;
    userAddresses.push(msg.sender);
  }

  function getAllUsers() external view returns (address[] memory) {
    return userAddresses;
  }

  function _getCurrentLoanData() internal returns (uint256) {

  }

  function _getLowestRateLoan() internal returns (uint256) {

  }

  function optToggle() public {
    loanData[msg.sender].flag = !loanData[msg.sender].flag;

  }

  function refinance() public onlyOwner returns (bool) {

  }

}