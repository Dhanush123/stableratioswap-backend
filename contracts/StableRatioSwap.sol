//SPDX-License-Identifier: Unlicense
pragma solidity >=0.6.12;
pragma experimental ABIEncoderV2;

import "./IStableRatioSwap.sol";
// import "./IUniswapV2Router02.sol";
// import "./UniswapLiquiditySwapProvider.sol";

import "@chainlink/contracts/src/v0.6/ChainlinkClient.sol";
import "@chainlink/contracts/src/v0.6/interfaces/AggregatorV3Interface.sol";

import {ILendingPool} from "@aave/protocol-v2/contracts/interfaces/ILendingPool.sol";
import {ILendingPoolAddressesProvider} from "@aave/protocol-v2/contracts/interfaces/ILendingPoolAddressesProvider.sol";
import {AaveProtocolDataProvider} from "@aave/protocol-v2/contracts/misc/AaveProtocolDataProvider.sol";
// import {IFlashLoanReceiver} from "@aave/protocol-v2/contracts/flashloan/interfaces/IFlashLoanReceiver.sol";
// import {UniswapLiquiditySwapAdapter} from "@aave/protocol-v2/contracts/adapters/UniswapLiquiditySwapAdapter.sol";

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {SafeMath} from "@openzeppelin/contracts/math/SafeMath.sol";
import {Address} from "@openzeppelin/contracts/utils/Address.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";

