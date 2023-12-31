// SPDX-License-Identifier: None
pragma solidity ^0.8.18;
pragma abicoder v2;

import "./NoDelegateCall.sol";

import {SafeCast} from "../libraries/SafeCast.sol";
import {TickBitmap} from "../libraries/TickBitmap.sol";
import {Oracle} from "../libraries/Oracle.sol";

import {FullMath} from "../libraries/FullMath.sol";
import {FixedPoint128} from "../libraries/FixedPoint128.sol";
import {TransferHelper} from "../libraries/TransferHelper.sol";
import {TickMath} from "../libraries/TickMath.sol";
import {SqrtPriceMath} from "../libraries/SqrtPriceMath.sol";
import {SwapMath} from "../libraries/AlcorLibraries/SwapMath.sol";

// Alcor libraries
import {Tick} from "../libraries/AlcorLibraries/AlcorTick.sol";
import {Position} from "../libraries/AlcorLibraries/AlcorPosition.sol";
import {Polynomials} from "../libraries/AlcorLibraries/Polynomials.sol";
import {TickLibrary} from "../libraries/AlcorLibraries/TickLibrary.sol";

import "../interfaces/IUniswapV3Pool.sol";
import "../interfaces/IUniswapV3Factory.sol";
import "../interfaces/ISwapRouter.sol";
import "../interfaces/IAlcorPoolDeployer.sol";
import "../interfaces/IAlcorFactory.sol";

import "hardhat/console.sol";
import "../interfaces/IERC20Minimal.sol";

