#  Ethereum ↔ Base Token Bridge

This project implements a **cross-chain token bridge** between the Ethereum and Base blockchains. It allows users to **lock tokens on Ethereum**, and receive **wrapped tokens on Base**, and later **burn them on Base** to **release the original tokens back on Ethereum**.

---

##  Architecture Overview

The bridge uses a **Lock-Mint** / **Burn-Release** architecture with a trusted off-chain **relayer**:

-  **Ethereum**: Users lock tokens in a `BridgeETH` contract.
-  **Relayer**: Listens to deposit/burn events and triggers mint/release.
-  **Base**: Users receive or burn wrapped tokens via `BridgeBase`.

---

##  Cross-Chain Workflow

###  Bridging: Ethereum ➝ Base

1. **User deposits tokens on Ethereum**:
   - Calls `deposit(amount, nonce)`
   - Tokens are locked in `BridgeETH`
   - Emits `Deposit` event with `nonce`

2. **Relayer listens to Deposit event**:
   - Signs and sends tx to Base

3. **Relayer mints wrapped tokens on Base**:
   - Calls `mint(user, amount, nonce)`
   - `BridgeBase` mints wrapped tokens
   - `nonce` is marked to prevent replay

---

###  Bridging Back: Base ➝ Ethereum

1. **User burns wrapped tokens on Base**:
   - Calls `burn(amount, nonce)`
   - Emits `Burned` event with `nonce`

2. **Relayer picks up Burn event**:
   - Sends info to Ethereum

3. **Relayer marks user withdrawable on Ethereum**:
   - Calls `burnedOnOppositeChain(user, amount, nonce)`
   - Adds to user’s `pendingBalance`

4. **User withdraws on Ethereum**:
   - Calls `withdraw(amount)`
   - Original tokens are released from `BridgeETH`

---

##  Replay Attack Prevention

All cross-chain actions include a `nonce` (unique ID) to prevent replay attacks:

```solidity
require(!processedNonces[nonce], "Nonce already used");
processedNonces[nonce] = true;
