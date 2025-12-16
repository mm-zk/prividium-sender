// script/Deploy.s.sol
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Script.sol";
import "../src/GhostSystem.sol";

contract DeployScript is Script {
    function run() external {
        // 1. Setup the deployer wallet
        // If running on Anvil default, we use a well-known private key or mnemonic
        // Here we read from environment variable or default to Anvil Account #0
        uint256 deployerPrivateKey = vm.envOr("PRIVATE_KEY", uint256(0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80));

        vm.startBroadcast(deployerPrivateKey);

        // 2. Deploy Bridge
        MockBridge bridge = new MockBridge();
        console.log("MockBridge deployed at:", address(bridge));

        // 3. Deploy Factory
        GhostFactory factory = new GhostFactory(address(bridge));
        console.log("GhostFactory deployed at:", address(factory));

        vm.stopBroadcast();
    }
}