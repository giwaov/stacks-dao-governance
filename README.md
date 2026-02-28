# 🏛️ Stacks DAO Governance

A decentralized proposal voting system built on Stacks blockchain using Clarity smart contracts.

## Features

- **Create Proposals**: Submit governance proposals (0.1 STX fee)
- **Vote on Proposals**: Cast yes/no votes (0.01 STX per vote)
- **On-chain Transparency**: All votes recorded on Stacks mainnet
- **Wallet Integration**: Connect via Hiro Wallet using @stacks/connect

## Tech Stack

- **Smart Contract**: Clarity (Stacks blockchain)
- **Frontend**: Next.js 14 with TypeScript
- **Wallet**: @stacks/connect for wallet integration
- **Transactions**: @stacks/transactions for contract calls

## Deployed Contract

**Mainnet**: `SP3E0DQAHTXJHH5YT9TZCSBW013YXZB25QFDVXXWY.dao-v2`

## Contract Functions

```clarity
;; Create a new proposal
(create-proposal (title (string-utf8 100)))

;; Vote yes on a proposal
(vote-yes (proposal-id uint))

;; Vote no on a proposal  
(vote-no (proposal-id uint))

;; Read-only: Get proposal details
(get-proposal (id uint))
```

## Getting Started

```bash
npm install
npm run dev
```

Open [http://localhost:3000](http://localhost:3000)

## Architecture

```
┌─────────────────┐    ┌─────────────────┐
│   Next.js App   │───▶│  Stacks Wallet  │
│  @stacks/connect│    │  (Hiro/Leather) │
└────────┬────────┘    └─────────────────┘
         │
         ▼
┌─────────────────────────────────────────┐
│         Stacks Blockchain               │
│  ┌───────────────────────────────────┐  │
│  │     dao-v2.clar Contract          │  │
│  │  - Proposals Map                  │  │
│  │  - Votes Tracking                 │  │
│  │  - STX Fee Collection             │  │
│  └───────────────────────────────────┘  │
└─────────────────────────────────────────┘
```

## License

MIT
