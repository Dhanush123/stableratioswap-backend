//SPDX-License-Identifier: Unlicense
pragma solidity >=0.6.12;

import "hardhat/console.sol";
import "@openzeppelin/contracts/math/SafeMath.sol";
import "./IStableRatioSwap.sol";

contract MockStableRatioSwap is IStableRatioSwap {

  using SafeMath for uint;
  // using Address for address;

  uint ratio;

  address[] private userAddresses;
  mapping(address => User) private userData;
  mapping(string => bool) stablecoinList;

  struct User {
    address userAddress;
    bool optInStatus;
  }

  constructor() public {
    stablecoinList["TUSD"] = true;
    stablecoinList["USDC"] = true;
    stablecoinList["USDT"] = true;
    stablecoinList["DAI"] = true;
    stablecoinList["BUSD"] = true;
  }

  function deposit(uint amount, string memory tokenType, address sender) internal {
    // String check
    require(stablecoinList[tokenType]);
  }

  function createUser() external override returns (bool) {
    require(userData[msg.sender].userAddress == address(0));
    userData[msg.sender].userAddress = msg.sender;
    userData[msg.sender].optInStatus = false;
    userAddresses.push(msg.sender);
    emit Bool(true);
    return true;
  }

  function getAllUsers() internal view returns (address[] memory) {
    return userAddresses;
  }

  function getAllStablecoinDeposits() external override returns (bool) {
    (uint tusd, uint decimalsTusd) = _getCurrentDepositData(msg.sender, "TUSD");
    (uint usdc, uint decimalsUsdc) = _getCurrentDepositData(msg.sender, "USDC");
    (uint usdt, uint decimalsUsdt) = _getCurrentDepositData(msg.sender, "USDT");
    (uint dai, uint decimalsDai) = _getCurrentDepositData(msg.sender, "DAI");
    (uint busd, uint decimalsBusd) = _getCurrentDepositData(msg.sender, "BUSD");
    emit Deposit(tusd, decimalsTusd, usdc, decimalsUsdc, usdt, decimalsUsdt, dai, decimalsDai, busd, decimalsBusd);
    return true;
  }

  function _getCurrentDepositData(address userAddress, string memory tokenType) internal view returns (uint, uint) {
    return (100,2);
  }

  function _getHighestAPYStablecoinAlt() internal view returns (string memory, uint) {
    //need to double check actual uint value representation
    return ("USDC", 110);
  }

  function max(uint a, uint b) private pure returns (uint) {
    return a > b ? a : b;
  }

  function optInToggle() external override returns (bool) {
    userData[msg.sender].optInStatus = !userData[msg.sender].optInStatus;
    emit Bool(userData[msg.sender].optInStatus);
    return userData[msg.sender].optInStatus;
  }

  // /**
  //   This function is called after your contract has received the flash loaned amount
  // */
  // function executeOperation(
  //     address[] calldata assets,
  //     uint[] calldata amounts,
  //     uint[] calldata premiums,
  //     address initiator,
  //     bytes calldata params
  // )
  //     external
  //     override
  //     returns (bool)
  // {

  //     //
  //     // This contract now has the funds requested.
  //     // Your logic goes here.
  //     //
  //     require(msg.sender == address(LENDING_POOL), 'CALLER_MUST_BE_LENDING_POOL');

      
  //     // At the end of your logic above, this contract owes
  //     // the flashloaned amounts + premiums.
  //     // Therefore ensure your contract has enough to repay
  //     // these amounts.
      
  //     // Approve the LendingPool contract allowance to *pull* the owed amount
  //     for (uint i = 0; i < assets.length; i++) {
  //         uint amountOwing = amounts[i].add(premiums[i]);
  //         IERC20(assets[i]).approve(address(LENDING_POOL), amountOwing);
  //     }
      
  //     return true;
  // }

  function swapStablecoinDeposit() external override returns (bool) {
    requestTUSDRatio();
    require(ratio > 10000, "The transaction terminated because the TUSD ratio is not bigger than 1");
    emit Bool(true);
    return true;
  }

  function requestTUSDRatio() internal {
    ratio = 1210; //corresponds to 1.210
  }
}
