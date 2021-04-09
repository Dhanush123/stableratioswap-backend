//SPDX-License-Identifier: Unlicense
pragma solidity >=0.6.12;
pragma experimental ABIEncoderV2;

// HardHat Imports
import "hardhat/console.sol";
import "./IStableRatioSwap.sol";

import "@chainlink/contracts/src/v0.6/ChainlinkClient.sol";
import "@chainlink/contracts/src/v0.6/interfaces/AggregatorV3Interface.sol";

import {ILendingPool} from "@aave/protocol-v2/contracts/interfaces/ILendingPool.sol";
import {ILendingPoolAddressesProvider} from "@aave/protocol-v2/contracts/interfaces/ILendingPoolAddressesProvider.sol";
import {AaveProtocolDataProvider} from "@aave/protocol-v2/contracts/misc/AaveProtocolDataProvider.sol";
// import {IFlashLoanReceiver} from "@aave/protocol-v2/contracts/flashloan/interfaces/IFlashLoanReceiver.sol";
// import {UniswapliquiditySwapAdapter} from "@aave/protocol-v2/contracts/adapters/UniswapliquiditySwapAdapter.sol";

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {SafeMath} from "@openzeppelin/contracts/math/SafeMath.sol";
import {Address} from "@openzeppelin/contracts/utils/Address.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";

