// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.20;

import "forge-std/Test.sol";
import {Bank} from "../src/Bank.sol";
import {BankAutomation} from "../src/BankAutomation.sol";

contract BankAutomationTest is Test {
    Bank public bank;
    BankAutomation public automation;
    address admin;
    address user1;
    address user2;
    address user3;

    // 添加receive函数来接收ETH
    receive() external payable {}

    function setUp() public {
        admin = address(this);
        user1 = vm.addr(1);
        user2 = vm.addr(2);
        user3 = vm.addr(3);
        
        bank = new Bank();
        automation = new BankAutomation(payable(address(bank)));
        
        // 设置自动化合约地址
        bank.setAutomationContract(address(automation));
    }

    function testAddAndRemoveUser() public {
        // 添加用户到监控列表
        automation.addUser(user1);
        assertTrue(automation.monitoredUsers(user1));
        
        // 移除用户
        automation.removeUser(user1);
        assertFalse(automation.monitoredUsers(user1));
    }

    function testCheckUpkeep() public {
        // 添加用户到监控列表
        automation.addUser(user1);
        
        // 用户存款但未达到阈值
        vm.prank(user1);
        bank.approve(5 ether);
        vm.deal(user1, 5 ether);
        vm.prank(user1);
        bank.deposit{value: 5 ether}();
        
        // 检查是否需要自动化转移
        (bool upkeepNeeded,) = automation.checkUpkeep("");
        assertFalse(upkeepNeeded);
        
        // 用户存款达到阈值
        vm.prank(user1);
        bank.approve(10 ether);
        vm.deal(user1, 10 ether);
        vm.prank(user1);
        bank.deposit{value: 10 ether}();
        
        // 检查是否需要自动化转移
        (upkeepNeeded,) = automation.checkUpkeep("");
        assertTrue(upkeepNeeded);
    }

    function testPerformUpkeep() public {
        // 添加用户到监控列表
        automation.addUser(user1);
        
        // 用户存款达到阈值
        vm.prank(user1);
        bank.approve(15 ether);
        vm.deal(user1, 15 ether);
        vm.prank(user1);
        bank.deposit{value: 15 ether}();
        
        uint256 adminBalanceBefore = admin.balance;
        
        // 执行自动化转移
        automation.performUpkeep(abi.encode(user1));
        
        // 验证自动化转移
        assertEq(admin.balance, adminBalanceBefore + 7.5 ether);
        assertEq(bank.balances(user1), 7.5 ether);
    }

    function testManualTrigger() public {
        // 添加用户到监控列表
        automation.addUser(user1);
        
        // 用户存款达到阈值
        vm.prank(user1);
        bank.approve(15 ether);
        vm.deal(user1, 15 ether);
        vm.prank(user1);
        bank.deposit{value: 15 ether}();
        
        uint256 adminBalanceBefore = admin.balance;
        
        // 手动触发自动化转移
        automation.manualTrigger(user1);
        
        // 验证自动化转移
        assertEq(admin.balance, adminBalanceBefore + 7.5 ether);
        assertEq(bank.balances(user1), 7.5 ether);
    }

    function testMultipleUsers() public {
        // 添加多个用户到监控列表
        automation.addUser(user1);
        automation.addUser(user2);
        automation.addUser(user3);
        
        // 用户1存款达到阈值
        vm.prank(user1);
        bank.approve(15 ether);
        vm.deal(user1, 15 ether);
        vm.prank(user1);
        bank.deposit{value: 15 ether}();
        
        // 用户2存款达到阈值
        vm.prank(user2);
        bank.approve(12 ether);
        vm.deal(user2, 12 ether);
        vm.prank(user2);
        bank.deposit{value: 12 ether}();
        
        uint256 adminBalanceBefore = admin.balance;
        
        // 执行自动化转移
        automation.performUpkeep(abi.encode(user1));
        automation.performUpkeep(abi.encode(user2));
        
        // 验证自动化转移
        assertEq(admin.balance, adminBalanceBefore + 7.5 ether + 6 ether);
        assertEq(bank.balances(user1), 7.5 ether);
        assertEq(bank.balances(user2), 6 ether);
    }

    function testOnlyOwnerCanAddUser() public {
        vm.prank(user1);
        vm.expectRevert("Only owner can call this function");
        automation.addUser(user2);
    }

    function testOnlyOwnerCanRemoveUser() public {
        automation.addUser(user1);
        vm.prank(user1);
        vm.expectRevert("Only owner can call this function");
        automation.removeUser(user1);
    }

    function testOnlyOwnerCanManualTrigger() public {
        automation.addUser(user1);
        vm.prank(user1);
        bank.approve(15 ether);
        vm.deal(user1, 15 ether);
        vm.prank(user1);
        bank.deposit{value: 15 ether}();
        
        vm.prank(user1);
        vm.expectRevert("Only owner can call this function");
        automation.manualTrigger(user1);
    }

    function testEmergencyStop() public {
        // 添加多个用户
        automation.addUser(user1);
        automation.addUser(user2);
        automation.addUser(user3);
        
        // 紧急停止
        automation.emergencyStop();
        
        // 验证所有用户都被移除
        assertFalse(automation.monitoredUsers(user1));
        assertFalse(automation.monitoredUsers(user2));
        assertFalse(automation.monitoredUsers(user3));
        
        address[] memory users = automation.getMonitoredUsers();
        assertEq(users.length, 0);
    }

    function testGetMonitoredUsers() public {
        automation.addUser(user1);
        automation.addUser(user2);
        
        address[] memory users = automation.getMonitoredUsers();
        assertEq(users.length, 2);
        assertEq(users[0], user1);
        assertEq(users[1], user2);
    }

    function testCheckUserUpkeep() public {
        automation.addUser(user1);
        
        // 用户未达到阈值
        vm.prank(user1);
        bank.approve(5 ether);
        vm.deal(user1, 5 ether);
        vm.prank(user1);
        bank.deposit{value: 5 ether}();
        
        assertFalse(automation.checkUserUpkeep(user1));
        
        // 用户达到阈值
        vm.prank(user1);
        bank.approve(10 ether);
        vm.deal(user1, 10 ether);
        vm.prank(user1);
        bank.deposit{value: 10 ether}();
        
        assertTrue(automation.checkUserUpkeep(user1));
    }
} 