//SPDX-License-Identifier: Unlicense
pragma solidity >=0.6.12;
pragma experimental ABIEncoderV2;

import "hardhat/console.sol";
import {ILendingPool} from "@aave/protocol-v2/contracts/interfaces/ILendingPool.sol";
import {ILendingPoolAddressesProvider} from '@aave/protocol-v2/contracts/interfaces/ILendingPoolAddressesProvider.sol';
import {AaveProtocolDataProvider} from "@aave/protocol-v2/contracts/misc/AaveProtocolDataProvider.sol";
import "@openzeppelin/contracts/math/SafeMath.sol";

contract StableRatioSwap {

  using SafeMath for uint256;

  address public owner;
  address[] public userAddresses;
  mapping(address => User) userData;
  TokenData[] allTokenData = AaveProtocolDataProvider().getAllATokens();

  struct User {
    address userAddress;
    uint256 deposit;
    bool flag;
  }

  modifier onlyOwner {
    require (msg.sender == owner);
    _;
  }

  event Deposit(
    uint256 tusd,
    uint256 usdc,
    uint256 usdt,
    uint256 dai,
    uint256 busd
  );

  constructor() public {
    owner = msg.sender;
  }

  function deposit(address userAddress, uint256 amount) public {
    // temporary addresses to make file compile, replace later @Hide
    address pool = address(bytes20(sha256(abi.encodePacked(msg.sender,'block.timestamp'))));
    address token = address(bytes20(sha256(abi.encodePacked(msg.sender,'block.timestamp'))));
    // ILendingPool(pool).deposit(token, amount, userAddress, 0);
    emit Deposit(1,2,3,4,5);
  }

  function createUser(address _userAddress, uint256 amount) public {
    require (userData[msg.sender].userAddress == address(0));
    userData[msg.sender].userAddress = _userAddress;
    userData[msg.sender].deposit = amount;
    userData[msg.sender].flag = false;
    userAddresses.push(msg.sender);
  }

  function getAllUsers() external view returns (address[] memory) {
    return userAddresses;
  }

  function getAllStablecoinDeposits() public {

  }

  function _getCurrentDepositData() internal view returns (uint256) {
    AaveProtocolDataProvider().getUserReserveData(asset, msg.sender);
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