contract StableRatioSwap is IStableRatioSwap, ChainlinkClient, Ownable {

  using SafeMath for uint;
  using Address for address;

  // Constant variables for Chainlink external adaptor
  bytes32 private constant jobID = "35e14dbd490f4e3b9fbe92b85b32d98a";
  address private constant oracle = 0xFC153f49E74711C3140CA06bFAcf42FfDC492A17;
  uint private constant fee = 0.01 * 1 ether;

  // These addresses are for Kovan
  address private constant kovan_tusd = 0x016750AC630F711882812f24Dba6c95b9D35856d;
  address private constant kovan_usdc = 0xe22da380ee6B445bb8273C81944ADEB6E8450422;
  address private constant kovan_usdt = 0x13512979ADE267AB5100878E2e0f485B568328a4;
  address private constant kovan_dai = 0xFf795577d9AC8bD7D90Ee22b6C1703490b6512FD;
  address private constant kovan_busd = 0x4c6E1EFC12FDfD568186b7BAEc0A43fFfb4bCcCf;
  address constant lendingPoolAddressesProviderAddr = 0x88757f2f99175387aB4C6a4b3067c77A695b0349;
  address constant aaveProtocolDataProviderAddr = 0x3c73A5E5785cAC854D468F727c606C07488a29D6;
  AaveProtocolDataProvider protocolDataProvider;
  address poolAddr;

  uint ratio;
  uint flashedTUSDAmt;
  address flashedUserAddress;

  address[] private userAddresses;
  mapping(address => User) private userData;
  mapping(string => address) stableCoinAddresses;
  mapping(string => bool) stablecoinList;

  ILendingPoolAddressesProvider public ADDRESSES_PROVIDER;
  ILendingPool public LENDING_POOL;
  
  struct User {
    address userAddress;
    bool optInStatus;
    bool forceSwap;
  }

  constructor() public {
    setPublicChainlinkToken();
    protocolDataProvider = AaveProtocolDataProvider(aaveProtocolDataProviderAddr);
    ADDRESSES_PROVIDER  = ILendingPoolAddressesProvider(lendingPoolAddressesProviderAddr);
    poolAddr = ADDRESSES_PROVIDER.getLendingPool();
    LENDING_POOL = ILendingPool(poolAddr);
    
    stableCoinAddresses["TUSD"] = kovan_tusd;
    stableCoinAddresses["USDC"] = kovan_usdc;
    stableCoinAddresses["USDT"] = kovan_usdt;
    stableCoinAddresses["DAI"] = kovan_dai;
    stableCoinAddresses["BUSD"] = kovan_busd;

    stablecoinList["TUSD"] = true;
    stablecoinList["USDC"] = true;
    stablecoinList["USDT"] = true;
    stablecoinList["DAI"] = true;
    stablecoinList["BUSD"] = true;
  }

  function deposit(uint amount, string memory tokenType, address sender) public override {
    // String check
    require(stablecoinList[tokenType]);
    address token = stableCoinAddresses[tokenType];
    // Check if the LendingPool contract have at least an allowance() of amount for the asset being deposited
    require(IERC20(token).approve(poolAddr, amount));
    
    LENDING_POOL.deposit(token, amount, sender, 0);
  }

  function createUser() external override {
    if (userData[msg.sender].userAddress == address(0)) {
      userData[msg.sender].userAddress = msg.sender;
      userData[msg.sender].optInStatus = true;
      userData[msg.sender].forceSwap = false;
      userAddresses.push(msg.sender);
      emit CreateUser(true);
    } else {
      emit CreateUser(false);
    }
  }

  function getAllUsers() internal view returns (address[] memory) {
    return userAddresses;
  }

  function getAllStablecoinDeposits() external override {
    (uint tusd, uint decimalsTusd) = _getCurrentDepositData(msg.sender, "TUSD");
    (uint usdc, uint decimalsUsdc) = _getCurrentDepositData(msg.sender, "USDC");
    (uint usdt, uint decimalsUsdt) = _getCurrentDepositData(msg.sender, "USDT");
    (uint dai, uint decimalsDai) = _getCurrentDepositData(msg.sender, "DAI");
    (uint busd, uint decimalsBusd) = _getCurrentDepositData(msg.sender, "BUSD");
    emit AllDeposits(tusd, decimalsTusd, usdc, decimalsUsdc, usdt, decimalsUsdt, dai, decimalsDai, busd, decimalsBusd);
  }

  function _getCurrentDepositData(address userAddress, string memory tokenType) internal view returns (uint, uint) {
    // Helper for getAllStablecoinDeposits()
    // Whether userAddress exists is handled by functions that call this function.
    require(stablecoinList[tokenType]);
    address token = stableCoinAddresses[tokenType];
    (uint currentBalance,,,,,,,,) = protocolDataProvider.getUserReserveData(token, userAddress);
    (uint decimals,,,,,,,,,) = protocolDataProvider.getReserveConfigurationData(token);
    return (currentBalance, decimals);
  }

  function _getHighestAPYStablecoinAlt() internal view returns (string memory, uint) {
    uint maxLiquidityRate = 0;
    uint currentLiquidityRate;
    string memory tokenType = "TUSD";
    (,,,currentLiquidityRate,,,,,,) = protocolDataProvider.getReserveData(stableCoinAddresses["TUSD"]);
    maxLiquidityRate = max(maxLiquidityRate, currentLiquidityRate);
    (,,,currentLiquidityRate,,,,,,) = protocolDataProvider.getReserveData(stableCoinAddresses["USDC"]);
    maxLiquidityRate = max(maxLiquidityRate, currentLiquidityRate);
    if (maxLiquidityRate == currentLiquidityRate) {
      tokenType = "USDC";
    }
    (,,,currentLiquidityRate,,,,,,) = protocolDataProvider.getReserveData(stableCoinAddresses["USDT"]);
    maxLiquidityRate = max(maxLiquidityRate, currentLiquidityRate);
    if (maxLiquidityRate == currentLiquidityRate) {
      tokenType = "USDT";
    }
    (,,,currentLiquidityRate,,,,,,) = protocolDataProvider.getReserveData(stableCoinAddresses["DAI"]);
    maxLiquidityRate = max(maxLiquidityRate, currentLiquidityRate);
    if (maxLiquidityRate == currentLiquidityRate) {
      tokenType = "DAI";
    }
    (,,,currentLiquidityRate,,,,,,) = protocolDataProvider.getReserveData(stableCoinAddresses["BUSD"]);
    maxLiquidityRate = max(maxLiquidityRate, currentLiquidityRate);
    if (maxLiquidityRate == currentLiquidityRate) {
      tokenType = "BUSD";
    }
    return (tokenType, maxLiquidityRate);
  }

  function max(uint a, uint b) private pure returns (uint) {
    return a > b ? a : b;
  }

  function optInToggle() external override {
    userData[msg.sender].optInStatus = !userData[msg.sender].optInStatus;
    emit OptInToggle(userData[msg.sender].optInStatus);
  }

  /**
    This function is called after your contract has received the flash loaned amount
  */
  /** 
  function executeOperation(
      address[] calldata assets,
      uint[] calldata amounts,
      uint[] calldata premiums,
      address initiator,
      bytes calldata params
  )
      external
      override
      returns (bool)
  {

      //
      // This contract now has the funds requested.
      // Your logic goes here.
      //
      require(msg.sender == address(LENDING_POOL), 'CALLER_MUST_BE_LENDING_POOL');

      (string memory tokenType, uint liquidityRate) = _getHighestAPYStablecoinAlt();
      uint amountOwing = flashedTUSDAmt.add(premiums[0]);
      LENDING_POOL.withdraw(kovan_tusd, flashedTUSDAmt, flashedUserAddress);
      IERC20(stableCoinAddresses[tokenType]).approve(address(LENDING_POOL), amountOwing);
      LENDING_POOL.deposit(stableCoinAddresses[tokenType], amountOwing, flashedUserAddress, uint16(0));
      
      // At the end of your logic above, this contract owes
      // the flashloaned amounts + premiums.
      // Therefore ensure your contract has enough to repay
      // these amounts.
      
      // Approve the LendingPool contract allowance to *pull* the owed amount
      for (uint i = 0; i < assets.length; i++) {
          // uint amountOwing = amounts[i].add(premiums[i]);
          IERC20(assets[i]).approve(address(LENDING_POOL), amountOwing);
      }
      emit SwapStablecoinDeposit(true, ratio);
      return true;
  }
  */

  function swapStablecoinDeposit(bool force) external override {
    userData[msg.sender].forceSwap = true;
    requestTUSDRatio();
  }

  function requestTUSDRatio() internal {
    Chainlink.Request memory req = buildChainlinkRequest(jobID, address(this), this.getTUSDRatio.selector);
    sendChainlinkRequestTo(oracle, req, fee);
  }

  function getTUSDRatio(bytes32 _requestID, uint _ratio) public recordChainlinkFulfillment(_requestID) {
    ratio = _ratio;

    // 0 = no debt, 1 = stable, 2 = variable
    uint[] memory modes = new uint[](1);
    modes[0] = 0;

    // the assets to be flashed
    address[] memory assets = new address[](1);
    assets[0] = stableCoinAddresses["TUSD"];

    for(uint i; i < userAddresses.length; i++) {
      if (userData[userAddresses[i]].optInStatus) {
        // the amount to be flashed for each asset
        uint[] memory amounts = new uint[](1);
        (amounts[0],) = _getCurrentDepositData(userAddresses[i], "TUSD");

        if (amounts[0] == 0) {
          emit SwapStablecoinDeposit(false, ratio);
          continue;
        }

        if (ratio > 10000 || userData[msg.sender].forceSwap) {
          // address onBehalfOf = userAddresses[i];
          (string memory tokenType, uint liquidityRate) = _getHighestAPYStablecoinAlt();
          flashedTUSDAmt = amounts[0];
          flashedUserAddress = userAddresses[i];
          LENDING_POOL.withdraw(kovan_tusd, flashedTUSDAmt, flashedUserAddress);
          IERC20(stableCoinAddresses[tokenType]).approve(address(LENDING_POOL), flashedTUSDAmt);
          LENDING_POOL.deposit(stableCoinAddresses[tokenType], flashedTUSDAmt, flashedUserAddress, uint16(0));

          // LENDING_POOL.flashLoan(address(this), assets, amounts, modes, address(this), "", 0);
          emit SwapStablecoinDeposit(true, ratio);
        } else {
          emit SwapStablecoinDeposit(false, ratio);
        }
      }
    }
  }

  receive() external payable {}

}
