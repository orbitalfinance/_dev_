## 1. Foundry

**Foundry is a blazing fast, portable and modular toolkit for Ethereum application development written in Rust.**

Foundry consists of:

- **Forge**: Ethereum testing framework (like Truffle, Hardhat and DappTools).
- **Cast**: Swiss army knife for interacting with EVM smart contracts, sending transactions and getting chain data.
- **Anvil**: Local Ethereum node, akin to Ganache, Hardhat Network.
- **Chisel**: Fast, utilitarian, and verbose solidity REPL.

## 2. Documentation

<https://book.getfoundry.sh/>

## 3. Usage

### 3.1. Build

```shell
forge build
```

### 3.2. Test

```shell
forge test
```

### 3.3. Format

```shell
forge fmt
```

### 3.4. Gas Snapshots

```shell
forge snapshot
```

### 3.5. Anvil

```shell
anvil
```

### 3.6. Deploy

```shell
forge script script/Counter.s.sol:CounterScript --rpc-url <your_rpc_url> --private-key <your_private_key>
```

### 3.7. Cast

```shell
cast <subcommand>
```

### 3.8. Help

```shell
forge --help
anvil --help
cast --help
```
