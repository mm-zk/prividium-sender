// src/GhostSystem.sol
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";

// --- 1. MOCK BRIDGE ---
contract MockBridge {
    event Bridged(address indexed l2Receiver, address token, uint256 amount);
    function deposit(address _l2Receiver, address _token, uint256 _amount) external payable {
        emit Bridged(_l2Receiver, _token, _amount);
    }
}

// --- 2. GHOST VAULT ---
contract GhostVault {
    using SafeERC20 for IERC20;

    address public immutable BRIDGE;
    address public immutable OWNER;
    uint256 public immutable DESTINATION_CHAIN_ID; // <--- NEW

    error SignatureInvalid();

    constructor(address _bridge, address _owner, uint256 _destChainId) {
        BRIDGE = _bridge;
        OWNER = _owner;
        DESTINATION_CHAIN_ID = _destChainId;
    }

    receive() external payable {}

    // ROLE 1: PUBLIC FORWARDER
    function bridgeToL2(address _token) external {
        // FIX: If we are already on the destination chain, do nothing.
        // The funds should stay here waiting for Alice to sweep them.
        if (block.chainid == DESTINATION_CHAIN_ID) {
            return;
        }

        address targetL2 = address(this);
        
        if (_token == address(0)) {
            uint256 balance = address(this).balance;
            if (balance > 0) {
                MockBridge(BRIDGE).deposit{value: balance}(targetL2, address(0), balance);
            }
        } else {
            uint256 balance = IERC20(_token).balanceOf(address(this));
            if (balance > 0) {
                IERC20(_token).forceApprove(BRIDGE, balance);
                MockBridge(BRIDGE).deposit(targetL2, _token, balance);
            }
        }
    }

    // ROLE 2: PRIVATE SWEEP
    function sweep(address _token, address _recipient, bytes calldata _signature) external {
        // Replay protection: include chainId in the hash
        bytes32 messageHash = keccak256(
            abi.encodePacked(
                "\x19Ethereum Signed Message:\n32",
                keccak256(abi.encodePacked(block.chainid, address(this), _token, _recipient))
            )
        );

        address signer = ECDSA.recover(messageHash, _signature);
        if (signer != OWNER) revert SignatureInvalid();

        if (_token == address(0)) {
            payable(_recipient).transfer(address(this).balance);
        } else {
            IERC20(_token).safeTransfer(_recipient, IERC20(_token).balanceOf(address(this)));
        }
    }
}

// --- 3. GHOST FACTORY ---
contract GhostFactory {
    address public immutable BRIDGE;
    uint256 public immutable DESTINATION_CHAIN_ID; // <--- NEW

    event GhostDeployed(address indexed vault, address indexed owner, bytes ephemeralPublicKey);

    constructor(address _bridge, uint256 _destChainId) {
        BRIDGE = _bridge;
        DESTINATION_CHAIN_ID = _destChainId;
    }

    function deployAndBridge(
        bytes32 _salt, 
        address _owner, 
        address _token, 
        bytes calldata _ephemeralPublicKey
    ) external payable {
        address vault = computeAddress(_salt, _owner);
        
        // 1. Deploy if needed
        if (vault.code.length == 0) {
            // Pass the ChainID to the vault constructor
            new GhostVault{salt: _salt}(BRIDGE, _owner, DESTINATION_CHAIN_ID);
            emit GhostDeployed(vault, _owner, _ephemeralPublicKey);
        }

        // 2. Forward Gas
        if (address(this).balance > 0) {
            payable(vault).transfer(address(this).balance);
        }

        // 3. Bridge (Will skip if we are on L2)
        GhostVault(payable(vault)).bridgeToL2(_token);
    }

    function computeAddress(bytes32 _salt, address _owner) public view returns (address) {
        // Constructor args MUST include the DESTINATION_CHAIN_ID now
        bytes memory bytecode = abi.encodePacked(
            type(GhostVault).creationCode,
            abi.encode(BRIDGE, _owner, DESTINATION_CHAIN_ID)
        );
        bytes32 hash = keccak256(
            abi.encodePacked(bytes1(0xff), address(this), _salt, keccak256(bytecode))
        );
        return address(uint160(uint256(hash)));
    }
}