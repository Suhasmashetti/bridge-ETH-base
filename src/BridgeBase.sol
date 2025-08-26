// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/access/Ownable.sol";

interface IMSuhas {
    function mint(address to, uint256 amount) external;
    function burnFromBridge(address account, uint256 amount) external;
}

contract BridgeBase is Ownable {
    IMSuhas public mSuhas;

    event Minted(address indexed to, uint256 amount, address indexed triggeredBy);
    event Burned(address indexed from, uint256 amount, address indexed toOnL1);

    constructor(address _mSuhas) {
        require(_mSuhas != address(0), "zero mSuhas");
        mSuhas = IMSuhas(_mSuhas);
    }

    /// @notice Relayer/admin mints wrapped tokens on L2 after seeing L1 Lock event
    function mint(address to, uint256 amount) external onlyOwner {
        require(to != address(0), "zero to");
        require(amount > 0, "amount>0");
        mSuhas.mint(to, amount);
        emit Minted(to, amount, msg.sender);
    }

    /// @notice User burns wrapped tokens on L2 to redeem on L1. `toOnL1` is recipient on L1.
    /// BridgeBase will call privileged burn on token contract to avoid approvals.
    function burn(uint256 amount, address toOnL1) external {
        require(toOnL1 != address(0), "invalid to");
        require(amount > 0, "amount>0");

        // burn user's wrapped tokens (the token contract enforces onlyBridge)
        mSuhas.burnFromBridge(msg.sender, amount);

        emit Burned(msg.sender, amount, toOnL1);
        // relayer watches this event and will call BridgeEth.release(toOnL1, amount)
    }

    // helper to change token if needed
    function setMSuhas(address _mSuhas) external onlyOwner {
        require(_mSuhas != address(0), "zero");
        mSuhas = IMSuhas(_mSuhas);
    }
}
