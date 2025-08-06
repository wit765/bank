# Bank Contract with Chainlink Automation

A decentralized bank contract with automated fund transfer functionality using Chainlink Automation.

## Features

- **Approve Mechanism**: Users must approve their deposit amount before depositing
- **Automated Transfer**: When a user's balance exceeds 10 ETH, half is automatically transferred to the admin
- **Top Depositors**: Maintains a leaderboard of top 3 depositors
- **Admin Controls**: Only admin can withdraw funds and manage automation settings

## Contract Addresses (Sepolia Testnet)

- **Bank Contract**: `0x45f01A021841f1cEe27664db3FB0E2DBC76dB7F9`
- **BankAutomation Contract**: `0x267685E78057205A9786690Fc53bf0f31824a1cF`
- **Admin Address**: `0x127BBf091aA8908bb0017795CdF350De6C3E6F8b`

## Smart Contracts

### Bank.sol
Main bank contract with the following functions:
- `deposit()`: Deposit ETH (requires prior approval)
- `approve(uint256 amount)`: Approve deposit amount
- `withdraw(uint256 amount)`: Admin-only withdrawal
- `executeAutoTransfer(address user)`: Automated transfer function
- `checkUpkeep(address user)`: Check if automation is needed

### BankAutomation.sol
Automation contract that monitors users and executes transfers:
- `addUser(address user)`: Add user to monitoring list
- `removeUser(address user)`: Remove user from monitoring list
- `checkUpkeep()`: Chainlink Automation interface
- `performUpkeep()`: Execute automated transfers
- `manualTrigger(address user)`: Manual trigger for testing

## Installation

```bash
# Clone the repository
git clone <repository-url>
cd bank

# Install dependencies
forge install

# Build contracts
forge build
```

## Testing

```bash
# Run all tests
forge test

# Run specific test
forge test --match-test testApproveAndDeposit

# Run tests with verbose output
forge test -vv
```

## Deployment

### Prerequisites
1. Set up environment variables:
   ```bash
   export PRIVATE_KEY="0xyour_private_key_here"
   export RPC_URL="https://sepolia.infura.io/v3/your_api_key"
   ```

2. Get Sepolia testnet ETH from faucets:
   - [Infura Faucet](https://www.infura.io/faucet/sepolia)
   - [Alchemy Faucet](https://sepoliafaucet.com/)

### Deploy to Sepolia
```bash
forge script script/DeployBank.s.sol --rpc-url $RPC_URL --broadcast --verify
```

## Usage

### For Users
1. **Approve Deposit**: Call `approve(amount)` with the amount you want to deposit
2. **Deposit**: Call `deposit()` with the ETH amount
3. **Check Balance**: Use `balances(address)` to check your balance

### For Admin
1. **Withdraw**: Call `withdraw(amount)` to withdraw ETH
2. **Set Automation**: Use `setAutomationContract(address)` to set automation contract
3. **Monitor Users**: Add users to automation monitoring list

### For Automation
1. **Add Users**: Call `addUser(address)` on automation contract
2. **Monitor**: Automation will automatically check and execute transfers
3. **Manual Trigger**: Use `manualTrigger(address)` for testing

## Security Features

- **Approve Mechanism**: Prevents unauthorized deposits
- **Admin Controls**: Restricted withdrawal to admin only
- **Automation Security**: Only automation contract can execute transfers
- **Threshold Protection**: Transfers only occur when balance exceeds 10 ETH

## Network Support

- **Testnet**: Sepolia (Deployed)
- **Mainnet**: Ethereum (Ready for deployment)

## License

MIT License

## Contributing

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Add tests
5. Submit a pull request

## Support

For questions or issues, please open an issue on GitHub.
