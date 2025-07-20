// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.20;

import "forge-std/Test.sol";
import {Bank} from "../src/Bank.sol";

contract BankTest is Test {
    Bank public bank;
    address admin;
    address user1;
    address user2;
    address user3;
    address user4;

    function setUp() public {
        admin = address(this);
        user1 = vm.addr(1);
        user2 = vm.addr(2);
        user3 = vm.addr(3);
        user4 = vm.addr(4);
        bank = new Bank();
    }

    function testDepositUpdatesBalance() public {
        // 存款前余额应为0
        assertEq(bank.balances(user1), 0);
        // user1 存入 1 ether
        vm.deal(user1, 1 ether);
        vm.prank(user1);
        bank.deposit{value: 1 ether}();
        // 存款后余额应为1 ether
        assertEq(bank.balances(user1), 1 ether);
    }

    function testTopDepositors_1User() public {
        vm.deal(user1, 1 ether);
        vm.prank(user1);
        bank.deposit{value: 1 ether}();
        // 只有user1
        assertEq(bank.topDepositors(0), user1);
        assertEq(bank.topDepositors(1), address(0));
        assertEq(bank.topDepositors(2), address(0));
    }

    function testTopDepositors_2Users() public {
        vm.deal(user1, 1 ether);
        vm.deal(user2, 2 ether);
        vm.prank(user1);
        bank.deposit{value: 1 ether}();
        vm.prank(user2);
        bank.deposit{value: 2 ether}();
        // user2 > user1
        assertEq(bank.topDepositors(0), user2);
        assertEq(bank.topDepositors(1), user1);
        assertEq(bank.topDepositors(2), address(0));
    }

    function testTopDepositors_3Users() public {
        vm.deal(user1, 1 ether);
        vm.deal(user2, 2 ether);
        vm.deal(user3, 3 ether);
        vm.prank(user1);
        bank.deposit{value: 1 ether}();
        vm.prank(user2);
        bank.deposit{value: 2 ether}();
        vm.prank(user3);
        bank.deposit{value: 3 ether}();
        // user3 > user2 > user1
        assertEq(bank.topDepositors(0), user3);
        assertEq(bank.topDepositors(1), user2);
        assertEq(bank.topDepositors(2), user1);
    }

    function testTopDepositors_4Users() public {
        vm.deal(user1, 1 ether);
        vm.deal(user2, 2 ether);
        vm.deal(user3, 3 ether);
        vm.deal(user4, 4 ether);
        vm.prank(user1);
        bank.deposit{value: 1 ether}();
        vm.prank(user2);
        bank.deposit{value: 2 ether}();
        vm.prank(user3);
        bank.deposit{value: 3 ether}();
        vm.prank(user4);
        bank.deposit{value: 4 ether}();
        // user4 > user3 > user2，user1被挤出榜单
        assertEq(bank.topDepositors(0), user4);
        assertEq(bank.topDepositors(1), user3);
        assertEq(bank.topDepositors(2), user2);
    }

    function testTopDepositors_SameUserMultipleDeposits() public {
        vm.deal(user1, 5 ether);
        vm.deal(user2, 2 ether);
        vm.deal(user3, 3 ether);
        vm.prank(user1);
        bank.deposit{value: 1 ether}();
        vm.prank(user2);
        bank.deposit{value: 2 ether}();
        vm.prank(user3);
        bank.deposit{value: 3 ether}();
        // user3 > user2 > user1
        assertEq(bank.topDepositors(0), user3);
        assertEq(bank.topDepositors(1), user2);
        assertEq(bank.topDepositors(2), user1);
        // user1 再存 4 ether，总额5 ether，成为第一
        vm.prank(user1);
        bank.deposit{value: 4 ether}();
        assertEq(bank.topDepositors(0), user1);
        assertEq(bank.topDepositors(1), user3);
        assertEq(bank.topDepositors(2), user2);
    }

    function testOnlyAdminCanWithdraw() public {
        // admin存入10 ether
        vm.deal(admin, 10 ether);
        bank.deposit{value: 10 ether}();
        // 非admin取款应revert
        vm.deal(user1, 1 ether);
        vm.prank(user1);
        vm.expectRevert("Only admin can withdraw");
        bank.withdraw(1 ether);
        // admin取款成功
        uint256 before = admin.balance;
        bank.withdraw(5 ether);
        assertEq(admin.balance, before + 5 ether);
    }
} 