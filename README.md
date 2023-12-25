# ecdsa_motoko

```bash
# Starts the replica, running in the background
dfx start --background

# Deploys your canisters to the replica and generates your candid interface
dfx deploy

dfx canister call ecdsa_motoko_backend test_secp256r11
(true)
dfx canister call ecdsa_motoko_backend test_secp256r12
(true)
```