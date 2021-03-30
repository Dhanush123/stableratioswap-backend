//SPDX-License-Identifier: Unlicense
pragma solidity >=0.6.12;
pragma experimental ABIEncoderV2;

import "hardhat/console.sol";
import {ILendingPool} from "@aave/protocol-v2/contracts/interfaces/ILendingPool.sol";
import {ILendingPoolAddressesProvider} from '@aave/protocol-v2/contracts/interfaces/ILendingPoolAddressesProvider.sol';
import {AaveProtocolDataProvider} from "@aave/protocol-v2/contracts/misc/AaveProtocolDataProvider.sol";

contract StableRatioSwap {

  address public owner;
  address[] public userAddresses;
  mapping(address => User) userData;

  struct User {
    address userAddress;
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

  function deposit(address userAddress, uint256 amount) public {
    //temporary addresses to make file compile, replace later @Hide
    address pool = address(bytes20(sha256(abi.encodePacked(msg.sender,'block.timestamp'))));
    address token = address(bytes20(sha256(abi.encodePacked(msg.sender,'block.timestamp'))));
    ILendingPool(pool).deposit(token, amount, userAddress, 0);
  }

  function createUser(address _userAddress, uint256 amount) public {
    if (userData[msg.sender].userAddress != address(0)) {
      userData[msg.sender].userAddress = _userAddress;
      userData[msg.sender].deposit = amount;
      userData[msg.sender].flag = false;
      userAddresses.push(msg.sender);
    }
    deposit(_userAddress, amount);
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