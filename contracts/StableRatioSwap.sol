//SPDX-License-Identifier: Unlicense
pragma solidity >=0.6.6;
pragma experimental ABIEncoderV2;

import "./IStableRatioSwap.sol";
import "./UniswapV2Router02.sol";
// import "./UniswapLiquiditySwapProvider.sol";

import "@chainlink/contracts/src/v0.6/ChainlinkClient.sol";
import "@chainlink/contracts/src/v0.6/interfaces/AggregatorV3Interface.sol";

// import {ILendingPool} from "@aave/protocol-v2/contracts/interfaces/ILendingPool.sol";
// import {ILendingPoolAddressesProvider} from "@aave/protocol-v2/contracts/interfaces/ILendingPoolAddressesProvider.sol";
import {AaveProtocolDataProvider} from "@aave/protocol-v2/contracts/misc/AaveProtocolDataProvider.sol";
// import {IFlashLoanReceiver} from "@aave/protocol-v2/contracts/flashloan/interfaces/IFlashLoanReceiver.sol";
// import {UniswapliquiditySwapAdapter} from "@aave/protocol-v2/contracts/adapters/UniswapliquiditySwapAdapter.sol";

// import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
// import {SafeMath} from "@openzeppelin/contracts/math/SafeMath.sol";
// import {Address} from "@openzeppelin/contracts/utils/Address.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";

