//SPDX-License-Identifier: Unlicense
pragma solidity >=0.6.12;

import "hardhat/console.sol";
import "@openzeppelin/contracts/math/SafeMath.sol";

contract MockStableRatioSwap {

  using SafeMath for uint256;

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
    owner = msg.sender;
  }

  function deposit(address userAddress, uint256 amount) public {
    address pool = address(bytes20(sha256(abi.encodePacked(msg.sender,'block.timestamp'))));
    address token = address(bytes20(sha256(abi.encodePacked(msg.sender,'block.timestamp'))));
  }

  function createUser(address _userAddress, uint256 amount) public {
    if (userData[msg.sender].userAddress != address(0)) {
      userData[msg.sender].userAddress = _userAddress;
      userData[msg.sender].deposit = amount;
      userData[msg.sender].flag = false;
      userAddresses.push(msg.sender);
    }
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