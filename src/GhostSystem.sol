// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";

// --- 1. MOCK BRIDGE (Simulates L1 -> L2) ---
contract MockBridge {
    event Bridged(address indexed l2Receiver, address token, uint256 amount);

    function deposit(address _l2Receiver, address _token, uint256 _amount) external payable {
        emit Bridged(_l2Receiver, _token, _amount);
    }
}

// --- 2. GHOST VAULT (The Twin Contract) ---
contract GhostVault {
    using SafeERC20 for IERC20;

    address public immutable BRIDGE;
    address public immutable OWNER; // The "Stealth Address" owner

    error SignatureInvalid();

    constructor(address _bridge, address _owner) {
        BRIDGE = _bridge;
        OWNER = _owner;
    }

    receive() external payable {}

    // ROLE 1: PUBLIC FORWARDER (Called by Relayer)
    function bridgeToL2(address _token) external {
        address targetL2 = address(this); // Address is same on L2
        
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

    // ROLE 2: PRIVATE SWEEP (Called by Alice on L2)
    function sweep(address _token, address _recipient, bytes calldata _signature) external {
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

    // Emitted so Alice can find her contract. 
    // `ephemeralPublicKey` is the "R" value she needs for ECDH.
    event GhostDeployed(address indexed vault, address indexed owner, bytes ephemeralPublicKey);

    constructor(address _bridge) {
        BRIDGE = _bridge;
    }

    function deployAndBridge(
        bytes32 _salt, 
        address _owner, 
        address _token, 
        bytes calldata _ephemeralPublicKey
    ) external payable {
        // 1. Deploy (Idempotent)
        address vault = computeAddress(_salt, _owner);
        if (vault.code.length == 0) {
            new GhostVault{salt: _salt}(BRIDGE, _owner);
            emit GhostDeployed(vault, _owner, _ephemeralPublicKey);
        }

        // 2. Forward ETH for gas (if any sent by relayer)
        if (address(this).balance > 0) {
            payable(vault).transfer(address(this).balance);
        }

        // 3. Bridge
        GhostVault(payable(vault)).bridgeToL2(_token);
    }

    function computeAddress(bytes32 _salt, address _owner) public view returns (address) {
        bytes memory bytecode = abi.encodePacked(
            type(GhostVault).creationCode,
            abi.encode(BRIDGE, _owner)
        );
        bytes32 hash = keccak256(
            abi.encodePacked(bytes1(0xff), address(this), _salt, keccak256(bytecode))
        );
        return address(uint160(uint256(hash)));
    }
}