require('dotenv').config()
require('@nomiclabs/hardhat-waffle')
require('@nomiclabs/hardhat-etherscan')
require('@nomiclabs/hardhat-ethers')
require('hardhat-tracer')
require('hardhat-log-remover')
require('hardhat-abi-exporter')
require('hardhat-deploy')
require('hardhat-contract-sizer');

const {
  INFURA_API_URL,
  ALCHEMY_API_URL,
  accounts,
  accountsHH,
} = require('./hardhat.secrets')
const chainIds = {
  ropsten: 3,
  testnet: 97,
  mainnet: 56
}

module.exports = {
  defaultNetwork: 'ropsten',
  etherscan: {
    // Your API key for Etherscan
    // Obtain one at https://etherscan.io/
    apiKey: "514SSMF6P7BM1546Z3WBEJR147TT6AJ9IS"
  },
  networks: {
    // hardhat: {
    //   accounts: {
    //     mnemonic: process.env.MNEMONIC
    //   },
    //   saveDeployments: true
    // },
    // localhost: {
    //   url: 'http://127.0.0.1:8545',
    //   accounts: {
    //     mnemonic: process.env.MNEMONIC,
    //     accountsBalance: '100000000000000000000000'
    //   },
    //   saveDeployments: false
    // },
    ropsten: {
      // gas: 'auto',
      // chainId: chainIds.ropsten,
      // url: INFURA_API_URL,
      url: ALCHEMY_API_URL,
      accounts: accounts
    },
    // testnet: {
    //   url: 'https://data-seed-prebsc-2-s3.binance.org:8545/',
    //   chainId: chainIds.testnet,
    //   // accounts: {
    //   //   mnemonic: process.env.MNEMONIC
    //   // },
    //   accounts: [process.env.PRIVATE_KEY],
    //   saveDeployments: true
    // }
    // mainnet: {
    //   url: 'https://bsc-dataseed.binance.org',
    //   chainId: chainIds.mainnet,
    //   accounts: [process.env.PRIVATE_KEY],
    //   saveDeployments: true
    // }
  },
  // etherscan: {
  //   apiKey: process.env.BSCSCAN_APIKEY
  // },
  solidity: {
    version: '0.8.4',
    settings: {
      optimizer: {
        enabled: true,
        runs: 20,
      }
    }
  },
  paths: {
    sources: './contracts',
    tests: './test',
    cache: './cache',
    artifacts: './artifacts',
    deploy: './deploy',
    deployments: './deployments'
  },
  namedAccounts: {
    deployer: {
      default: 0
    }
  },
  abiExporter: {
    path: './abi',
    clear: true,
    flat: true,
    only: [],
    spacing: 2
  },
  contractSizer: {
    alphaSort: true, //whether to sort results table alphabetically (default sort is by contract size) [false]
    disambiguatePaths: true, //whether to output contract sizes automatically after compilation [false]
    runOnCompile: false, //whether to output the full path to the compilation artifact (relative to the Hardhat root directory) [false]
    strict: false, //whether to throw an error if any contracts exceed the size limit [false]
  }
}
