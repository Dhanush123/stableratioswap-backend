//SPDX-License-Identifier: Unlicense
pragma solidity >=0.6.12;

import "hardhat/console.sol";
import "@openzeppelin/contracts/math/SafeMath.sol";
import {Address} from "@openzeppelin/contracts/utils/Address.sol";
import "./IStableRatioSwap.sol";

contract MockStableRatioSwap is IStableRatioSwap {

  using SafeMath for uint;
  using Address for address;

  uint ratio;
  uint nonce;

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

  function deposit(uint amount, string memory tokenType, address sender) public override {
    // String check
    require(stablecoinList[tokenType]);
  }

  function createUser() external override {
    require(userData[msg.sender].userAddress == address(0));
    userData[msg.sender].userAddress = msg.sender;
    userData[msg.sender].optInStatus = false;
    userAddresses.push(msg.sender);
    // emit Bool(true);
    // return true;
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
    emit Deposit(tusd, decimalsTusd, usdc, decimalsUsdc, usdt, decimalsUsdt, dai, decimalsDai, busd, decimalsBusd);
  }

  function _getCurrentDepositData(address userAddress, string memory tokenType) internal returns (uint, uint) {
    return (random(),2); //i.e. 10100, 2 == 101.00
  }

  function _getHighestAPYStablecoinAlt() internal view returns (string memory, uint) {
    //need to double check actual uint value representation
    return ("USDC", 110);
  }

  function max(uint a, uint b) private pure returns (uint) {
    return a > b ? a : b;
  }

  function optInToggle() external override {
    userData[msg.sender].optInStatus = !userData[msg.sender].optInStatus;
    // emit Bool(userData[msg.sender].optInStatus);
  }

  function swapStablecoinDeposit() external override {
    requestTUSDRatio();
    require(ratio > 10000, "The transaction terminated because the TUSD ratio is not bigger than 1");
    // emit Bool(true);
    // return true;
  }

  function requestTUSDRatio() internal {
    ratio = 1210; //corresponds to 1.210
  }

  function random() internal returns (uint) {
    uint randomnumber = uint(keccak256(abi.encodePacked(now, msg.sender, nonce))) % 900;
    randomnumber = randomnumber + 101;
    nonce++;
    return randomnumber;
  }
}
