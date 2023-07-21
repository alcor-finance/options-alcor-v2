// SPDX-License-Identifier: None
pragma solidity ^0.8.18;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "../../contracts/interfaces/aave/IPool.sol";

contract AaveSupplier {
    IPool constant lendingPool =
        IPool(0x7d2768dE32b0b80b7a3454c06BdAc94A69DDc7A9);

    mapping(address => uint256) public deposits;

    error InsufficientBalance(uint256 available, uint256 required);

    function deposit(address asset, uint256 amount) public {
        // user must first approve this contract to spend their asset
        IERC20(asset).transferFrom(msg.sender, address(this), amount);

        deposits[msg.sender] += amount;

        IERC20(asset).approve(address(lendingPool), amount);
        lendingPool.deposit(asset, amount, address(this), 0);
    }

    function withdraw(address asset, uint256 amount) public {
        if (deposits[msg.sender] < amount) {
            revert InsufficientBalance(deposits[msg.sender], amount);
        }

        lendingPool.withdraw(asset, amount, msg.sender);

        deposits[msg.sender] -= amount;
    }
}
