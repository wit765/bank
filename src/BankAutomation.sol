// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "./Bank.sol";

// 自动化接口
interface IAutomationCompatible {
    function checkUpkeep(bytes calldata checkData) external view returns (bool upkeepNeeded, bytes memory performData);
    function performUpkeep(bytes calldata performData) external;
}

contract BankAutomation is IAutomationCompatible {
    Bank public bank;
    address public owner;
    
    // 存储需要监控的用户地址
    mapping(address => bool) public monitoredUsers;
    address[] public userList;
    
    event UserAdded(address indexed user);
    event UserRemoved(address indexed user);
    event AutoTransferExecuted(address indexed user, uint256 amount);
    
    constructor(address payable _bank) {
        bank = Bank(_bank);
        owner = msg.sender;
    }
    
    modifier onlyOwner() {
        require(msg.sender == owner, "Only owner can call this function");
        _;
    }
    
    // 添加需要监控的用户
    function addUser(address user) external onlyOwner {
        require(!monitoredUsers[user], "User already monitored");
        monitoredUsers[user] = true;
        userList.push(user);
        emit UserAdded(user);
    }
    
    // 移除监控的用户
    function removeUser(address user) external onlyOwner {
        require(monitoredUsers[user], "User not monitored");
        monitoredUsers[user] = false;
        
        // 从userList中移除
        for (uint i = 0; i < userList.length; i++) {
            if (userList[i] == user) {
                userList[i] = userList[userList.length - 1];
                userList.pop();
                break;
            }
        }
        
        emit UserRemoved(user);
    }
    
    // 自动化接口: 检查是否需要执行
    function checkUpkeep(
        bytes calldata /* checkData */
    ) external view override returns (bool upkeepNeeded, bytes memory performData) {
        upkeepNeeded = false;
        performData = "";
        
        // 检查所有监控的用户
        for (uint i = 0; i < userList.length; i++) {
            address user = userList[i];
            if (monitoredUsers[user]) {
                (bool needsUpkeep, bytes memory data) = bank.checkUpkeep(user);
                if (needsUpkeep) {
                    upkeepNeeded = true;
                    performData = data;
                    break;
                }
            }
        }
    }
    
    // 自动化接口: 执行自动化操作
    function performUpkeep(bytes calldata performData) external override {
        address user = abi.decode(performData, (address));
        
        // 验证用户确实需要自动化转移
        require(monitoredUsers[user], "User not monitored");
        (bool needsUpkeep,) = bank.checkUpkeep(user);
        require(needsUpkeep, "No upkeep needed");
        
        // 执行自动化转移
        bank.executeAutoTransfer(user);
        
        emit AutoTransferExecuted(user, bank.autoTransferThreshold() / 2);
    }
    
    // 获取所有监控的用户
    function getMonitoredUsers() external view returns (address[] memory) {
        return userList;
    }
    
    // 检查特定用户是否需要自动化转移
    function checkUserUpkeep(address user) external view returns (bool) {
        if (!monitoredUsers[user]) return false;
        (bool needsUpkeep,) = bank.checkUpkeep(user);
        return needsUpkeep;
    }
    
    // 紧急停止功能
    function emergencyStop() external onlyOwner {
        // 清空所有监控用户
        for (uint i = 0; i < userList.length; i++) {
            monitoredUsers[userList[i]] = false;
        }
        delete userList;
    }
    
    // 手动触发自动化转移（用于测试）
    function manualTrigger(address user) external onlyOwner {
        require(monitoredUsers[user], "User not monitored");
        (bool needsUpkeep,) = bank.checkUpkeep(user);
        require(needsUpkeep, "No upkeep needed");
        
        bank.executeAutoTransfer(user);
        
        emit AutoTransferExecuted(user, bank.autoTransferThreshold() / 2);
    }
} 