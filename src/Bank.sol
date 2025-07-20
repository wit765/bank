// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

contract Bank {
    // 管理员地址
    address public admin;
    
    // 记录每个地址的存款金额
    mapping(address => uint256) public balances;
    
    // 存款排行榜（前3名）
    address[3] public topDepositors;
    
    // 事件
    event Deposited(address indexed user, uint256 amount);
    event Withdrawn(address indexed admin, uint256 amount);
    
    // 构造函数，设置管理员
    constructor() {
        admin = msg.sender;
    }
    
    // 接收ETH的fallback函数（支持Metamask直接转账）
    receive() external payable {
        deposit();
    }
    
    // 存款函数（也可通过直接转账触发）
    function deposit() public payable {
        require(msg.value > 0, "Deposit amount must be greater than 0");
        
        // 更新用户余额
        balances[msg.sender] += msg.value;
        
        // 更新存款排行榜
        updateTopDepositors(msg.sender, balances[msg.sender]);
        
        emit Deposited(msg.sender, msg.value);
    }
    
    // 仅管理员可调用的提款函数
    function withdraw(uint256 amount) external {
        require(msg.sender == admin, "Only admin can withdraw");
        require(amount <= address(this).balance, "Insufficient contract balance");
        
        payable(admin).transfer(amount);
        emit Withdrawn(admin, amount);
    }
    
    // 更新存款排行榜
    function updateTopDepositors(address user, uint256 newBalance) private {
        // 检查是否已在前3名中
        bool alreadyInTop = false;
        for (uint i = 0; i < 3; i++) {
            if (topDepositors[i] == user) {
                alreadyInTop = true;
                break;
            }
        }
        
        // 如果不在前3名中，检查是否能进入
        if (!alreadyInTop) {
            for (uint i = 0; i < 3; i++) {
                if (newBalance > balances[topDepositors[i]] || topDepositors[i] == address(0)) {
                    // 插入到当前位置，后面的依次后移
                    for (uint j = 2; j > i; j--) {
                        topDepositors[j] = topDepositors[j-1];
                    }
                    topDepositors[i] = user;
                    break;
                }
            }
        } else {
            // 如果已在榜单中，重新排序
            sortTopDepositors();
        }
    }
    
    // 对排行榜进行排序
    function sortTopDepositors() private {
        for (uint i = 0; i < 2; i++) {
            for (uint j = 0; j < 2 - i; j++) {
                if (balances[topDepositors[j]] < balances[topDepositors[j+1]]) {
                    address temp = topDepositors[j];
                    topDepositors[j] = topDepositors[j+1];
                    topDepositors[j+1] = temp;
                }
            }
        }
    }
    
    // 获取合约总余额
    function getContractBalance() public view returns (uint256) {
        return address(this).balance;
    }
}      
