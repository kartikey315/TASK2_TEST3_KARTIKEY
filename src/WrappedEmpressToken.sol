// SPDX-License-Identifier: MIT
pragma solidity 0.8.26;

import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";

contract WrappedEmpressToken is ERC20, Ownable {
    IERC20 public empressToken;

    event Wrapped(address indexed account, uint256 amount);
    event Unwrapped(address indexed account, uint256 amount);

    error WET_AmountEqualOrLessToZero();
    error WET_TokenTransferFailed();
    error WET_InsufficientBalance();
    error WET_CannotRecoverEmpressToken();

    constructor(
        address _empressTokenAddress
    ) ERC20("Wrapped EMPRESS TOKEN", "WEMP") Ownable(msg.sender) {
        empressToken = IERC20(_empressTokenAddress);
    }

    function wrap(uint256 amount) external {
        if (amount <= 0) {
            revert WET_AmountEqualOrLessToZero();
        }
        bool success = empressToken.transferFrom(
            msg.sender,
            address(this),
            amount
        );
        if (!success) {
            revert WET_TokenTransferFailed();
        }
        _mint(msg.sender, amount);
        emit Wrapped(msg.sender, amount);
    }

    function unwrap(uint256 amount) external {
        if (amount <= 0) {
            revert WET_AmountEqualOrLessToZero();
        }
        if (balanceOf(msg.sender) < amount) {
            revert WET_InsufficientBalance();
        }

        _burn(msg.sender, amount);
        bool success = empressToken.transfer(msg.sender, amount);
        if (!success) {
            revert WET_TokenTransferFailed();
        }
        emit Unwrapped(msg.sender, amount);
    }

    function recoverERC20(
        address tokenAddress,
        uint256 tokenAmount
    ) external onlyOwner {
        if (tokenAddress == address(empressToken)) {
            revert WET_CannotRecoverEmpressToken();
        }
        IERC20(tokenAddress).transfer(owner(), tokenAmount);
    }
}
