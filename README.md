#  GunDrive — Smart Contracts
### Avalanche Build 100 Hackathon Submission

GunDrive is a 2D multiplayer shooter game with full blockchain integration on Avalanche. Players earn tokens, own NFT skins, unlock maps, and stake USDC to compete in real-money matches.

---

##  Live Contracts — Avalanche Fuji Testnet

| Contract | Address |
|---|---|
| ShooterCoin (SHC) | 0xA2214B51Bc444f4A1065f629F3Aac1C4720f040c |
| GameSkins (NFT) | 0xb908522642D6b70E78c674C86cDa516E750e251C |
| StakeToPlay | 0xE4bBd8966D2e833C18F4255AaB1f4DF785c7B5E1 |

---

## Contract Overview

### 1. ShooterCoin.sol (ERC20)
The in-game currency of GunDrive.
- Players earn SHC by winning single player matches
- 5 minute cooldown between rewards prevents farming
- Used to purchase NFT skins in the game shop
- Built on OpenZeppelin ERC20 standard
- Thirdweb ContractMetadata for dashboard management

### 2. GameSkins.sol (ERC1155 NFT)
NFT skins that double as map access keys.
- Players buy skins with SHC tokens or USDC
- Each skin unlocks a unique game map
- Desert Warrior → Desert Map
- Shadow Ghost → Night City Map
- Egyptian King → Egyptian Map
- Soulbound — skins cannot be transferred between wallets
- Unity checks wallet ownership to unlock maps in real time

### 3. StakeToPlay.sol
Competitive stake-based matchmaking with automatic payouts.
- Players stake USDC to enter a match (minimum 1 USDC)
- Supports 2 to 4 players per match
- Total pot locked in contract during the match
- Game server submits final scores after match ends
- Contract automatically distributes rewards:
  - 1st place receives 70% of the total pot
  - 2nd place receives 30% of the total pot
- Reentrancy protected for safe fund distribution
- Cancel function refunds creator if no one joins

---

## Tech Stack

| Layer | Technology |
|---|---|
| Blockchain | Avalanche Fuji Testnet |
| Language | Solidity ^0.8.28 |
| Token Standards | ERC20, ERC1155 |
| Libraries | OpenZeppelin, Thirdweb |
| Development | Remix IDE |
| Dashboard | Thirdweb |
| Game Engine | Unity |
| Multiplayer | Photon Fusion |
| Web3 SDK | Thirdweb Unity SDK v5 |

---

## Security Features

- `onlyOwner` modifier protects admin functions
- Reentrancy protection on all fund distributions
- Soulbound NFTs prevent skin trading exploits
- 5 minute cooldown on token rewards prevents farming
- Struct existence checks prevent ghost match attacks
- approve + transferFrom pattern for all token payments

---

##  How It All Works Together

```
SINGLE PLAYER
Player wins match → calls rewardPlayer() → earns SHC tokens

NFT SHOP
Player spends SHC → buyWithSHC() → NFT minted to wallet
Player clicks map → canAccessMap() → unlocked or blocked

STAKE TO PLAY
Player approves USDC → createMatch() → USDC locked
Opponent approves USDC → joinMatch() → USDC locked
Match plays on Photon Fusion
Game server calls submitScores() → winners paid automatically
```

---

##  Repository Structure

```
gundrive-contracts/
│
├── contracts/
│   ├── ShooterCoin.sol    → ERC20 in-game token
│   ├── GameSkins.sol      → ERC1155 NFT skins
│   └── StakeToPlay.sol    → Stake + payout logic
│
├── deployments/
│   └── addresses.md       → All deployed addresses
│
└── README.md
```

---



---

## Team
- Smart Contract Developer — Ken
- Game Developer — Hyperionß

---

##  Hackathon
Avalanche Build 100 Hackathon
Built on Avalanche Fuji Testnet