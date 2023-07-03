
# Requirements

Foundry : https://github.com/foundry-rs/foundry

# Building Contracts

```bash
forge build
```

# Running tests

```bash
make unit-tests
```

# Test Coverage

```bash
forge coverage
```

# Deployment Process

0) Fill .env file : Deployer PK, RPCs, API keys...

1) Deploy MobulaTokensProtocol
```bash
make deploy-tokens-protocol
```

2) Save the MobulaTokensProtocol address in .env TOKENS_PROTOCOL_ADDRESS

3) Deploy API
```bash
make deploy-protocol-api
```

4) Save the API address in .env PROTOCOL_API_ADDRESS

5) Update API address in MobulaTokensProtocol
```bash
make update-protocol-api
```

6) Deploy Axelar senders (on other blockchains)
```bash
make deploy-axelar-bnb-sender
```

7) Update WhitelistAxelarContracts.s.sol with deployments script for each Axelar senders

8) Whitelist Axelar senders
```bash
make whitelist-axelar-contracts
```

---