// SPDX-License-Identifier: None
pragma solidity ^0.8.18;
pragma abicoder v2;

import "../dependencies/ReentrancyGuard.sol";
import "./NoDelegateCall.sol";

// import "../libraries/LowGasSafeMath.sol";
import "../libraries/SafeCast.sol";
import "../libraries/TransferHelper.sol";

import "../libraries/AlcorLibraries/UserInfoCallOption.sol";
import "../libraries/AlcorLibraries/Cryptography.sol";
import "../libraries/AlcorLibraries/TickLibrary.sol";

import "../interfaces/IERC20Minimal.sol";

import "../interfaces/IUniswapV3Pool.sol";
import "../interfaces/IUniswapV3Factory.sol";
import "../interfaces/ISwapRouter.sol";
import "../interfaces/IAlcorPoolDeployer.sol";
import "../interfaces/IAlcorFactory.sol";

abstract contract AlcorVanillaOption is ReentrancyGuard, NoDelegateCall {
    using FullMath for uint256;

    // using LowGasSafeMath for uint256;
    // using LowGasSafeMath for int256;
    using SafeCast for uint256;
    using SafeCast for int256;

    using TickLibrary for int24;

    // using Cryptography for Cryptography.SellingLimitOrder;
    // using Cryptography for Cryptography.BuyingLimitOrder;
    // using Cryptography for bytes32;

    // using UserInfoCallOption for mapping(address => UserInfoCallOption.Info);

    address public immutable factory;
    uint24 public immutable protocolFee;

    uint256 public token0_unclaimedProtocolFees;
    uint256 public token1_unclaimedProtocolFees;

    address public constant UNISWAP_V3_FACTORY =
        0x1F98431c8aD98523631AE4a59f267346ea31F984;
    address public constant ISWAP_ROUTER =
        0xE592427A0AEce92De3Edee1F18E0157C05861564;
    uint24 public constant UNISWAP_POOL_FEE = 500;

    struct OptionInfo {
        // TOKEN0 must be STABLECOIN
        address token0;
        // TOKEN1 must be UNDERLYING ASSET (e.g. WETH)
        address token1;
        uint8 token0Decimals;
        uint8 token1Decimals;
        uint256 expiration;
        uint160 strikePrice;
        bool isCallOption;
        int24 tickSpacing;
        // uint24 protocolFee;
        bool isExpired;
        uint256 payoff_token0;
        uint256 openInterest;
        uint256 priceAtExpiry;
    }

    OptionInfo public optionMainInfo;

    mapping(address => UserInfoCallOption.Info) public usersInfo;

    struct limitOrderFulfilment {
        uint256 fulfilledAmount;
        bool isFulfilled;
    }
    // keccak256(signature of the limit order)
    mapping(bytes32 => limitOrderFulfilment) public limitOrdersFulfilments;

    constructor() ReentrancyGuard() {
        (
            factory,
            optionMainInfo.token0,
            optionMainInfo.token1,
            optionMainInfo.token0Decimals,
            optionMainInfo.token1Decimals,
            optionMainInfo.expiration,
            optionMainInfo.strikePrice,
            optionMainInfo.tickSpacing
        ) = IAlcorPoolDeployer(msg.sender).parameters();

        optionMainInfo.isCallOption = true;
        protocolFee = 500; // 0.05%
    }

    /// @dev Prevents calling a function from anyone except the address returned by IAlcorFactory#owner()
    modifier onlyFactoryOwner() {
        require(msg.sender == IAlcorFactory(factory).owner());
        _;
    }

    modifier optionNotExpired() {
        console.log(block.timestamp, optionMainInfo.expiration);
        require(
            block.timestamp < optionMainInfo.expiration,
            "option is expired"
        );
        _;
    }

    function claimProtocolFees(
        address token,
        uint256 amount
    ) external nonReentrant onlyFactoryOwner {
        require(
            token == optionMainInfo.token0 || token == optionMainInfo.token1,
            "Invalid token"
        );

        if (token == optionMainInfo.token0) {
            require(amount <= token0_unclaimedProtocolFees, "amount too big");
            token0_unclaimedProtocolFees -= amount;
            TransferHelper.safeTransfer(token, msg.sender, amount);
        } else {
            require(amount <= token1_unclaimedProtocolFees, "amount too big");
            token1_unclaimedProtocolFees -= amount;
            TransferHelper.safeTransfer(token, msg.sender, amount);
        }
    }

    function getPayout() public nonReentrant {
        require(optionMainInfo.isExpired, "option is not expired");
        require(
            usersInfo[msg.sender].soldContractsAmount < 0,
            "this method is only for buyes"
        );
        if (optionMainInfo.payoff_token0 > 0) {
            usersInfo[msg.sender].soldContractsAmount = 0;
            uint256 amount = uint256(usersInfo[msg.sender].soldContractsAmount)
                .mulDiv(optionMainInfo.payoff_token0, 1);
            TransferHelper.safeTransfer(
                optionMainInfo.token0,
                msg.sender,
                amount
            );
        }
    }

    function withdrawCollateral() public nonReentrant {
        require(optionMainInfo.isExpired, "option is not expired");
        require(
            usersInfo[msg.sender].soldContractsAmount > 0,
            "this method is only for sellers"
        );
        if (optionMainInfo.payoff_token0 < 0) {
            usersInfo[msg.sender].soldContractsAmount = 0;
            uint256 amount = uint256(usersInfo[msg.sender].soldContractsAmount)
                .mulDiv(optionMainInfo.priceAtExpiry, 1);
            TransferHelper.safeTransfer(
                optionMainInfo.token0,
                msg.sender,
                amount
            );
        } else {
            usersInfo[msg.sender].soldContractsAmount = 0;
            uint256 amount = uint256(usersInfo[msg.sender].soldContractsAmount)
                .mulDiv(optionMainInfo.strikePrice, 1);
            TransferHelper.safeTransfer(
                optionMainInfo.token0,
                msg.sender,
                amount
            );
        }
    }

    function ToExpiredState() public {
        require(block.timestamp >= optionMainInfo.expiration, "too early");
        optionMainInfo.isExpired = true;

        address uniswap_pool = IUniswapV3Factory(UNISWAP_V3_FACTORY).getPool(
            optionMainInfo.token0,
            optionMainInfo.token1,
            UNISWAP_POOL_FEE
        );
        ISwapRouter router = ISwapRouter(ISWAP_ROUTER);

        address tokenIn = optionMainInfo.token1;
        address tokenOut = optionMainInfo.token0;

        uint256 tokenIn_balance = IERC20Minimal(tokenIn).balanceOf(
            address(this)
        );
        // aprove tokenIn
        IERC20Minimal(optionMainInfo.token1).approve(
            address(router),
            tokenIn_balance
        );

        ISwapRouter.ExactInputSingleParams memory params = ISwapRouter
            .ExactInputSingleParams({
                tokenIn: tokenIn,
                tokenOut: tokenOut,
                fee: UNISWAP_POOL_FEE,
                recipient: address(this),
                deadline: block.timestamp,
                amountIn: tokenIn_balance,
                amountOutMinimum: 0,
                sqrtPriceLimitX96: 0
            });

        // execute swap
        router.exactInputSingle(params);

        (, int24 tick, , , , , ) = IUniswapV3Pool(uniswap_pool).slot0();
        optionMainInfo.priceAtExpiry = tick.getPriceAtTick();

        // out of the money call option
        if (optionMainInfo.priceAtExpiry <= optionMainInfo.strikePrice) {
            optionMainInfo.payoff_token0 = 0;
        }
        // in the money call option
        else {
            optionMainInfo.payoff_token0 = (optionMainInfo.priceAtExpiry -
                uint256(optionMainInfo.strikePrice));
        }
    }
}
