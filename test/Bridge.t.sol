// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.20;

import "forge-std/Test.sol";
import "../src/SuhasToken.sol";
import "../src/MSuhasToken.sol";
import "../src/BridgeEth.sol";
import "../src/BridgeBase.sol";

contract BridgeTest is Test {
    SuhasToken suhasToken;
    MSuhasToken mSuhasToken;
    BridgeEth bridgeEth;
    BridgeBase bridgeBase;

    address user = address(0xBEEF);
    address relayer = address(0xCAFE);

    function setUp() public {
        // Deploy L1 token + bridge
        suhasToken = new SuhasToken(1_000 ether);
        bridgeEth = new BridgeEth(address(suhasToken));

        // Give user some Suhas tokens
        suhasToken.transfer(user, 100 ether);

        // Deploy L2 wrapped token + bridge
        mSuhasToken = new MSuhasToken();
        bridgeBase = new BridgeBase(address(mSuhasToken));

        // Link token <-> bridge
        mSuhasToken.setBridge(address(bridgeBase));

        // Set relayer as owner on both bridges
        bridgeEth.transferOwnership(relayer);
        bridgeBase.transferOwnership(relayer);
    }

    function testLockAndMintFlow() public {
        // User approves + locks tokens on L1
        vm.startPrank(user);
        suhasToken.approve(address(bridgeEth), 50 ether);
        bridgeEth.lock(50 ether, user); // lock 50 for same user on L2
        vm.stopPrank();

        // Relayer sees event and mints on L2
        vm.prank(relayer);
        bridgeBase.mint(user, 50 ether);

        assertEq(mSuhasToken.balanceOf(user), 50 ether, "User should get MSuhas on L2");
        assertEq(suhasToken.balanceOf(address(bridgeEth)), 50 ether, "Bridge should hold locked Suhas");
    }

    function testBurnAndReleaseFlow() public {
        // Setup: simulate prior lock+mint
        vm.startPrank(user);
        suhasToken.approve(address(bridgeEth), 30 ether);
        bridgeEth.lock(30 ether, user);
        vm.stopPrank();

        vm.prank(relayer);
        bridgeBase.mint(user, 30 ether);

        // User burns on L2
        vm.startPrank(user);
        bridgeBase.burn(30 ether, user);
        vm.stopPrank();

        // Relayer sees burn and releases on L1
        vm.prank(relayer);
        bridgeEth.release(user, 30 ether);

        assertEq(suhasToken.balanceOf(user), 30 ether, "User got tokens back on L1");
        assertEq(mSuhasToken.balanceOf(user), 0, "User's L2 tokens burned");
    }
}