// contract StableRatioSwap is IStableRatioSwap, ChainlinkClient, IFlashLoanReceiver, Ownable {
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
  address private constant kovan_weth = 0xd0A1E359811322d97991E03f863a0C30C2cF029C;
  address constant lendingPoolAddressesProviderAddr = 0x88757f2f99175387aB4C6a4b3067c77A695b0349;
  address constant aaveProtocolDataProviderAddr = 0x3c73A5E5785cAC854D468F727c606C07488a29D6;
  address constant uniswapLiquiditySwapAdapterAddress = 0xC18451d36aA370fDACe8d45839bF975F48f7AEa1;
  AaveProtocolDataProvider protocolDataProvider;
  address poolAddr;

  uint ratio;
  uint flashedTUSDAmt;
  uint deadline;
  address swappingUserAddress;
  address latestTokenToSwapTo;

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

  struct PermitSignature {
    uint256[] amount;
    uint256[] deadline;
    uint8[] v;
    bytes32[] r;
    bytes32[] s;
  }

  // address constant uniswapRouterAddress = 0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D;
  // IUniswapV2Router02 private uniswapRouter;
  // address constant uniswapV2Router02Address = 0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D;
  // IUniswapV2Router02 uniswapV2Router02;
  // UniswapLiquiditySwapAdapter uniswapLiquiditySwapAdapter;

  constructor() public {
    setPublicChainlinkToken();
    protocolDataProvider = AaveProtocolDataProvider(aaveProtocolDataProviderAddr);
    ADDRESSES_PROVIDER = ILendingPoolAddressesProvider(lendingPoolAddressesProviderAddr);
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

    // uniswapRouter = IUniswapV2Router02(uniswapRouterAddress);
    // uniswapLiquiditySwapAdapter = UniswapLiquiditySwapAdapter(uniswapLiquiditySwapAdapterAddress);
    // uniswapV2Router02 = UniswapV2Router02(uniswapV2Router02Address);
    // uniswapV2Router02 = IUniswapV2Router02(uniswapV2Router02Address);
    // deadline = block.timestamp+150;
  }

  function deposit(uint amount, address tokenAddress, address sender) internal {
    // Check if the LendingPool contract have at least an allowance() of amount for the asset being deposited
    require(IERC20(tokenAddress).approve(poolAddr, amount));
    LENDING_POOL.deposit(tokenAddress, amount, sender, 0);
  }

  function createUser() external override {
    if (userData[msg.sender].userAddress == address(0)) {
      userData[msg.sender].userAddress = msg.sender;
      userData[msg.sender].optInStatus = true;
      // userData[msg.sender].forceSwap = false;
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
    string memory tokenType;
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

  function swapStablecoinDeposit(bool force) external override {
    swappingUserAddress = msg.sender; 
    userData[swappingUserAddress].forceSwap = force;
    requestTUSDRatio();
  }

  function requestTUSDRatio() internal {
    Chainlink.Request memory req = buildChainlinkRequest(jobID, address(this), this.getTUSDRatio.selector);
    sendChainlinkRequestTo(oracle, req, fee);
  }

  function getTUSDRatio(bytes32 _requestID, uint _ratio) public recordChainlinkFulfillment(_requestID) {
    ratio = _ratio;
    coreSwapping();
  }

  function coreSwapping() public {
    (uint userAmount, uint decimals) = _getCurrentDepositData(swappingUserAddress, "TUSD");
    (string memory swapToTokenName,) = _getHighestAPYStablecoinAlt();
    address swapToTokenAddress = stableCoinAddresses[swapToTokenName];
    bool meetCondition = ratio > 10000 || userData[swappingUserAddress].forceSwap == true;
    emit SwapStablecoinDeposit(meetCondition, ratio, userAmount, decimals, swapToTokenAddress, swapToTokenName);
  }

  receive() external payable {}
  
  // function coreSwapping() internal {
  //   // emit SwapStablecoinDeposit(false, 2);
  //   address[] memory assetToSwapFromList = new address[](1);
  //   assetToSwapFromList[0] = kovan_weth; //stableCoinAddresses["TUSD"];

  //   (string memory tokenType,) = _getHighestAPYStablecoinAlt();
  //   latestTokenToSwapTo = stableCoinAddresses[tokenType];
  //   // emit SwapStablecoinDeposit(false, 3);

  //   address[] memory assetToSwapToList = new address[](1);
  //   assetToSwapToList[0] = latestTokenToSwapTo;

  //   uint[] memory minAmountsToReceive = new uint[](1);
  //   minAmountsToReceive[0] = 0;

  //   uint userAmount;
  //   (userAmount,) = _getCurrentDepositData(swappingUserAddress, "WETH");
  //   // uint deadline = block.timestamp + 100;
  //   uint amountToSwap = userAmount/uint(2);
  //   // emit SwapStablecoinDeposit(false, 4);

  //   BaseUniswapAdapter.PermitSignature[] memory permitParams = new BaseUniswapAdapter.PermitSignature[](1);
  //   permitParams[0] = BaseUniswapAdapter.PermitSignature(userAmount,deadline,0,0x0000000000000000000000000000000000000000000000000000000000000000,0x0000000000000000000000000000000000000000000000000000000000000000);
  //   // emit SwapStablecoinDeposit(false, 5);

  //   uint[] memory amountToSwapList = new uint[](1);
  //   amountToSwapList[0] = amountToSwap;
  //   // require(IERC20(assetToSwapFromList[0]).approve(poolAddr, amountToSwapList[0]));
  //   // emit SwapStablecoinDeposit(false, 6);
  //   IERC20(assetToSwapFromList[0]).allowance(swappingUserAddress,uniswapLiquiditySwapAdapterAddress);
  //   // emit SwapStablecoinDeposit(false, 7);
  //   uniswapLiquiditySwapAdapter.swapAndDeposit(assetToSwapFromList, assetToSwapToList, amountToSwapList, minAmountsToReceive, permitParams);
  //   emit SwapStablecoinDeposit(true, ratio, address(this), 0, 0);
  // }
  
    // function executeOperation(
    //   address[] calldata assets,
    //   uint256[] calldata amounts,
    //   uint256[] calldata premiums,
    //   address initiator,
    //   bytes calldata params
    // )
    //   external
    //   override
    //   returns (bool)
    // {   
    //     // 1) Aave gives SRS TUSD
    //     uint256 loanAmount = amounts[0];
    //     emit SwapStablecoinDeposit(true, 6);
    //     uniswapSwap(loanAmount);
    //     emit SwapStablecoinDeposit(true, 7);

    //     // 4) SRS repays Aave TUSD + fee
    //     for (uint i = 0; i < assets.length; i++) {
    //       uint amountOwing = amounts[i].add(premiums[i]);
    //       // Approve SRS to pull amountOwing
    //       IERC20(assets[i]).approve(address(this), amountOwing);
    //       // move amountOwing from Aave to SRS
    //       LENDING_POOL.withdraw(assets[i],amountOwing,address(this));
    //       // Approve the LendingPool contract allowance to *pull* the owed amount from SRS
    //       IERC20(assets[i]).approve(address(LENDING_POOL), amountOwing);
    //     }
    //     emit SwapStablecoinDeposit(true, 8);
    //     return true;
    // }
    
  // function uniswapSwap(uint256 amountWantSwap) public payable {   
  //   emit SwapStablecoinDeposit(true, 9);
  //   uint amountOut = amountWantSwap;
  //   uint amountInMax = amountWantSwap;
  //   require(IERC20(kovan_tusd).approve(address(uniswapV2Router02), amountInMax), 'approve failed.');
  //   emit SwapStablecoinDeposit(true, 11);

  //   address[] memory path = new address[](2);
  //   path[0] = kovan_tusd;
  //   path[1] = latestTokenToSwapTo;
  //   emit SwapStablecoinDeposit(true, 12);
  //   address recipient = address(this);
  //   emit SwapStablecoinDeposit(true, 13);
  //   // 2) Uniswap swap TUSD -> other coin (OC) and returns OC to SRS
  //   uint[] memory swappedAmount = uniswapV2Router02.swapTokensForExactTokens(amountOut, amountInMax, path, recipient, deadline);
  //   emit SwapStablecoinDeposit(false, 14);
  //   // 3) SRS deposits OC to Aave on user's behalf
  //   deposit(swappedAmount[1],latestTokenToSwapTo,swappingUserAddress);
  // }
}
