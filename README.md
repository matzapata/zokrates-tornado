
# Zokrates starter project

Starter template to create contracts using zero knowledge proofs with zokrates and hardhat

# Contracts instructions

Hardhat commands

```shell
npx hardhat help
npx hardhat test
REPORT_GAS=true npx hardhat test
npx hardhat node
npx hardhat ignition deploy ./ignition/modules/Lock.ts
```

Makefile to work with circuits

```shell
make compile
make proof # default proof inputs
make proof INPUT_A=1 INPUT_B=1 # override proof inputs
```
