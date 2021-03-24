//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import "hardhat/console.sol";

contract MockStableRatioSwap {

  address public owner;
  address[] public userAddresses;
  mapping(address => User) userData;

  struct User {
    address owner;
    uint256 deposit;
    bool flag;
  }

  modifier onlyOwner {
    if (msg.sender == owner) {
       _;
    }
  }

  constructor() {
    owner = msg.sender;
  }

  function createUser(address _owner, uint256 _deposit) public {
    userData[msg.sender].owner = _owner;
    userData[msg.sender].deposit = _deposit;
    userData[msg.sender].flag = false;
    userAddresses.push(msg.sender);
  }

  function getAllUsers() external view returns (address[] memory) {
    return userAddresses;
  }

  function getAllStablecoinDeposits() public {

  }

  function _getCurrentDepositData() internal {

  }

  function _getHighestAPYStablecoinAlt() internal {

  }

  function optToggle() public {
    
  }

  function swapStablecoinDeposit() internal onlyOwner {

  }

}