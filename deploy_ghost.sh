export FACTORY=0xe7f1725E7734CE288F8367e1Bb143E90bb3F0512
export SALT=0xb0d12c2ef5fdb19c7428545fb08fbe6a1906630f96ebf12b61a9ddad41b27ce1
export OWNER=0xDA6191F82A90e3e5C5c0B727Eb3830c28ca7d174
export EPHEMERAL_KEY=0x0393cdc721fdcea742e1243bf14a017cf008e6e4573eae0cf46da89f3f4fa9386e
export TOKEN=0x0000000000000000000000000000000000000000 # 0x0 for ETH

# 2. Call the Factory to Deploy & Bridge
# We use a random private key for the Relayer (Alice doesn't pay for this)
cast send $FACTORY \
  "deployAndBridge(bytes32,address,address,bytes)" \
  $SALT $OWNER $TOKEN $EPHEMERAL_KEY \
  --private-key 0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80 \
  --rpc-url http://127.0.0.1:8545