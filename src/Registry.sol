// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

contract Registry {
    
    struct UserKeys {
        // Public Keys (Visible to everyone, used by Sender)
        bytes scanPublicKey;  
        bytes spendPublicKey;
        
        // Private Key (Visible to everyone who looks at blockchain data!)
        // In prod: Encrypt this before sending!
        bytes32 encScanPrivateKey; 
        
        bool exists;
    }

    // Mapping: "alice" -> Keys
    mapping(string => UserKeys) private records;

    event Registered(string indexed name, address indexed wallet);

    function register(
        string calldata _name,
        bytes calldata _scanPubKey,
        bytes calldata _spendPubKey,
        bytes32 _scanPrivKey
    ) external {
        require(!records[_name].exists, "Name already taken");
        
        records[_name] = UserKeys({
            scanPublicKey: _scanPubKey,
            spendPublicKey: _spendPubKey,
            encScanPrivateKey: _scanPrivKey,
            exists: true
        });

        emit Registered(_name, msg.sender);
    }

    // Read function for the Sender Page
    function getPublicKeys(string calldata _name) external view returns (bytes memory scanPub, bytes memory spendPub) {
        require(records[_name].exists, "User not found");
        return (records[_name].scanPublicKey, records[_name].spendPublicKey);
    }

    // Read function for Alice (Scanning)
    // In reality, anyone can call this and see the key.
    function getScanPrivateKey(string calldata _name) external view returns (bytes32) {
        require(records[_name].exists, "User not found");
        return records[_name].encScanPrivateKey;
    }
}