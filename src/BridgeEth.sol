// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract BridgeEth is Ownable {
    IERC20 public suhasToken;

    event Locked(address indexed user, uint256 amount, address indexed toOnL2);
    event Released(address indexed to, uint256 amount, address indexed triggeredBy);

    constructor(address _suhasToken) {
        require(_suhasToken != address(0), "zero token");
        suhasToken = IERC20(_suhasToken);
    }

    /// @notice User approves this contract and calls lock to bridge to L2.
    /// `toOnL2` is the recipient address on L2.
    function lock(uint256 amount, address toOnL2) external {
        require(amount > 0, "amount>0");
        require(toOnL2 != address(0), "invalid to");
        // transfer tokens into the bridge contract (escrowed on L1)
        bool ok = suhasToken.transferFrom(msg.sender, address(this), amount);
        require(ok, "transfer failed");

        emit Locked(msg.sender, amount, toOnL2);
        // relayer watches this event and will call BridgeBase.mint(toOnL2, amount)
    }

    /// @notice Relayer / admin calls this after observing a burn on L2 to release tokens
    /// Only owner (set to relayer account) can call release.
    function release(address to, uint256 amount) external onlyOwner {
        require(amount > 0, "amount>0");
        require(to != address(0), "invalid to");
        bool ok = suhasToken.transfer(to, amount);
        require(ok, "transfer failed");
        emit Released(to, amount, msg.sender);
    }
}
