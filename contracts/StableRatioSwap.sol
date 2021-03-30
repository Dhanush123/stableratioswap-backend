//SPDX-License-Identifier: Unlicense
pragma solidity >=0.6.12;
pragma experimental ABIEncoderV2;

// HardHat Imports
import "hardhat/console.sol";
import "@chainlink/contracts/src/v0.6/ChainlinkClient.sol";
import "@chainlink/contracts/src/v0.6/interfaces/AggregatorV3Interface.sol";
import {ILendingPool} from "@aave/protocol-v2/contracts/interfaces/ILendingPool.sol";
import {ILendingPoolAddressesProvider} from '@aave/protocol-v2/contracts/interfaces/ILendingPoolAddressesProvider.sol';
import {AaveProtocolDataProvider} from "@aave/protocol-v2/contracts/misc/AaveProtocolDataProvider.sol";
import "@openzeppelin/contracts/math/SafeMath.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract StableRatioSwap is ChainlinkClient {

  using SafeMath for uint256;

  bytes32 jobID = "35e14dbd490f4e3b9fbe92b85b32d98a";
  address private constant oracle = 0xFC153f49E74711C3140CA06bFAcf42FfDC492A17;
  uint256 private fee = 0.01 * 1 ether;
  // address private constant LINK_KOVAN = 0xTo_Be_Filled; 
  // address private constant NODE_ADDRESS = 0xTo_Be_Filled;

  // These addresses are for Kovan
  address constant ILendingPoolAddressesProvider_Addr = 0x88757f2f99175387aB4C6a4b3067c77A695b0349;
  address constant AaveProtocolDataProvider_Addr = 0x3c73A5E5785cAC854D468F727c606C07488a29D6;

  address private owner;
  address[] private userAddresses;
  mapping(address => User) private userData;
  mapping(string => address) stableCoinAddresses;
  address pooladdr;
  ILendingPool pool;

  mapping(string => bool) stablecoinList;
  
  struct User {
    address userAddress;
    bool flag;
  }

  modifier onlyFlag {
    require(userData[msg.sender].flag, 'Call this function only when the flag of a user is true');
    _;
  }

  //modifier onlyNode() {
    //require(NODE_ADDRESS == msg.sender, 'Only Node can call this function');
    //_;
  //}

  event Deposit(
    uint256 tusd,
    uint256 usdc,
    uint256 usdt,
    uint256 dai,
    uint256 busd
  );

  constructor() public {
    setPublicChainlinkToken();
    owner = msg.sender;
    pooladdr = ILendingPoolAddressesProvider(ILendingPoolAddressesProvider_Addr).getLendingPool();
    pool = ILendingPool(pooladdr);
    // Constructing hashmaps
    AaveProtocolDataProvider.TokenData[] memory allTokenData = AaveProtocolDataProvider(AaveProtocolDataProvider_Addr).getAllATokens();
    for (uint i = 0; i < allTokenData.length; i++) {
      AaveProtocolDataProvider.TokenData memory token = allTokenData[0];
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
    require(IERC20(token).approve(pooladdr, amount));
    
    pool.deposit(token, amount, msg.sender, 0);

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
    uint256 tusd = _getCurrentDepositData("TUSD");
    uint256 usdc = _getCurrentDepositData("USDC");
    uint256 usdt = _getCurrentDepositData("USDT");
    uint256 dai = _getCurrentDepositData("DAI");
    uint256 busd = _getCurrentDepositData("BUSD");
    emit Deposit(tusd, usdc, usdt, dai, busd);
  }

  function _getCurrentDepositData(string memory tokenType) internal view returns (uint256) {
    // Helper for getAllStablecoinDeposits()
    address token = stableCoinAddresses[tokenType];
    uint256 currentBalance;
    (currentBalance,,,,,,,,) = AaveProtocolDataProvider(AaveProtocolDataProvider_Addr).getUserReserveData(token, msg.sender);
    return currentBalance;
  }

  function _getHighestAPYStablecoinAlt() internal {

  }

  function optToggle() public {
    userData[msg.sender].flag = !userData[msg.sender].flag;
  }

  function swapStablecoinDeposit() public onlyFlag {

  }

  function requestTUSDRatio() public {
    Chainlink.Request memory req = buildChainlinkRequest(jobID, address(this), this.fulfillEthereumPrice.selector);
    sendChainlinkRequestTo(oracle, req, fee);
  }

  function getTUSDRatio(bytes32 _requestID) public requestTUSDRatio(_requestID) {

  }

}
