//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import "hardhat/console.sol";

contract StableRatioSwap {

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
    //_createUser(msg.sender, _deposit);
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

  function _getCurrentDepositData() internal view returns (uint256) {
    return userData[msg.sender].deposit;
  }

  function _getHighestAPYStablecoinAlt() internal {

  }

  function optToggle() public {
    userData[msg.sender].flag = !userData[msg.sender].flag;
  }

  function swapStablecoinDeposit() internal onlyOwner {

  }

}