// contract StableRatioSwap is IStableRatioSwap, ChainlinkClient, IFlashLoanReceiver, Ownable {
contract StableRatioSwap is IStableRatioSwap, ChainlinkClient, IFlashLoanReceiver, Ownable {

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
  address constant uniswapV2Router02Address = 0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D;
  UniswapV2Router02 uniswapV2Router02;
  // UniswapLiquiditySwapAdapter uniswapLiquiditySwapAdapter;

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

    // uniswapRouter = IUniswapV2Router02(uniswapRouterAddress);
    // uniswapLiquiditySwapAdapter = UniswapLiquiditySwapAdapter(uniswapLiquiditySwapAdapterAddress);
    uniswapV2Router02 = UniswapV2Router02(uniswapV2Router02Address);
  }

    function executeOperation(
    address[] calldata assets,
    uint256[] calldata amounts,
    uint256[] calldata premiums,
    address initiator,
    bytes calldata params
  ) override external returns (bool) {
    return true;
  }

  function deposit(uint amount, string memory tokenType, address sender) public override {
    // String check
    require(stablecoinList[tokenType]);
    // address token = stableCoinAddresses[tokenType];
    // // Check if the LendingPool contract have at least an allowance() of amount for the asset being deposited
    // require(IERC20(token).approve(poolAddr, amount));
    // LENDING_POOL.deposit(token, amount, sender, 0);
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

  function swapStablecoinDeposit(bool force) external override {
    userData[msg.sender].forceSwap = true;
    emit SwapStablecoinDeposit(true, 1);
    coreSwapping();
    // requestTUSDRatio();
  }

  function coreSwapping() internal {
    // the amount to be flashed for each asset
    uint[] memory userAmount = new uint[](1);
    (userAmount[0],) = _getCurrentDepositData(userAddresses[i], "TUSD");
    emit SwapStablecoinDeposit(true, 2);

    (string memory tokenType, uint liquidityRate) = _getHighestAPYStablecoinAlt();
    latestTokenToSwapTo = stableCoinAddresses[tokenType];
    emit SwapStablecoinDeposit(true, 3);

    address receiverAddress = address(this);
    address[] memory assets = new address[](1);
    assets[0] = stableCoinAddresses["TUSD"];

    address onBehalfOf = address(this);

    bytes memory params = "";
    uint16 referralCode = 0;
    uint256[] memory amounts = new uint256[](1);
    amounts[0] = userAmount[0];
    // 0 = no debt, 1 = stable, 2 = variable
    uint[] memory modes = new uint[](1);
    modes[0] = 0;

    swappingUserAddress = msg.sender;

    emit SwapStablecoinDeposit(false, 4);
    LENDING_POOL.flashLoan(
        receiverAddress,
        assets,
        amounts,
        modes,
        onBehalfOf,
        params,
        referralCode
    );
    emit SwapStablecoinDeposit(false, 5);
  }

    function executeOperation(
      address[] calldata assets,
      uint256[] calldata amounts,
      uint256[] calldata premiums,
      address initiator,
      bytes calldata params
    )
      external
      override
      returns (bool)
    {   
        // do something
        uint256 loanAmount = amounts[0];
        emit SwapStablecoinDeposit(true, 6);
        uniswapSwap(loanAmount-premiums[0]);
        emit SwapStablecoinDeposit(true, 7);

        // Approve the LendingPool contract allowance to *pull* the owed amount
        for (uint i = 0; i < assets.length; i++) {
          uint amountOwing = amounts[i].add(premiums[i]);
          IERC20(assets[i]).approve(address(LENDING_POOL), amountOwing);
        }
        
        emit SwapStablecoinDeposit(true, 8);
        return true;
    }
    
  function uniswapSwap(uint256 amount) public payable {   
    if(IERC20(latestTokenToSwapTo).approve(address(uniswapV2Router02), amount)) {
      emit SwapStablecoinDeposit(true, 9);
    } else {
      emit SwapStablecoinDeposit(false, 10);
    }
    
    address[] memory path = new address[](2);
    path[0] = kovan_tusd;
    path[1] = latestTokenToSwapTo;
    uint deadline = block.timestamp + 15;
    uint[] memory swappedAmount = uniswapRouter.swapExactTokensForTokens(amount,0, path, address(this), deadline);
    emit SwapStablecoinDeposit(false, 11);
    if (IERC20(latestTokenToSwapTo).approve(address(LENDING_POOL), swappedAmount[1])) {
      emit SwapStablecoinDeposit(true, 12);
    } else {
      emit SwapStablecoinDeposit(false, 13);
    }
    LENDING_POOL.deposit(latestTokenToSwapTo, swappedAmount[1], swappingUserAddress, uint16(0));
    emit SwapStablecoinDeposit(true, 14);
  }

  // function coreSwapping() internal {
  //   // use uniswap to swap current deposit
  //   address[] memory path = new address[](2);
  //   path[0] = kovan_tusd;
  //   path[1] = latestTokenToSwapTo;
  //   uint deadline = block.timestamp + 15;
  //   if(IERC20(latestTokenToSwapTo).approve(address(uniswapRouter), amount)) {
  //     emit SwapStablecoinDeposit(true, 1);
  //   } else {
  //     emit SwapStablecoinDeposit(false, 2);
  //   }
  //   uint[] memory swappedAmount = uniswapRouter.swapExactTokensForTokens(amount,0, path, address(this), deadline);

  //   // use Aave to deposit
  //   emit SwapStablecoinDeposit(false, 98);
  //   address[] memory assetToSwapFromList = new address[](1);
  //   assetToSwapFromList[0] = stableCoinAddresses["TUSD"];
  //   (string memory tokenType,) = _getHighestAPYStablecoinAlt();
  //   latestTokenToSwapTo = stableCoinAddresses[tokenType];
  //   address[] memory assetToSwapToList = new address[](1);
  //   assetToSwapToList[0] = latestTokenToSwapTo;
  //   uint[] memory amountToSwapList = new uint[](1);
  //   emit SwapStablecoinDeposit(false, 99);
  //   (amountToSwapList[0],) = _getCurrentDepositData(msg.sender, "TUSD");
  //   uint[] memory minAmountsToReceive = new uint[](1);
  //   minAmountsToReceive[0] = 0;
  //   uint8[] memory v = new uint8[](1);
  //   v[0] = 0;
  //   emit SwapStablecoinDeposit(false, 101);
  //   (uint userAmount,) = _getCurrentDepositData(msg.sender, "TUSD");
  //   uint deadline = block.timestamp + 15;
  //   emit SwapStablecoinDeposit(false, 102);
  //   BaseUniswapAdapter.PermitSignature[] memory permitParams = new BaseUniswapAdapter.PermitSignature[](1);
  //   permitParams[0] = BaseUniswapAdapter.PermitSignature(userAmount,deadline,0,0x0000000000000000000000000000000000000000000000000000000000000000,0x0000000000000000000000000000000000000000000000000000000000000000);
  //   emit SwapStablecoinDeposit(false, 103);

  //   require(IERC20(assetToSwapFromList[0]).approve(poolAddr, amountToSwapList[0]));
  //   emit SwapStablecoinDeposit(false, 104);
  //   uniswapLiquiditySwapAdapter.swapAndDeposit(assetToSwapFromList, assetToSwapToList, amountToSwapList, minAmountsToReceive, permitParams);
  //   emit SwapStablecoinDeposit(true, 105);
  // }
  
  // /**
  //   This function is called after the contract has received the flash loaned amount
  // */
  // function executeOperation(
  //     address[] calldata assets,
  //     uint256[] calldata amounts,
  //     uint256[] calldata premiums,
  //     address initiator,
  //     bytes calldata params
  //   )
  //     external
  //     override
  //     returns (bool)
  //   {   
  //       // do something
  //       uint256 loanAmount = amounts[0];
  //       uniswapSwap(loanAmount);
        
  //       // Approve the LendingPool contract allowance to *pull* the owed amount
  //       for (uint i = 0; i < assets.length; i++) {
  //           uint amountOwing = amounts[i].add(premiums[i]);
  //           IERC20(assets[i]).approve(address(LENDING_POOL), amountOwing);
  //       }
  //       emit SwapStablecoinDeposit(true, 106);
  //       return true;
  //   }

  // function requestTUSDRatio() internal {
  //   Chainlink.Request memory req = buildChainlinkRequest(jobID, address(this), this.getTUSDRatio.selector);
  //   sendChainlinkRequestTo(oracle, req, fee);
  // }

  // function getTUSDRatio(bytes32 _requestID, uint _ratio) public recordChainlinkFulfillment(_requestID) {
  //   ratio = _ratio;
  //   coreSwapping();
  // }

  // function coreSwapping() internal {
  //   // for(uint i; i < userAddresses.length; i++) {
  //   //   if (userData[userAddresses[i]].optInStatus) {
  //       // the amount to be flashed for each asset
  //       uint[] memory userAmount = new uint[](1);
  //       (userAmount[0],) = _getCurrentDepositData(userAddresses[i], "TUSD");

  //       // if (userAmount[0] == 0) {
  //       //   emit SwapStablecoinDeposit(false, ratio);
  //       //   continue;
  //       // }

  //       // if (ratio > 10000 || userData[userAddresses[i]].forceSwap) {
  //         // address onBehalfOf = userAddresses[i];
  //         (string memory tokenType, uint liquidityRate) = _getHighestAPYStablecoinAlt();
  //         latestTokenToSwapTo = stableCoinAddresses[tokenType];

  //         address receiverAddress = address(this);
  //         address[] memory assets = new address[](1);
  //         assets[0] = stableCoinAddresses["TUSD"];

  //         address onBehalfOf = address(this);

  //         bytes memory params = "";
  //         uint16 referralCode = 0;
  //         uint256[] memory amounts = new uint256[](1);
  //         amounts[0] = userAmount[0];
  //         // 0 = no debt, 1 = stable, 2 = variable
  //         uint[] memory modes = new uint[](1);
  //         modes[0] = 0;

  //         swappingUserAddress = msg.sender;

  //         emit SwapStablecoinDeposit(false, 98);
  //         LENDING_POOL.flashLoan(
  //             receiverAddress,
  //             assets,
  //             amounts,
  //             modes,
  //             onBehalfOf,
  //             params,
  //             referralCode
  //         );
  //         emit SwapStablecoinDeposit(false, 99);
  //       // } else {
  //       //   emit SwapStablecoinDeposit(false, ratio);
  //       // }
  //   //   }
  //   // }
  // }

  receive() external payable {}

}
