//SPDX-License-Identifier: Unlicense
pragma solidity >=0.6.12;
pragma experimental ABIEncoderV2;

// HardHat Imports
import "hardhat/console.sol";
import "@chainlink/contracts/src/v0.6/ChainlinkClient.sol";
import "@chainlink/contracts/src/v0.6/interfaces/AggregatorV3Interface.sol";
import {IFlashLoanReceiver} from "@aave/protocol-v2/contracts/flashloan/interfaces/IFlashLoanReceiver.sol";
import {ILendingPool} from "@aave/protocol-v2/contracts/interfaces/ILendingPool.sol";
import {ILendingPoolAddressesProvider} from "@aave/protocol-v2/contracts/interfaces/ILendingPoolAddressesProvider.sol";
import {AaveProtocolDataProvider} from "@aave/protocol-v2/contracts/misc/AaveProtocolDataProvider.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {SafeMath} from "@openzeppelin/contracts/math/SafeMath.sol";
import {Address} from "@openzeppelin/contracts/utils/Address.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";

contract StableRatioSwap is ChainlinkClient, IFlashLoanReceiver, Ownable {

  using SafeMath for uint256;
  using Address for address;

  // Constant variables for Chainlink external adaptor
  bytes32 private constant jobID = "35e14dbd490f4e3b9fbe92b85b32d98a";
  address private constant oracle = 0xFC153f49E74711C3140CA06bFAcf42FfDC492A17;
  uint256 private constant fee = 0.01 * 1 ether;

  // These addresses are for Kovan
  address constant lendingPoolAddressesProviderAddr = 0x88757f2f99175387aB4C6a4b3067c77A695b0349;
  address constant aaveProtocolDataProviderAddr = 0x3c73A5E5785cAC854D468F727c606C07488a29D6;
  AaveProtocolDataProvider protocolDataProvider;
  address poolAddr;
  // ILendingPool pool;

  uint256 ratio;
  // address constant nodeAddr;

  // address private owner;
  address[] private userAddresses;
  mapping(address => User) private userData;
  mapping(string => address) stableCoinAddresses;
  mapping(string => bool) stablecoinList;

  ILendingPoolAddressesProvider public override ADDRESSES_PROVIDER;
  ILendingPool public override LENDING_POOL;
  
  /*
  modifier onlyNode {
    require(msg.sender == nodeAddr, 'This function is only callable by a Node Adaptor');
    _;
  }
  */
  
  struct User {
    address userAddress;
    bool flag;
  }

  event Deposit(
    uint256 tusd,
    uint256 usdc,
    uint256 usdt,
    uint256 dai,
    uint256 busd
  );

  constructor() public {
    setPublicChainlinkToken();
    // owner = msg.sender;
    protocolDataProvider = AaveProtocolDataProvider(aaveProtocolDataProviderAddr);
    ADDRESSES_PROVIDER  = ILendingPoolAddressesProvider(lendingPoolAddressesProviderAddr);
    poolAddr = ADDRESSES_PROVIDER.getLendingPool();
    LENDING_POOL = ILendingPool(poolAddr);

    // Constructing hashmaps
    AaveProtocolDataProvider.TokenData[] memory allTokenData = protocolDataProvider.getAllATokens();
    for (uint i = 0; i < allTokenData.length; i++) {
      AaveProtocolDataProvider.TokenData memory token = allTokenData[i];
      string memory tokenSym = token.symbol;
      address addr = token.tokenAddress;
      stableCoinAddresses[tokenSym] = addr;
    }
    stablecoinList["TUSD"] = true;
    stablecoinList["USDC"] = true;
    stablecoinList["USDT"] = true;
    stablecoinList["DAI"] = true;
    stablecoinList["BUSD"] = true;
  }

  function deposit(uint256 amount, string memory tokenType) public {
    // String check
    require(stablecoinList[tokenType]);
    address token = stableCoinAddresses[tokenType];
    // Check if the LendingPool contract have at least an allowance() of amount for the asset being deposited
    require(IERC20(token).approve(poolAddr, amount));
    
    LENDING_POOL.deposit(token, amount, msg.sender, 0);

    if (keccak256(abi.encodePacked(tokenType)) == keccak256(abi.encodePacked("TUSD"))) {
      emit Deposit(amount, 0, 0, 0, 0);
    } else if (keccak256(abi.encodePacked(tokenType)) == keccak256(abi.encodePacked("USDC"))) {
      emit Deposit(0, amount, 0, 0, 0);
    } else if (keccak256(abi.encodePacked(tokenType)) == keccak256(abi.encodePacked("USDT"))) {
      emit Deposit(0, 0, amount, 0, 0);
    } else if (keccak256(abi.encodePacked(tokenType)) == keccak256(abi.encodePacked("DAI"))) {
      emit Deposit(0, 0, 0, amount, 0);
    } else if (keccak256(abi.encodePacked(tokenType)) == keccak256(abi.encodePacked("BUSD"))) {
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
    uint256 tusd = _getCurrentDepositData(msg.sender, "TUSD");
    uint256 usdc = _getCurrentDepositData(msg.sender, "USDC");
    uint256 usdt = _getCurrentDepositData(msg.sender, "USDT");
    uint256 dai = _getCurrentDepositData(msg.sender, "DAI");
    uint256 busd = _getCurrentDepositData(msg.sender, "BUSD");
    emit Deposit(tusd, usdc, usdt, dai, busd);
  }

  function _getAllStablecoinDeposits(address userAddress) internal view returns (uint256, uint256, uint256, uint256, uint256) {
    uint256 tusd = _getCurrentDepositData(userAddress, "TUSD");
    uint256 usdc = _getCurrentDepositData(userAddress, "USDC");
    uint256 usdt = _getCurrentDepositData(userAddress, "USDT");
    uint256 dai = _getCurrentDepositData(userAddress, "DAI");
    uint256 busd = _getCurrentDepositData(userAddress, "BUSD");
    return (tusd, usdc, usdt, dai, busd);
  }

  function _getCurrentDepositData(address userAddress, string memory tokenType) internal view returns (uint256) {
    // Helper for getAllStablecoinDeposits()
    address token = stableCoinAddresses[tokenType];
    uint256 currentBalance;
    (currentBalance,,,,,,,,) = protocolDataProvider.getUserReserveData(token, userAddress);
    return currentBalance;
  }

  function _getHighestAPYStablecoinAlt() internal view returns (string memory, uint256) {
    uint256 maxLiquidityRate = 0;
    uint256 currentLiquidityRate;
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

  function max(uint256 a, uint256 b) private pure returns (uint256) {
    return a > b ? a : b;
  }

  function optToggle() public {
    userData[msg.sender].flag = !userData[msg.sender].flag;
  }

  /**
    This function is called after your contract has received the flash loaned amount
  */
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

      //
      // This contract now has the funds requested.
      // Your logic goes here.
      //
      
      // At the end of your logic above, this contract owes
      // the flashloaned amounts + premiums.
      // Therefore ensure your contract has enough to repay
      // these amounts.
      
      // Approve the LendingPool contract allowance to *pull* the owed amount
      for (uint i = 0; i < assets.length; i++) {
          uint amountOwing = amounts[i].add(premiums[i]);
          IERC20(assets[i]).approve(address(LENDING_POOL), amountOwing);
      }
      
      return true;
  }

  function swapStablecoinDeposit() public {
    string memory tokenType;
    uint256 liquidityRate;
    (tokenType, liquidityRate) = _getHighestAPYStablecoinAlt();

    uint256[] memory modes = new uint256[](5);
    modes[0] = 1;
    modes[1] = 1;
    modes[2] = 1;
    modes[3] = 1;
    modes[4] = 1;
    
    for(uint i; i < userAddresses.length; i++) {
      uint256 tusd;
      uint256 usdc;
      uint256 usdt;
      uint256 dai;
      uint256 busd;
      (tusd, usdc, usdt, dai, busd) = _getAllStablecoinDeposits(userAddresses[i]);
      uint256[] memory amounts = new uint256[](5);
      amounts[0] = tusd;
      amounts[1] = usdc;
      amounts[2] = usdt;
      amounts[3] = dai;
      amounts[4] = busd;
      address[] memory assets = new address[](5);
      assets[0] = stableCoinAddresses["TUSD"];
      assets[1] = stableCoinAddresses["USDC"];
      assets[2] = stableCoinAddresses["USDT"];
      assets[3] = stableCoinAddresses["DAI"];
      assets[4] = stableCoinAddresses["BUSD"];
      bytes memory params = "";
      address onBehalfOf = userAddresses[i];
      LENDING_POOL.flashLoan(address(this), assets, amounts, modes, onBehalfOf, params, 0);
    }
  }

  function requestTUSDRatio() public {
    Chainlink.Request memory req = buildChainlinkRequest(jobID, address(this), this.getTUSDRatio.selector);
    sendChainlinkRequestTo(oracle, req, fee);
  }

  function getTUSDRatio(bytes32 _requestID, uint256 _ratio) public recordChainlinkFulfillment(_requestID) {
    ratio = _ratio;
  }

  receive() external payable {}

}
