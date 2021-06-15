const { assert } = require("chai");

const cLandToken = artifacts.require("cLand");
const CollateralAndMint = artifacts.require("CollateralAndMint");
const LystToken = artifacts.require("LystToken");
const LandOracle = artifacts.require("LandOracle");
const Comp = artifacts.require("Comp");
const UNISWAP_ROUTER_ADR = web3.utils.toChecksumAddress(
  "0x7a250d5630b4cf539739df2c5dacb4c659f2488d"
);

require("chai")
  .use(require("chai-as-promised"))
  .should();

contract("CollateralAndMint", (accounts) => {
  describe("LandOracle Deployment", async () => {
    it("Contract Has been deployed", async () => {
      landOracle = await LandOracle.new();
      assert.equal(landOracle.address !== "", true);
    });

    it("Get Eth Latest Price", async () => {
      EthPrice = await landOracle.getLatestETHPrice();
      assert.equal(EthPrice, 194708712224);
    });

    it("Get Mana Latest Price", async () => {
      ManaPrice = await landOracle.getLatestManaPrice();
      assert.equal(ManaPrice, 998893000000000000);
    });

    it("Get Mana per Eth price Latest Price", async () => {
      ManaPerEthPrice = await landOracle.manaPerEth();
      assert.equal(ManaPerEthPrice, 1944931696795680320000);
    });

    it("Set Oracle Whitelist", async () => {
      await landOracle.setOracleWhitelist(accounts[0], {
        from: accounts[0],
      });
      OracleWhiteList = await landOracle.oracleWhitelisted(accounts[0]);
      assert.equal(OracleWhiteList == true, true);
    });

    it("Request Land Index Mean price in Mana and check for it existance.", async () => {
      await landOracle.requestLandData({
        from: accounts[0],
      });
      landPriceInMana = await landOracle.landPriceInMana();
      assert.equal(landPriceInMana, 51624533333333340000000);
    });

    it("Get Land Mean Sale Price for Last 750 Transactions", async () => {
      await landOracle.landIndexTokenPerEth();
      LandIndexTokenPrice = await landOracle.landIndexTokenPerEth();
      assert.equal(LandIndexTokenPrice, 37674562290713460);
    });

    describe("Comp Deployment", async () => {
      it("Contract Has been deployed", async () => {
        compound = await Comp.new("Comp Eth", "CETH");
        assert.equal(compound.address !== "", true);
      });
    });

    describe("cLandToken Deployment", async () => {
      it("Contract Has been deployed", async () => {
        clandToken = await cLandToken.new("Token", "Tok");
        assert.equal(clandToken.address !== "", true);
      });
    });

    describe("LystToken Deployment", async () => {
      it("Contract Has been deployed", async () => {
        lystToken = await LystToken.new("Decentraland Index", "dLand");
        assert.equal(lystToken.address !== "", true);
      });
    });

    describe("CollateralAndMint Deployment", async () => {
      it("Contract has been deployed", async () => {
        collateralAndMint = await CollateralAndMint.new(
          clandToken.address,
          lystToken.address,
          6000,
          landOracle.address,
          compound.address,
          UNISWAP_ROUTER_ADR
        );
        assert.equal(collateralAndMint.address !== "", true);
      });

      it("Request Land Mean Sale price though proxy", async () => {
        landOracleProxyPrice = await collateralAndMint.landIndexPrice();
        assert.equal(landOracleProxyPrice, 37674562290713460);
      });

      it("Percent for borrow", async () => {
        const collateralRequirementPercentEquals = await collateralAndMint.collateralRequirementPercent();
        assert.equal(collateralRequirementPercentEquals, 6000);
      });

      it("Granting and Checking permission to mint", async () => {
        await clandToken.grantRole(
          "0x9f2df0fed2c77648de5860a4cc508cd0818c85b8b8a1ab4ceeef8d981c8956a6",
          collateralAndMint.address
        );
        assert.equal(
          await clandToken.hasRole(
            "0x9f2df0fed2c77648de5860a4cc508cd0818c85b8b8a1ab4ceeef8d981c8956a6",
            collateralAndMint.address
          ),
          true
        );
      });

      it("Make Eth Deposit. Check Deposited amount", async () => {
        await collateralAndMint.collateralizeEth({
          from: accounts[0],
          value: 1000000000000000000,
        });
        const collateralBalance = await collateralAndMint.collateralBalance(
          accounts[0]
        );
        assert.equal(collateralBalance, 1000000000000000000);
      });

      it("Check balance of Comp Tokens after deposit", async () => {
        const compBalance = await compound.balanceOf(collateralAndMint.address);
        assert.equal(compBalance, 500000000000000000);
      });

      it("Comp Token ETH balance after deposit", async () => {
        const balance = await web3.eth.getBalance(compound.address);
        assert.equal(balance, 1000000000000000000);
      });

      it("CETH balance of user on CollateralAndMint after deposit", async () => {
        const ceth = await collateralAndMint.cETH(accounts[0]);
        assert.equal(ceth, 500000000000000000);
      });

      it("Total CETH balance record of platform on CollateralAndMint after deposit", async () => {
        const cethPlatform = await collateralAndMint.cETHCurrentBalance();
        assert.equal(cethPlatform, 500000000000000000);
      });

      it("Check my Current borrow limit", async () => {
        const currentBorrowLimitEth = await collateralAndMint.currentBorrowLimitEth(
          accounts[0]
        );
        assert.equal(currentBorrowLimitEth, 400000000000000000);
      });

      it("Mint Tokens Maximum to my collateral possibility", async () => {
        await collateralAndMint.mintAsset("15069824916285384", {
          from: accounts[0],
        });
        assert.equal(
          await clandToken.balanceOf(accounts[0]),
          "15069824916285384"
        );
      });

      it("Check new borrow limit after minting!", async () => {
        const currentBorrowLimitEth = await collateralAndMint.currentBorrowLimitEth(
          accounts[0]
        );
        assert.equal(currentBorrowLimitEth, 0);
      });

      it("Should not allow to mint more then the borrow limit", async () => {
        try {
          await collateralAndMint.mintAsset("16069824916285384", {
            from: accounts[0],
          });
          assert.fail("The transaction should have thrown an error");
        } catch (err) {
          assert.include(
            err.message,
            "revert",
            "You are borrowing within your limits if this test didn't pass"
          );
        }
      });

      it("Check borrow limits and Collataral used after borrowing all", async () => {
        const currentBorrowLimitEth = await collateralAndMint.currentBorrowLimitEth(
          accounts[0]
        );
        assert.equal(currentBorrowLimitEth, 0);

        const collateralBalance = await collateralAndMint.collateralBalance(
          accounts[0]
        );
        assert.equal(collateralBalance, 1000000000000000000);

        const collateralUsedEth = await collateralAndMint.collateralUsedEth(
          accounts[0]
        );
        assert.equal(collateralUsedEth, 400000000000000000);
      });

      it("Burn 100% parcially", async () => {
        //  First give unlimited allowance.
        await clandToken.approve(
          collateralAndMint.address,
          "99999999999999999999999"
        );
        await collateralAndMint.burnAsset("5069824916285384", {
          from: accounts[0],
        });
        await collateralAndMint.burnAsset("10000000000000000", {
          from: accounts[0],
        });
        assert.equal(await clandToken.balanceOf(accounts[0]), "0");
      });

      it("Mint 100% and burn 50% of the minted assets", async () => {
        await collateralAndMint.mintAsset("15069824916285384", {
          from: accounts[0],
        });

        await collateralAndMint.burnAsset("7534912458142692", {
          from: accounts[0],
        });

        assert.equal(
          await clandToken.balanceOf(accounts[0]),
          "7534912458142692"
        );
      });

      it("Check borrow limits and Collataral used after burning 50%", async () => {
        const currentBorrowLimitEth = await collateralAndMint.currentBorrowLimitEth(
          accounts[0]
        );

        assert.equal(currentBorrowLimitEth, 200000000000000000);

        const collateralBalance = await collateralAndMint.collateralBalance(
          accounts[0]
        );
        assert.equal(collateralBalance, 1000000000000000000);

        const collateralUsedEth = await collateralAndMint.collateralUsedEth(
          accounts[0]
        );
        assert.equal(collateralUsedEth, 200000000000000000);
      });

      it("Try to withdraw collateral.", async () => {
        try {
          await collateralAndMint.withdrawCollateral("1000000000000000000", {
            from: accounts[0],
          });
          assert.fail("The transaction should have thrown an error");
        } catch (err) {
          assert.include(
            err.message,
            "revert",
            "You should not be able to withdraw everything when you have minted!"
          );
        }

        // if 40% is 0.20 how much is 100%
        // y = x * 100 / p
        try {
          await collateralAndMint.withdrawCollateral("550000000000000000", {
            from: accounts[0],
          });
          assert.fail("The transaction should have thrown an error");
        } catch (err) {
          assert.include(
            err.message,
            "revert",
            "You should not be able to withdraw over the collateral treshold!"
          );
        }

        await collateralAndMint.withdrawCollateral("250000000000000000", {
          from: accounts[0],
        });
      });

      it("Check borrow limits and Collataral used after collateral withdraw", async () => {
        const collateralBalance = await collateralAndMint.collateralBalance(
          accounts[0]
        );
        assert.equal(collateralBalance, 750000000000000000);

        const collateralUsedEth = await collateralAndMint.collateralUsedEth(
          accounts[0]
        );
        assert.equal(collateralUsedEth, 200000000000000000);

        const currentBorrowLimitEth = await collateralAndMint.currentBorrowLimitEth(
          accounts[0]
        );
        assert.equal(currentBorrowLimitEth, 100000000000000000);
      });

      it("Check balance of Comp Tokens balance of CollateralAndMint after withdraw", async () => {
        const compBalance = await compound.balanceOf(collateralAndMint.address);
        assert.equal(compBalance, 375000000000000000);
      });

      it("Comp Token ETH balance after withdraw", async () => {
        const balance = await web3.eth.getBalance(compound.address);
        assert.equal(balance, 750000000000000000);
      });

      it("CETH balance of user on CollateralAndMint after withdraw", async () => {
        const ceth = await collateralAndMint.cETH(accounts[0]);
        assert.equal(ceth, 375000000000000000);
      });
    });

    describe("Add collateral and withdraw from different accounts", async () => {
      it("Testing Math for CETH movement", async () => {
        await collateralAndMint.collateralizeEth({
          from: accounts[1],
          value: 1000000000000000000,
        });

        await collateralAndMint.collateralizeEth({
          from: accounts[2],
          value: 1000000000000000000,
        });

        await collateralAndMint.withdrawCollateral("1000000000000000000", {
          from: accounts[1],
        });
        await collateralAndMint.withdrawCollateral("1000000000000000000", {
          from: accounts[2],
        });

        const balance = await web3.eth.getBalance(compound.address);
        assert.equal(balance, 750000000000000000);
      });
    });
  });
});
