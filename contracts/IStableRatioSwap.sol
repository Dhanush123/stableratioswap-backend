//SPDX-License-Identifier: Unlicense
pragma solidity >=0.6.12;
pragma experimental ABIEncoderV2;

interface IStableRatioSwap {
    /**
     * Emit a {Deposit} event
     */
    function createUser(address _userAddress) external returns (bool);

    /**
     * Emit a {Deposit} event
     */
    function getAllStablecoinDeposits() external returns (bool);

    /**
     * Emit a {Bool} event
     */
    function optInToggle() external returns (bool);

    /**
     * Emit a {Bool} event
     */
    function swapStablecoinDeposit() external returns (bool);

    event Deposit(
        uint256 tusd,
        uint256 usdc,
        uint256 usdt,
        uint256 dai,
        uint256 busd
    );

    event Bool(
        bool _bool
    );
}