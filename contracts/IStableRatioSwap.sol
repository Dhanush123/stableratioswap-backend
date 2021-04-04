//SPDX-License-Identifier: Unlicense
pragma solidity >=0.6.12;
pragma experimental ABIEncoderV2;

interface IStableRatioSwap {
    /**
     * Emit a {Bool} event
     */
    function createUser() external returns (bool);

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
        uint tusd,
        uint decimalsTusd,
        uint usdc,
        uint decimalsUsdc,
        uint usdt,
        uint decimalsUsdt,
        uint dai,
        uint decimalsDai,
        uint busd,
        uint decimalsBusd
    );

    event Bool(
        bool _bool
    );
}