abstract contract AlcorVanillaOption is NoDelegateCall {
    using FullMath for uint256;
    // using LowGasSafeMath for uint256;
    // using LowGasSafeMath for int256;
    using SafeCast for uint256;
    using SafeCast for int256;

    using Tick for mapping(int24 => Tick.Info);
    using TickBitmap for mapping(int16 => uint256);
    using Position for mapping(bytes32 => Position.Info);
    using Position for Position.Info;
    using Oracle for Oracle.Observation[65535];

    event Initialize(int24 tick);
    event CollectProtocol(
        address indexed sender,
        address indexed recipient,
        uint128 amount0,
        uint128 amount1
    );
    event SetFeeProtocol(
        uint8 feeProtocol0Old,
        uint8 feeProtocol1Old,
        uint8 feeProtocol0New,
        uint8 feeProtocol1New
    );

    error LOK();
    error TLU();
    error TLM();
    error TUM();
    error AI();

    address public factory;

    address public token0;
    address public token1;
    uint24 public fee;

    // accumulated protocol fees in token0/token1 units
    struct ProtocolFees {
        uint128 token0;
        uint128 token1;
    }
    ProtocolFees public protocolFees;

    int24 public tickSpacing;

    // uint128 public maxLiquidityPerTick;

    // uint128 public liquidity;

    Tick.FeeGrowthX128 public feeGrowthGlobalX128;

    uint256 public density;

    mapping(int24 => Tick.Info) public ticks;
    mapping(int16 => uint256) public tickBitmap;
    mapping(bytes32 => Position.Info) public positions;
    Oracle.Observation[65535] public observations;

    // address public constant UNISWAP_V3_FACTORY =
    //     0x1F98431c8aD98523631AE4a59f267346ea31F984;
    // address public constant ISWAP_ROUTER =
    //     0xE592427A0AEce92De3Edee1F18E0157C05861564;
    // uint24 public constant UNISWAP_POOL_FEE = 500;

    struct OptionInfo {
        address token0;
        address token1;
        uint256 expiration;
        uint256 optionStrikePriceX96;
        bool isCallOption;
        bool isExpired;
        uint160 sqrtPriceAtExpiryX96;
        uint32 poolFee;
        // the current protocol fee as a percentage of the swap fee taken on withdrawal
        // represented as an integer denominator (1/x)%
        uint8 feeProtocol;
    }

    OptionInfo public optionMainInfo;

    struct Slot0 {
        // the current price
        // uint160 sqrtPriceX96;
        // the current tick
        int24 tick;
        // the most-recently updated index of the observations array
        uint16 observationIndex;
        // the current maximum number of observations that are being stored
        uint16 observationCardinality;
        // the next maximum number of observations to store, triggered in observations.write
        uint16 observationCardinalityNext;
        // whether the pool is locked
        bool unlocked;
    }

    Slot0 public slot0;

    Polynomials.AlphasVector public currentAlphas;

    /// @dev Mutually exclusive reentrancy protection into the pool to/from a method. This method also prevents entrance
    /// to a function before the pool is initialized. The reentrancy guard is required throughout the contract because
    /// we use balance checks to determine the payment status of interactions such as mint, swap and flash.
    modifier lock() {
        if (!slot0.unlocked) revert LOK();
        slot0.unlocked = false;
        _;
        slot0.unlocked = true;
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

    /// @dev Common checks for valid tick inputs.
    function checkTicks(int24 tickLower, int24 tickUpper) internal pure {
        if (tickLower >= tickUpper) revert TLU();
        if (tickLower < TickMath.MIN_TICK) revert TLM();
        if (tickUpper > TickMath.MAX_TICK) revert TUM();
    }

    /// @dev Returns the block timestamp truncated to 32 bits, i.e. mod 2**32. This method is overridden in tests.
    function _blockTimestamp() internal view virtual returns (uint32) {
        return uint32(block.timestamp); // truncation is desired
    }

    /// @dev Get the pool's balance of token0
    /// @dev This function is gas optimized to avoid a redundant extcodesize check in addition to the returndatasize
    /// check
    function balance0() internal view returns (uint256) {
        (bool success, bytes memory data) = token0.staticcall(
            abi.encodeWithSelector(
                IERC20Minimal.balanceOf.selector,
                address(this)
            )
        );
        require(success && data.length >= 32);
        return abi.decode(data, (uint256));
    }

    /// @dev Get the pool's balance of token1
    /// @dev This function is gas optimized to avoid a redundant extcodesize check in addition to the returndatasize
    /// check
    function balance1() internal view returns (uint256) {
        (bool success, bytes memory data) = token1.staticcall(
            abi.encodeWithSelector(
                IERC20Minimal.balanceOf.selector,
                address(this)
            )
        );
        require(success && data.length >= 32);
        return abi.decode(data, (uint256));
    }

    function initialize(int24 tick) external {
        // if (slot0.sqrtPriceX96 != 0) revert AI();
        if (tick < TickMath.MIN_TICK || tick > TickMath.MAX_TICK) revert AI();

        // uint160 sqrtPriceX96 = TickMath.getSqrtRatioAtTick(tick);

        // int24 tick = TickMath.getTickAtSqrtRatio(sqrtPriceX96);

        (uint16 cardinality, uint16 cardinalityNext) = observations.initialize(
            _blockTimestamp()
        );

        slot0 = Slot0({
            // sqrtPriceX96: sqrtPriceX96,
            tick: tick,
            observationIndex: 0,
            observationCardinality: cardinality,
            observationCardinalityNext: cardinalityNext,
            unlocked: true
        });

        emit Initialize(tick);
    }

    struct ModifyPositionParams {
        // the address that owns the position
        address owner;
        // the lower and upper tick of the position
        // int24 tickLower;
        int24 tickUpper;
        // any change in liquidity
        // int128 liquidityDelta;
        Polynomials.AlphasVector alphasDelta;
    }

    // ------------------ old ------------------

    function getPayout() public {
        require(optionMainInfo.isExpired, "option is not expired");
        // require(
        //     usersInfo[msg.sender].soldContractsAmount < 0,
        //     "this method is only for buyes"
        // );
        // if (optionMainInfo.payoff_token0 > 0) {
        //     usersInfo[msg.sender].soldContractsAmount = 0;
        //     uint256 amount = uint256(usersInfo[msg.sender].soldContractsAmount)
        //         .mul(optionMainInfo.payoff_token0);
        //     TransferHelper.safeTransfer(
        //         optionMainInfo.token0,
        //         msg.sender,
        //         amount
        //     );
        // }
    }

    function withdrawCollateral() public {
        require(optionMainInfo.isExpired, "option is not expired");
        // require(
        //     usersInfo[msg.sender].soldContractsAmount > 0,
        //     "this method is only for sellers"
        // );
        // if (optionMainInfo.payoff_token0 < 0) {
        //     usersInfo[msg.sender].soldContractsAmount = 0;
        //     uint256 amount = uint256(usersInfo[msg.sender].soldContractsAmount)
        //         .mul(optionMainInfo.priceAtExpiry);
        //     TransferHelper.safeTransfer(
        //         optionMainInfo.token0,
        //         msg.sender,
        //         amount
        //     );
        // } else {
        //     usersInfo[msg.sender].soldContractsAmount = 0;
        //     uint256 amount = uint256(usersInfo[msg.sender].soldContractsAmount)
        //         .mul(optionMainInfo.strikePrice);
        //     TransferHelper.safeTransfer(
        //         optionMainInfo.token0,
        //         msg.sender,
        //         amount
        //     );
        // }
    }

    function ToExpiredState() public {
        require(block.timestamp >= optionMainInfo.expiration, "too early");
        optionMainInfo.isExpired = true;

        //     address uniswap_pool = IUniswapV3Factory(UNISWAP_V3_FACTORY).getPool(
        //         optionMainInfo.token0,
        //         optionMainInfo.token1,
        //         UNISWAP_POOL_FEE
        //     );
        //     ISwapRouter router = ISwapRouter(ISWAP_ROUTER);

        //     address tokenIn = optionMainInfo.token1;
        //     address tokenOut = optionMainInfo.token0;

        //     uint256 tokenIn_balance = IERC20(tokenIn).balanceOf(address(this));
        //     // aprove tokenIn
        //     IERC20(optionMainInfo.token1).approve(address(router), tokenIn_balance);

        //     ISwapRouter.ExactInputSingleParams memory params = ISwapRouter
        //         .ExactInputSingleParams({
        //             tokenIn: tokenIn,
        //             tokenOut: tokenOut,
        //             fee: UNISWAP_POOL_FEE,
        //             recipient: address(this),
        //             deadline: block.timestamp,
        //             amountIn: tokenIn_balance,
        //             amountOutMinimum: 0,
        //             sqrtPriceLimitX96: 0
        //         });

        //     // execute swap
        //     router.exactInputSingle(params);

        //     (, int24 tick, , , , , ) = IUniswapV3Pool(uniswap_pool).slot0();
        //     optionMainInfo.priceAtExpiry = tick.getPriceAtTick();

        //     // out of the money call option
        //     if (optionMainInfo.priceAtExpiry <= optionMainInfo.strikePrice) {
        //         optionMainInfo.payoff_token0 = 0;
        //     }
        //     // in the money call option
        //     else {
        //         optionMainInfo.payoff_token0 = (optionMainInfo.priceAtExpiry -
        //             uint256(optionMainInfo.strikePrice));
        //     }
    }

    function setFeeProtocol(
        uint8 feeProtocol0,
        uint8 feeProtocol1
    ) external lock onlyFactoryOwner {
        unchecked {
            require(
                (feeProtocol0 == 0 ||
                    (feeProtocol0 >= 4 && feeProtocol0 <= 10)) &&
                    (feeProtocol1 == 0 ||
                        (feeProtocol1 >= 4 && feeProtocol1 <= 10))
            );
            uint8 feeProtocolOld = optionMainInfo.feeProtocol;
            optionMainInfo.feeProtocol = feeProtocol0 + (feeProtocol1 << 4);
            emit SetFeeProtocol(
                feeProtocolOld % 16,
                feeProtocolOld >> 4,
                feeProtocol0,
                feeProtocol1
            );
        }
    }

    function collectProtocol(
        address recipient,
        uint128 amount0Requested,
        uint128 amount1Requested
    )
        external
        lock
        onlyFactoryOwner
        returns (uint128 amount0, uint128 amount1)
    {
        amount0 = amount0Requested > protocolFees.token0
            ? protocolFees.token0
            : amount0Requested;
        amount1 = amount1Requested > protocolFees.token1
            ? protocolFees.token1
            : amount1Requested;

        unchecked {
            if (amount0 > 0) {
                if (amount0 == protocolFees.token0) amount0--; // ensure that the slot is not cleared, for gas savings
                protocolFees.token0 -= amount0;
                TransferHelper.safeTransfer(token0, recipient, amount0);
            }
            if (amount1 > 0) {
                if (amount1 == protocolFees.token1) amount1--; // ensure that the slot is not cleared, for gas savings
                protocolFees.token1 -= amount1;
                TransferHelper.safeTransfer(token1, recipient, amount1);
            }
        }

        emit CollectProtocol(msg.sender, recipient, amount0, amount1);
    }
}
