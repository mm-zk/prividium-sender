// script/Deploy.s.sol
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Script.sol";
import "../src/GhostSystem.sol";
import "../src/Registry.sol";

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

        
        // 3. Deploy Factory (Targeting Localhost 31337 as the destination)
        uint256 destChainId = 31337; 
        GhostFactory factory = new GhostFactory(address(bridge), destChainId);
        console.log("GhostFactory deployed at:", address(factory));

        
        // 4. Deploy Registry
        Registry registry = new Registry();
        console.log("Registry deployed at:", address(registry));

        registry.register(
            "alice",
            hex"0463f43e6f15321d0fb948b671854e2a5e22846cbaf1b470cd4a48fdc58c16953d73d1daa878b2e8b8ea575cfab361179f7ad70e3afe3a6d324417cd989fabd604",
            hex"046105145a889d8d9007523c0583191aacf7f1dc79de54f4554d5172c23aea864c2409d6056430e617c84d34ff8c1c770bdfdb8c4e118fb0fa776f8b3ccb6e1154",
            hex"bb9362aac533bf644933449cd9c0685ec275e1537075ed98e14da4ebfab557d9"
        );

        vm.stopBroadcast();
    }
}