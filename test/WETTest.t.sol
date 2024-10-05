// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {Test, console} from "forge-std/Test.sol";
import {WrappedEmpressToken} from "../src/WrappedEmpressToken.sol";
import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract MockEmpressToken is ERC20 {
    constructor() ERC20("EMPRESS TOKEN", "EMP") {
        _mint(msg.sender, 1000000 * 10 ** 18);
    }
}

contract WrappedEmpressTokenTest is Test {
    WrappedEmpressToken public wempToken;
    MockEmpressToken public empToken;
    address public owner;
    address public user1;
    address public user2;

    uint256 constant INITIAL_BALANCE = 1000 * 10 ** 18;

    function setUp() public {
        owner = address(this);
        user1 = makeAddr("USER1");
        user2 = makeAddr("USER2");

        empToken = new MockEmpressToken();
        wempToken = new WrappedEmpressToken(address(empToken));

        empToken.transfer(user1, INITIAL_BALANCE);
        empToken.transfer(user2, INITIAL_BALANCE);
    }

    function testInitialState() public {
        assertEq(wempToken.name(), "Wrapped EMPRESS TOKEN");
        assertEq(wempToken.symbol(), "WEMP");
        assertEq(address(wempToken.empressToken()), address(empToken));
    }

    function testWrap() public {
        uint256 wrapAmount = 100 * 10 ** 18;

        vm.startPrank(user1);
        empToken.approve(address(wempToken), wrapAmount);
        wempToken.wrap(wrapAmount);
        vm.stopPrank();

        assertEq(wempToken.balanceOf(user1), wrapAmount);
        assertEq(empToken.balanceOf(user1), INITIAL_BALANCE - wrapAmount);
        assertEq(empToken.balanceOf(address(wempToken)), wrapAmount);
    }

    function testUnwrap() public {
        uint256 wrapAmount = 100 * 10 ** 18;

        vm.startPrank(user1);
        empToken.approve(address(wempToken), wrapAmount);
        wempToken.wrap(wrapAmount);
        wempToken.unwrap(wrapAmount);
        vm.stopPrank();

        assertEq(wempToken.balanceOf(user1), 0);
        assertEq(empToken.balanceOf(user1), INITIAL_BALANCE);
        assertEq(empToken.balanceOf(address(wempToken)), 0);
    }

    function testWrapZeroAmount() public {
        vm.expectRevert(
            WrappedEmpressToken.WET_AmountEqualOrLessToZero.selector
        );
        wempToken.wrap(0);
    }

    function testUnwrapZeroAmount() public {
        vm.expectRevert(
            WrappedEmpressToken.WET_AmountEqualOrLessToZero.selector
        );
        wempToken.unwrap(0);
    }

    function testUnwrapInsufficientBalance() public {
        uint256 wrapAmount = 100 * 10 ** 18;

        vm.startPrank(user1);
        empToken.approve(address(wempToken), wrapAmount);
        wempToken.wrap(wrapAmount);

        vm.expectRevert(WrappedEmpressToken.WET_InsufficientBalance.selector);
        wempToken.unwrap(wrapAmount + 1);
        vm.stopPrank();
    }

    function testRecoverERC20() public {
        MockEmpressToken anotherToken = new MockEmpressToken();
        uint256 initialBalance = anotherToken.balanceOf(owner);
        uint256 amount = 100 * 10 ** 18;
        anotherToken.transfer(address(wempToken), amount);

        wempToken.recoverERC20(address(anotherToken), amount);

        assertEq(anotherToken.balanceOf(owner), initialBalance);
    }

    function testRecoverERC20EmpressToken() public {
        uint256 amount = 100 * 10 ** 18;
        empToken.transfer(address(wempToken), amount);

        vm.expectRevert(
            WrappedEmpressToken.WET_CannotRecoverEmpressToken.selector
        );
        wempToken.recoverERC20(address(empToken), amount);
    }

    function testTransferWrappedTokens() public {
        uint256 wrapAmount = 100 * 10 ** 18;
        uint256 transferAmount = 50 * 10 ** 18;

        vm.startPrank(user1);
        empToken.approve(address(wempToken), wrapAmount);
        wempToken.wrap(wrapAmount);
        wempToken.transfer(user2, transferAmount);
        vm.stopPrank();

        assertEq(wempToken.balanceOf(user1), wrapAmount - transferAmount);
        assertEq(wempToken.balanceOf(user2), transferAmount);
    }

    function testWrapAndUnwrapMultipleUsers() public {
        uint256 wrapAmount1 = 100 * 10 ** 18;
        uint256 wrapAmount2 = 150 * 10 ** 18;

        vm.startPrank(user1);
        empToken.approve(address(wempToken), wrapAmount1);
        wempToken.wrap(wrapAmount1);
        vm.stopPrank();

        vm.startPrank(user2);
        empToken.approve(address(wempToken), wrapAmount2);
        wempToken.wrap(wrapAmount2);
        vm.stopPrank();

        assertEq(wempToken.balanceOf(user1), wrapAmount1);
        assertEq(wempToken.balanceOf(user2), wrapAmount2);
        assertEq(
            empToken.balanceOf(address(wempToken)),
            wrapAmount1 + wrapAmount2
        );

        vm.prank(user1);
        wempToken.unwrap(wrapAmount1);

        vm.prank(user2);
        wempToken.unwrap(wrapAmount2);

        assertEq(wempToken.balanceOf(user1), 0);
        assertEq(wempToken.balanceOf(user2), 0);
        assertEq(empToken.balanceOf(address(wempToken)), 0);
        assertEq(empToken.balanceOf(user1), INITIAL_BALANCE);
        assertEq(empToken.balanceOf(user2), INITIAL_BALANCE);
    }

    function testWrapUnwrapFuzzed(uint256 wrapAmount) public {
        vm.assume(wrapAmount > 0 && wrapAmount <= INITIAL_BALANCE);

        vm.startPrank(user1);
        empToken.approve(address(wempToken), wrapAmount);
        wempToken.wrap(wrapAmount);

        assertEq(wempToken.balanceOf(user1), wrapAmount);
        assertEq(empToken.balanceOf(user1), INITIAL_BALANCE - wrapAmount);

        wempToken.unwrap(wrapAmount);

        assertEq(wempToken.balanceOf(user1), 0);
        assertEq(empToken.balanceOf(user1), INITIAL_BALANCE);
        vm.stopPrank();
    }
}
