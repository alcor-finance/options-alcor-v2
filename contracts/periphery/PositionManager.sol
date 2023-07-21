// SPDX-License-Identifier: None
pragma solidity ^0.8.18;

import "../dependencies/ReentrancyGuard.sol";

import "../libraries/AlcorLibs/UserInfoCallOption.sol";
import "../libraries/AlcorLibs/Cryptography.sol";
import "../libraries/AlcorLibs/TickLibrary.sol";
import "../libraries/AlcorLibs/BlackScholes.sol";

import "../core/AlcorFactory.sol";
import "../core/AlcorPoolCallOption.sol";
import "../core/AlcorPoolPutOption.sol";

import "./AaveSupplier.sol";

contract AlcorPositionManager is ReentrancyGuard, AaveSupplier {
    using FullMath for uint256;
    using LowGasSafeMath for uint256;
    using LowGasSafeMath for int256;
    using SafeCast for uint256;
    using SafeCast for int256;

    using TickLibrary for int24;

    using Cryptography for Cryptography.SellingLimitOrder;
    using Cryptography for Cryptography.BuyingLimitOrder;
    using Cryptography for bytes32;

    constructor() ReentrancyGuard() {}

    // deposit funds to liquidity pool, it will be used as a collateral for options sellings
    function deposit(uint256 amount, address token) external {}

    // withdraw funds from liquidity pool
    function withdraw(uint256 amount, address token) external {}

    function claimReward(uint256 amount, address token) external {}

    function buyOption() external {}

    function sellOption() external {}

    // liquidate the position purchasing options from the market
    function liquidate(
        Cryptography.BuyingLimitOrder[] memory buyingLimitOrders
    ) external {}

    // if there's no buying orders, we just liquidate the selling position and then delta hedge it
    function liquidate() external {}

    function _depositToLendingPool(uint256 amount, address token) internal {}

    function _withdrawFromLendingPool(uint256 amount, address token) internal {}

    function _hedgeLiquidatedPositions() internal {}
}
