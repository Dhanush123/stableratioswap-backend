//SPDX-License-Identifier: Unlicense
pragma solidity >=0.6.12;
pragma experimental ABIEncoderV2;

interface IStableRatioSwap {
    /**
     * Emit a {CreateUser} event
     */
    function createUser() external;

    /**
     * Emit a {Deposit} event
     */
    function getAllStablecoinDeposits() external;

    /**
     * Emit a {OptInToggle} event
     */
    function optInToggle() external;

    /**
     * Emit a {SwapStablecoinDeposit} event
     */
    function swapStablecoinDeposit(bool force) external;

    // function deposit(uint, string memory, address) external;

    event AllDeposits(
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

    event Deposit(
        bool depositStatus
    );

    event CreateUser(
        bool createUserStatus
    );

    event OptInToggle(
        bool optInStatus
    );

    event SwapStablecoinDeposit(
        bool swapStatus,
        uint ratio
    );
}