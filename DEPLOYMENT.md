# Bank 合约部署指南

## 1. 环境准备

### 1.1 创建环境变量文件
创建 `.env` 文件并添加以下内容：
```bash
# 部署私钥 - 请替换为你的实际私钥
PRIVATE_KEY=8abf948e865673dd024600ace337b1aa6a6d1904ff14a47b7313c8629810ab9d

# 网络配置
RPC_URL=https://sepolia.infura.io/v3/3c181a9d8a794bb0acb169685ab1faf0
```

### 1.2 获取私钥
- 从 MetaMask 或其他钱包导出私钥
- 确保账户有足够的 ETH 支付 gas 费用

### 1.3 获取 RPC URL
- 可以使用 Alchemy、Infura 等服务
- 对于测试网，推荐使用 Sepolia 测试网

## 2. 部署步骤

### 2.1 编译合约
```bash
forge build
```

### 2.2 部署到测试网
```bash
# 部署到 Sepolia 测试网
forge script script/DeployBank.s.sol --rpc-url $RPC_URL --broadcast --verify

# 或者使用环境变量
forge script script/DeployBank.s.sol --rpc-url $RPC_URL --broadcast --verify --env-file .env
```

### 2.3 部署到主网
```bash
# 部署到以太坊主网
forge script script/DeployBank.s.sol --rpc-url $MAINNET_RPC_URL --broadcast --verify --env-file .env
```

## 3. 部署后的配置

### 3.1 设置自动化合约
部署完成后，需要：
1. 将用户添加到监控列表
2. 注册到 Chainlink Automation 网络

### 3.2 添加用户到监控列表
```javascript
// 使用 ethers.js 或其他库
const automation = new ethers.Contract(automationAddress, automationABI, signer);
await automation.addUser(userAddress);
```

## 4. 合约功能

### 4.1 用户操作
1. **Approve**: 用户需要先 approve 存款金额
2. **Deposit**: 用户存款（需要先 approve）
3. **查看余额**: 查看个人存款余额

### 4.2 管理员操作
1. **Withdraw**: 管理员可以提取合约中的 ETH
2. **设置自动化合约**: 设置自动化合约地址

### 4.3 自动化功能
1. **监控用户**: 自动化合约监控指定用户
2. **自动转移**: 当用户余额超过 10 ETH 时，自动转移一半给管理员

## 5. 安全注意事项

1. **私钥安全**: 永远不要将私钥提交到代码仓库
2. **测试网**: 建议先在测试网部署和测试
3. **Gas 费用**: 确保账户有足够的 ETH 支付部署费用
4. **合约验证**: 部署后记得验证合约代码

## 6. 故障排除

### 6.1 常见错误
- `insufficient funds`: 账户余额不足
- `nonce too low`: 交易 nonce 错误
- `gas limit exceeded`: gas 限制过低

### 6.2 解决方案
- 检查账户余额
- 重置 nonce
- 增加 gas limit

## 7. 合约地址

部署完成后，请记录以下地址：
- Bank 合约地址
- BankAutomation 合约地址
- 管理员地址

这些地址将用于后续的交互和监控。 