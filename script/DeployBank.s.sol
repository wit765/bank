// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.20;

import "forge-std/Script.sol";
import {Bank} from "../src/Bank.sol";
import {BankAutomation} from "../src/BankAutomation.sol";

contract DeployBank is Script {
    function run() external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        vm.startBroadcast(deployerPrivateKey);

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
        
        // 添加一些示例用户到监控列表（可选）
        // automation.addUser(0x1234567890123456789012345678901234567890);
        // console.log("Example user added to monitoring list");

        vm.stopBroadcast();
    }
} 