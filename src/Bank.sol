// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

contract Bank {
    // 管理员地址
    address public admin;
    
    // 记录每个地址的存款金额
    mapping(address => uint256) public balances;
    
    // 存款排行榜（前3名）
    address[3] public topDepositors;
    
    // Approve机制
    mapping(address => uint256) public approvedAmounts;
    
    // 自动化转移阈值（固定为10 ether）
    uint256 public constant autoTransferThreshold = 10 ether;
    
    // 自动化合约地址
    address public automationContract;
    
    // 事件
    event Deposited(address indexed user, uint256 amount);
    event Withdrawn(address indexed admin, uint256 amount);
    event Approved(address indexed user, uint256 amount);
    event AutoTransfer(address indexed user, uint256 amount);
    event AutomationContractSet(address indexed automationContract);
    
    // 构造函数，设置管理员
    constructor() {
        admin = msg.sender;
    }
    
    // 接收ETH的fallback函数（支持Metamask直接转账）
    receive() external payable {
        // 直接转账时也需要approve
        require(approvedAmounts[msg.sender] >= msg.value, "Amount not approved");
        deposit();
    }
    
    // 设置自动化合约地址（仅管理员）
    function setAutomationContract(address _automationContract) external {
        require(msg.sender == admin, "Only admin can set automation contract");
        automationContract = _automationContract;
        emit AutomationContractSet(_automationContract);
    }
    
    // Approve函数 - 用户需要先approve才能存款
    function approve(uint256 amount) external {
        approvedAmounts[msg.sender] = amount;
        emit Approved(msg.sender, amount);
    }
    
    // 存款函数（需要先approve）
    function deposit() public payable {
        require(msg.value > 0, "Deposit amount must be greater than 0");
        require(approvedAmounts[msg.sender] >= msg.value, "Amount not approved");
        
        // 减少approved金额
        approvedAmounts[msg.sender] -= msg.value;
        
        // 更新用户余额
        balances[msg.sender] += msg.value;
        
        // 更新存款排行榜
        updateTopDepositors(msg.sender, balances[msg.sender]);
        
        emit Deposited(msg.sender, msg.value);
    }
    
    // 自动化转移函数（仅自动化合约可调用）
    function executeAutoTransfer(address user) external {
        require(msg.sender == automationContract, "Only automation contract can call");
        require(balances[user] >= autoTransferThreshold, "Balance below threshold");
        
        uint256 transferAmount = balances[user] / 2;
        balances[user] -= transferAmount;
        
        // 转移给owner
        payable(admin).transfer(transferAmount);
        
        // 重新更新排行榜
        updateTopDepositors(user, balances[user]);
        
        emit AutoTransfer(user, transferAmount);
    }
    
    // 仅管理员可调用的提款函数
    function withdraw(uint256 amount) external {
        require(msg.sender == admin, "Only admin can withdraw");
        require(amount <= address(this).balance, "Insufficient contract balance");
        
        payable(admin).transfer(amount);
        emit Withdrawn(admin, amount);
    }
    
    // 检查用户是否需要自动化转移
    function checkUpkeep(address user) external view returns (bool upkeepNeeded, bytes memory performData) {
        upkeepNeeded = balances[user] >= autoTransferThreshold;
        performData = abi.encode(user);
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
    
    // 获取用户的approved金额
    function getApprovedAmount(address user) public view returns (uint256) {
        return approvedAmounts[user];
    }
}      
