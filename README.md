# 🎲 Decentralized Raffle (Foundry)

A decentralized lottery built with Solidity and Foundry, integrating Chainlink VRF for verifiable randomness and designed with a test-driven approach.

## ✨ Features

- Players can enter the raffle by paying the entrance fee.
- Automatic validation of minimum entry fee.
- Time-based raffle interval.
- Chainlink Automation (`checkUpkeep` & `performUpkeep`) integration.
- Chainlink VRF V2 for provably fair winner selection.
- Automatic prize distribution to the winner.
- Raffle state resets for the next round.

## 🧪 Testing

Comprehensive unit tests written using Foundry covering:

- Entrance fee validation
- Player registration
- Event emission
- Time interval logic (`vm.warp`)
- Upkeep conditions
- `performUpkeep()` execution
- Chainlink VRF callback simulation using `VRFCoordinatorV2Mock`
- Winner selection
- Prize transfer
- Raffle reset after completion

## 📊 Current Test Coverage

- **Lines:** ~90%
- **Statements:** ~92%
- **Functions:** ~86%

## 🛠 Tech Stack

- Solidity
- Foundry
- Chainlink VRF V2
- Chainlink Automation
- Forge Standard Library

---

Currently deployed and tested on a local Anvil environment. Sepolia deployment coming soon.