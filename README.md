## Generating keys

cast wallet new

cast wallet public-key --private-key XXX

Then remove '0x' and add '04' and add to registry.json.




SEND FUNDS TO (Ghost Address):
0x7755Db54517660a3961EEb7625a583A4B4895E32
Next Steps for Relayer:

Salt:
0xb0d12c2ef5fdb19c7428545fb08fbe6a1906630f96ebf12b61a9ddad41b27ce1
Owner (Ghost Key):
0xDA6191F82A90e3e5C5c0B727Eb3830c28ca7d174
Ephemeral Public Key (The Clue):
0x0393cdc721fdcea742e1243bf14a017cf008e6e4573eae0cf46da89f3f4fa9386e


Successfully created new keypair.
Address:     0x1d29ee17d5346156313FA5FC9E5C20be18aa22aD
Private key: 0xbb9362aac533bf644933449cd9c0685ec275e1537075ed98e14da4ebfab557d9
➜  zkns git:(master) ✗ cast wallet new
Successfully created new keypair.
Address:     0x9907b78f3f0038190B2a5B2854acaBC2D31034ca
Private key: 0x38c5165043af1893f64403262a85cd9cca869b5afcb7d8aa65c179473b0f3b03



cast send 0x7755Db54517660a3961EEb7625a583A4B4895E32 --value 100 --private-key 0x2a871d0798f97d79848a013d4936a73bf4cc922c825d33c1cf7073dff6d409c6

