# Price Oracle for CoW AMM LP Tokens [![Open in Gitpod][gitpod-badge]][gitpod] [![Github Actions][gha-badge]][gha] [![Foundry][foundry-badge]][foundry] [![License: MIT][license-badge]][license]

[gitpod]: https://gitpod.io/#https://github.com/cowdao-grants/cow-amm-lp-oracle
[gitpod-badge]: https://img.shields.io/badge/Gitpod-Open%20in%20Gitpod-FFB45B?logo=gitpod
[gha]: https://github.com/cowdao-grants/cow-amm-lp-oracle/actions
[gha-badge]: https://github.com/cowdao-grants/cow-amm-lp-oracle/actions/workflows/ci.yml/badge.svg
[foundry]: https://getfoundry.sh/
[foundry-badge]: https://img.shields.io/badge/Built%20with-Foundry-FFDB1C.svg
[license]: https://www.gnu.org/licenses/gpl-3.0
[license-badge]: https://img.shields.io/badge/License-GPLv3-blue.svg

Development of a manipulation-resilient price oracle for CoW AMM LP tokens.

## Getting Started

```sh
$ git clone https://github.com/cowdao-grants/cow-amm-lp-oracle
$ cd cow-amm-lp-oracle
$ bun install
```

### Contract Deployment and Verification

The repository includes pre-configured RPC endpoints for various networks. When deploying contracts using
`forge script`, you can:

1. Specify the network: `--rpc-url <network>` (e.g., `--rpc-url mainnet`)
2. Set your block explorer API key: `export ETHERSCAN_API_KEY=your_api_key`
3. Use the `--verify` flag for contract verification

Supported networks: mainnet, sepolia, gnosis, arbitrum, base, and localhost.

For detailed information about contract deployment and verification, see the
[Foundry Book](https://book.getfoundry.sh/reference/forge/forge-script).

### VSCode Integration

It is recommended to use VSCode with the Nomic Foundation's
[Solidity extension](https://marketplace.visualstudio.com/items?itemName=NomicFoundation.hardhat-solidity).

For guidance on how to integrate a Foundry project in VSCode, please refer to this
[guide](https://book.getfoundry.sh/config/vscode).

### GitHub Actions

This project uses GitHub Actions for continuous integration (CI). On every push and pull request made to the main
branch, the contracts will be linted, built, and tested.

The CI workflow configuration can be found and modified in [.github/workflows/ci.yml](./.github/workflows/ci.yml).

## Acknowledgements

[PaulRBerg/foundry-template](https://github.com/PaulRBerg/foundry-template)

## License

This project is licensed under the GNU General Public License v3.0 (GPL-3.0).
