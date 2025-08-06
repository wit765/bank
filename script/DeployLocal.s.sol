// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.20;

import "forge-std/Script.sol";
import {Bank} from "../src/Bank.sol";
import {BankAutomation} from "../src/BankAutomation.sol";

contract DeployLocal is Script {
    function run() external {
        // 使用默认账户进行部署
        vm.startBroadcast();

        // 部署Bank合约
        Bank bank = new Bank();
        console.log("Bank contract deployed at:", address(bank));
        console.log("Admin address:", bank.admin());
        console.log("Auto transfer threshold:", bank.autoTransferThreshold());
        
        // 部署BankAutomation合约
        BankAutomation automation = new BankAutomation(payable(address(bank)));
        console.log("BankAutomation contract deployed at:", address(automation));
        
        // 设置自动化合约地址
        bank.setAutomationContract(address(automation));
        console.log("Automation contract set in Bank contract");
        
        // 添加一些示例用户到监控列表
        automation.addUser(0x70997970C51812dc3A010C7d01b50e0d17dc79C8);
        console.log("Example user added to monitoring list");

        vm.stopBroadcast();
        
        console.log("\n=== Deployment Complete ===");
        console.log("Bank contract address:", address(bank));
        console.log("BankAutomation contract address:", address(automation));
        console.log("Admin address:", bank.admin());
        console.log("Auto transfer threshold:", bank.autoTransferThreshold());
    }
} 