# LongevityBet

![Stacks](https://img.shields.io/badge/Blockchain-Stacks-purple)
![Clarity](https://img.shields.io/badge/Language-Clarity-blue)
![Version](https://img.shields.io/badge/Version-1.0.0-green)

LongevityBet is a synthetic assets smart contract providing exposure to life extension and anti-aging research investments on the Stacks blockchain. The contract allows users to invest in longevity research projects, mint synthetic tokens backed by these investments, and claim rewards based on research milestone achievements.

## 🔬 Features

- **Research Project Creation**: Create and fund longevity research projects with defined milestones
- **Synthetic Token System**: Mint LONG tokens backed by STX investments in research projects
- **Milestone Tracking**: Track research progress through predefined milestones with reward percentages
- **Proportional Rewards**: Burn tokens to claim STX rewards based on research milestone achievements
- **SIP-010 Compliance**: Full fungible token standard implementation for seamless DeFi integration
- **Emergency Controls**: Owner-controlled emergency shutdown functionality
- **Investment Tracking**: Transparent tracking of user investments and token allocations

## 🏗️ Technical Specifications

| Specification | Value |
|---------------|-------|
| **Blockchain** | Stacks |
| **Language** | Clarity |
| **Version** | 1.0.0 |
| **Token Standard** | SIP-010 (Fungible Token) |
| **Token Name** | LongevityBet Token |
| **Token Symbol** | LONG |
| **Decimals** | 6 |
| **Clarity Version** | 2 |
| **Epoch** | 2.5 |

## 📁 Project Structure

```
LongevityBet/
├── LongevityBet_contract/
│   ├── contracts/
│   │   └── LongevityBet.clar       # Main smart contract
│   ├── tests/                      # Test files
│   ├── settings/                   # Configuration files
│   ├── Clarinet.toml              # Clarinet configuration
│   ├── package.json               # Node.js dependencies
│   ├── tsconfig.json             # TypeScript configuration
│   └── vitest.config.js          # Test configuration
└── README.md                      # This file
```

## 🚀 Installation

### Prerequisites

- [Clarinet CLI](https://docs.hiro.so/clarinet) - Smart contract development toolchain
- [Node.js](https://nodejs.org/) (v16 or later) - For running tests
- [Git](https://git-scm.com/) - Version control

### Setup

1. **Clone the repository:**
   ```bash
   git clone <repository-url>
   cd LongevityBet
   ```

2. **Install dependencies:**
   ```bash
   cd LongevityBet_contract
   npm install
   ```

3. **Verify installation:**
   ```bash
   clarinet --version
   clarinet check
   ```

## 🎯 Usage Examples

### Creating a Research Project

```clarity
;; Create a longevity research project
(contract-call? .LongevityBet create-research-project
  "Anti-Aging Compound X"
  u"Research into compound X for cellular regeneration"
  u1000000000  ;; Target: 1000 STX
  (list u"Phase 1: Lab trials" u"Phase 2: Animal testing" u"Phase 3: Human trials")
  (list u25 u35 u40)  ;; Reward percentages for each milestone
)
```

### Investing in Research

```clarity
;; Invest 100 STX in project ID 1
(contract-call? .LongevityBet invest-in-research u1 u100000000)
;; Returns: tokens minted (100 LONG tokens with 6 decimals)
```

### Claiming Rewards

```clarity
;; Burn 50 LONG tokens and claim 25% rewards from project 1
(contract-call? .LongevityBet burn-and-claim u1 u50000000 u25)
;; Returns: STX reward amount claimed
```

## 📖 Contract Functions Documentation

### Public Functions

#### Token Management (SIP-010)

- **`transfer`**: Transfer tokens between principals
- **`get-name`**: Returns token name ("LongevityBet Token")
- **`get-symbol`**: Returns token symbol ("LONG")
- **`get-decimals`**: Returns token decimals (6)
- **`get-balance`**: Get token balance for a principal
- **`get-total-supply`**: Get total token supply
- **`get-token-uri`**: Get token metadata URI

#### Research Project Management

- **`create-research-project`**: Create a new longevity research project
  - Parameters: name, description, target amount, milestone descriptions, milestone rewards
  - Returns: project ID

- **`invest-in-research`**: Invest STX in a research project and mint LONG tokens
  - Parameters: project ID, STX amount
  - Returns: tokens minted
  - Exchange Rate: 1 STX = 1 LONG token

- **`achieve-milestone`**: Mark a research milestone as achieved (creator only)
  - Parameters: project ID, milestone ID
  - Returns: success boolean

- **`burn-and-claim`**: Burn LONG tokens and claim proportional STX rewards
  - Parameters: project ID, token amount, reward percentage
  - Returns: STX reward amount

#### Administrative

- **`emergency-shutdown`**: Activate emergency shutdown (owner only)

### Read-Only Functions

- **`get-research-project`**: Get research project details
- **`get-milestone`**: Get milestone information
- **`get-user-investment`**: Get user's investment in a specific project
- **`get-total-projects`**: Get total number of research projects
- **`get-project-funding-progress`**: Get funding progress percentage for a project

## 🚀 Deployment Guide

### Local Development

1. **Start Clarinet console:**
   ```bash
   cd LongevityBet_contract
   clarinet console
   ```

2. **Deploy locally:**
   ```bash
   clarinet integrate
   ```

### Testnet Deployment

1. **Configure network:**
   ```bash
   clarinet deployment generate --testnet
   ```

2. **Deploy to testnet:**
   ```bash
   clarinet deployment apply --testnet
   ```

### Mainnet Deployment

1. **Prepare mainnet configuration:**
   ```bash
   clarinet deployment generate --mainnet
   ```

2. **Deploy to mainnet:**
   ```bash
   clarinet deployment apply --mainnet
   ```

## 🧪 Testing

Run the test suite to ensure contract functionality:

```bash
# Run all tests
npm test

# Run tests with coverage report
npm run test:report

# Watch mode for development
npm run test:watch
```

## 🛡️ Security Considerations

### Access Controls
- **Project Creation**: Open to all users
- **Investment**: Open to all users during normal operation
- **Milestone Achievement**: Restricted to project creators
- **Emergency Shutdown**: Restricted to contract owner only

### Safety Mechanisms
- **Emergency Shutdown**: Prevents new investments during emergencies
- **Balance Validation**: Ensures sufficient balances before transfers
- **Milestone Validation**: Prevents duplicate milestone achievements
- **Amount Validation**: Prevents zero or invalid amount operations

### Audit Recommendations
- Conduct thorough testing of all mathematical operations
- Verify milestone reward distribution logic
- Test emergency shutdown scenarios
- Validate token minting/burning mechanisms
- Review access control implementations

## 🤝 Investment Model

### Token Economics
- **1:1 Exchange Rate**: 1 STX investment = 1 LONG token minted
- **Proportional Rewards**: Rewards distributed based on token ownership percentage
- **Milestone-Based**: Rewards unlocked only when research milestones are achieved
- **Burn Mechanism**: Users burn LONG tokens to claim their share of rewards

### Risk Factors
- Research projects may not achieve milestones
- Emergency shutdown may halt operations
- Smart contract risks inherent to blockchain technology
- Dependency on project creators to report milestone achievements honestly

## 📊 Contract Constants and Error Codes

### Error Codes
- `u100`: Owner-only operation
- `u101`: Not token owner
- `u102`: Insufficient balance
- `u103`: Invalid amount
- `u104`: Research project not found
- `u105`: Research project already exists
- `u106`: Invalid milestone
- `u107`: Milestone already achieved

### Configuration
- **Token URI**: `https://longevitybet.io/metadata.json`
- **Max Milestones**: 10 per project
- **Token Decimals**: 6 (1 token = 1,000,000 base units)

## 📄 License

[Insert appropriate license information]

## 🤝 Contributing

[Insert contribution guidelines]

## 📞 Contact

[Insert contact information]

---

**⚠️ Disclaimer**: This smart contract involves financial risks. Users should conduct their own research and understand the risks before investing. The success of longevity research projects is not guaranteed, and token values may fluctuate based on research outcomes.