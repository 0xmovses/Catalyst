const Web3 = require("web3");
const cLand = artifacts.require("cLand");
const CollateralAndMint = artifacts.require("CollateralAndMint");
const LystToken = artifacts.require("LystToken");
const Farm = artifacts.require("Farm");
// Used for Testing purposes only on Rinkeby
// const LandOracle = artifacts.require("LandOracle");
// Kovan deployed contract.
const LandOracle = Web3.utils.toChecksumAddress(
  "0x29B56B6024878aca47B413F79BA597c401134b8D"
);

// BOTH ARE KOVAN
const compAddress = Web3.utils.toChecksumAddress(
  "0x41B5844f4680a8C38fBb695b7F9CFd1F64474a72"
);
const UNISWAP_ROUTER_ADR = Web3.utils.toChecksumAddress(
  "0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D"
);

// // BOTH ARE RINKEBY
// const compAddress = Web3.utils.toChecksumAddress(
//   "0xd6801a1dffcd0a410336ef88def4320d6df1883e"
// );
// const UNISWAP_ROUTER_ADR = Web3.utils.toChecksumAddress(
//   "0x7a250d5630b4cf539739df2c5dacb4c659f2488d"
// );

module.exports = async function(deployer, network, accounts) {
  // Local (development) networks need their own deployment of the LINK
  // token and the Oracle contract
  // await deployer.deploy(LandOracle);
  // const landOracle = await LandOracle.deployed();
  // await landOracle.getLatestManaPrice();
  // await landOracle.ManaPerEth();

  await deployer.deploy(cLand, "Decentraland Land Index", "cLand");
  const cLandToken = await cLand.deployed();

  await deployer.deploy(LystToken, "Catalyst", "LYST");
  const lystToken = await LystToken.deployed();

  // FOR KOVAN
  await deployer.deploy(
    CollateralAndMint,
    cLandToken.address,
    lystToken.address,
    5000,
    LandOracle,
    compAddress,
    UNISWAP_ROUTER_ADR
  );

  // // FOR RINKEBY
  // await deployer.deploy(
  //   CollateralAndMint,
  //   cLandToken.address,
  //   lystToken.address,
  //   6000,
  //   landOracle.address,
  //   compAddress,
  //   UNISWAP_ROUTER_ADR
  // );

  await deployer.deploy(
    Farm,
    lystToken.address,
    "0xeb2198ba8047B20aC84fBfB78af33f5A9690F674",
    "0xeb2198ba8047B20aC84fBfB78af33f5A9690F674",
    "500000000000000000",
    0
  );

  const farm = await Farm.deployed();

  const collateralAndMint = await CollateralAndMint.deployed();

  // Granting Minter role.
  await lystToken.grantRole(
    "0x9f2df0fed2c77648de5860a4cc508cd0818c85b8b8a1ab4ceeef8d981c8956a6",
    farm.address
  );

  // Granting Minter role.
  await cLandToken.grantRole(
    "0x9f2df0fed2c77648de5860a4cc508cd0818c85b8b8a1ab4ceeef8d981c8956a6",
    collateralAndMint.address
  );
};
