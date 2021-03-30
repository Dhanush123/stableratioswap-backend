//SPDX-License-Identifier: Unlicense
pragma solidity >=0.6.12;
pragma experimental ABIEncoderV2;

import "hardhat/console.sol";
import {ILendingPool} from "@aave/protocol-v2/contracts/interfaces/ILendingPool.sol";
import {ILendingPoolAddressesProvider} from '@aave/protocol-v2/contracts/interfaces/ILendingPoolAddressesProvider.sol';
import {AaveProtocolDataProvider} from "@aave/protocol-v2/contracts/misc/AaveProtocolDataProvider.sol";
import "@openzeppelin/contracts/math/SafeMath.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract StableRatioSwap {

  using SafeMath for uint256;

  address public owner;
  address[] public userAddresses;
  mapping(address => User) userData;
  mapping(string => address) stableCoinAddresses;
  address pooladdr;
  ILendingPool pool;

  TokenData[] allTokenData = AaveProtocolDataProvider().getAllATokens();
  
  struct User {
    address userAddress;
    bool flag;
  }

  modifier onlyOwner {
    require(msg.sender == owner);
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
    pooladdr = ILendingPoolAddressesProvider().getLendingPool();
    pool = ILendingPool(pooladdr);
    for (i = 0; i < allTokenData.length; i++) {
      TokenData token = allTokenData[0];
      string tokenSym = token.symbol;
      address addr = token.tokenAddress;
      stableCoinAddresses[tokenSym] = addr;
    }
  }

  function deposit(uint256 amount, string tokenType) public {
    // Check if the LendingPool contract have at least an allowance() of amount for the asset being deposited
    require(IERC20().approve(pool, amount));

    address token = stableCoinAddresses[tokenType];
    pool.deposit(token, amount, msg.sender, 0);

    if (keccak256(abi.encodePacked(tokenType)) == keccak256(abi.encodePacked("tusd"))) {
      emit Deposit(amount, 0, 0, 0, 0);
    } else if (keccak256(abi.encodePacked(tokenType)) == keccak256(abi.encodePacked("usdc"))) {
      emit Deposit(0, amount, 0, 0, 0);
    } else if (keccak256(abi.encodePacked(tokenType)) == keccak256(abi.encodePacked("usdt"))) {
      emit Deposit(0, 0, amount, 0, 0);
    } else if (keccak256(abi.encodePacked(tokenType)) == keccak256(abi.encodePacked("dai"))) {
      emit Deposit(0, 0, 0, amount, 0);
    } else if (keccak256(abi.encodePacked(tokenType)) == keccak256(abi.encodePacked("busd"))) {
      emit Deposit(0, 0, 0, 0, amount);
    } 
  }

  function createUser(address _userAddress) public {
    require(userData[msg.sender].userAddress == address(0));
    userData[msg.sender].userAddress = _userAddress;
    userData[msg.sender].flag = false;
    userAddresses.push(msg.sender);
  }

  function getAllUsers() external view returns (address[] memory) {
    return userAddresses;
  }

  function getAllStablecoinDeposits() public {
    uint256 tusd = _getCurrentDepositData("tusd");
    uint256 usdc = _getCurrentDepositData("usdc");
    uint256 usdt = _getCurrentDepositData("usdt");
    uint256 dai = _getCurrentDepositData("dai");
    uint256 busd = _getCurrentDepositData("busd");
    emit Deposit(tusd, usdc, usdt, dai, busd);
  }

  function _getCurrentDepositData(string tokenType) internal view returns (uint256) {
    // Helper for getAllStablecoinDeposits()
    address token = stableCoinAddresses[tokenType];
    uint256 currentBalance;
    (currentBalance,,,,,,,,) = AaveProtocolDataProvider().getUserReserveData(token, msg.sender);
    return currentBalance;
  }

  function _getHighestAPYStablecoinAlt() internal {

  }

  function optToggle() public {
    userData[msg.sender].flag = !userData[msg.sender].flag;
  }

  function swapStablecoinDeposit() internal onlyOwner {

  }

}