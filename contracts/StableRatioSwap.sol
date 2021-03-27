//SPDX-License-Identifier: Unlicense
pragma solidity >=0.6.12;
pragma experimental ABIEncoderV2;

import "hardhat/console.sol";
import {ILendingPool} from "@aave/protocol-v2/contracts/interfaces/ILendingPool.sol";
import {ILendingPoolAddressesProvider} from '@aave/protocol-v2/contracts/interfaces/ILendingPoolAddressesProvider.sol';

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

  constructor() public {
    // createUser(msg.sender, _deposit);
    owner = msg.sender;
  }

  function deposit(address pool, address token, address user, uint256 amount) public {
    ILendingPool(pool).deposit(token, amount, user, 0);
  }

  function createUser(address pool, address token, address _owner, uint256 amount) public {
    userData[msg.sender].owner = _owner;
    userData[msg.sender].deposit = amount;
    userData[msg.sender].flag = false;
    userAddresses.push(msg.sender);
    deposit(pool, token, _owner, amount);
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