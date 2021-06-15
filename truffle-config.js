const HDWalletProvider = require("@truffle/hdwallet-provider");
require("dotenv").config();

const mnemonic = process.env.MNEMONIC;
const url_rinkeby = process.env.RINKEBY_RPC_URL;
const url_kovan = process.env.KOVAN_RPC_URL;
const ethscanapi = process.env.ETHERSCAN_API_KEY;

module.exports = {
  networks: {
    cldev: {
      host: "127.0.0.1",
      port: 8545,
      network_id: "*",
    },
    ganache: {
      host: "127.0.0.1",
      port: 7545,
      network_id: "*",
    },
    rinkeby: {
      provider: () => {
        return new HDWalletProvider(mnemonic, url_rinkeby);
      },
      network_id: "4",
      skipDryRun: true,
    },
    kovan: {
      provider: () => {
        return new HDWalletProvider(mnemonic, url_kovan);
      },
      network_id: "42",
      skipDryRun: true,
    },
  },
  compilers: {
    solc: {
      version: "0.8.0",
    },
  },
  api_keys: {
    etherscan: ethscanapi,
  },
  plugins: ["truffle-plugin-verify"],
};
