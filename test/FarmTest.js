const { assert } = require("chai");
const Farm = artifacts.require("Farm");
const ProperlyToken = artifacts.require("ProperlyToken");

contract("FarmTest", (accounts) => {
  describe("ProperlyToken Deployment", async () => {
    it("Contract Has been deployed", async () => {
      protocolToken = await ProperlyToken.new("Decentraland Index", "dLand");
      assert.equal(protocolToken.address !== "", true);
    });
  });

  describe("Farm Deployment", async () => {
    it("Contract Has been deployed", async () => {
      farm = await Farm.new(
        protocolToken.address,
        accounts[0],
        accounts[0],
        "100000000000000",
        0
      );
      assert.equal(farm.address !== "", true);
    });

    describe("Update Emission Rate", async () => {
      it("Update and Check", async () => {
        await farm.updateEmissionRate(1000000000000000);
        assert.equal(await farm.dpiPerBlock(), "1000000000000000");
      });
    });

    describe("Grant the rights for minting Protocol Tokens", async () => {
      it("Grand rights and test for rights.", async () => {
        await protocolToken.grantRole(
          "0x9f2df0fed2c77648de5860a4cc508cd0818c85b8b8a1ab4ceeef8d981c8956a6",
          farm.address
        );
        assert.equal(
          await protocolToken.hasRole(
            "0x9f2df0fed2c77648de5860a4cc508cd0818c85b8b8a1ab4ceeef8d981c8956a6",
            farm.address
          ),
          true
        );
      });
    });

    describe("Create a farming pool", async () => {
      it("Add pool and check it's existance.", async () => {
        assert.equal(await farm.poolLength(), 0);

        await farm.add(100, protocolToken.address, 0, true);
        assert.equal(await farm.poolLength(), 1);
      });
    });

    describe("Deposit in the farm", async () => {
      it("Minting Protocol tokens assents and making a deposit", async () => {
        await protocolToken.mint(accounts[1], "10000000000000000");
        await protocolToken.approve(farm.address, "1000000000000000000", {
          from: accounts[1],
        });
        await farm.deposit(0, "0");
        assert.equal(await protocolToken.balanceOf(farm.address), "0");
      });
    });

    describe("Deposit in the farm", async () => {
      it("Minting Protocol tokens assents and making a deposit", async () => {
        await farm.deposit(0, "10000000000000000", {
          from: accounts[1],
        });
        assert.equal(
          await protocolToken.balanceOf(farm.address),
          "10000000000000000"
        );
      });
    });

    describe("Testing Farm reward mechanism", async () => {
      it("Withdrawing Rewards", async () => {
        // Before withdrawing rewards.
        assert.equal(await protocolToken.balanceOf(accounts[1]), 0);
        await farm.deposit(0, "0", {
          from: accounts[1],
        });
        // 1 block mined + withdrawing rewards.
        assert.equal(
          await protocolToken.balanceOf(accounts[1]),
          1000000000000000
        );
      });
    });

    describe("Testing Pending rewards", async () => {
      it("Rewards after every block mined.", async () => {
        // Function to progress one block forward.
        await farm.setFeeAddress(accounts[2]);
        assert.equal(await farm.pendingDPI(0, accounts[1]), "1000000000000000");
      });
    });

    describe("Testing withdraw", async () => {
      it("Withdrawing staked assets", async () => {
        // Before withdrawing rewards.
        await farm.withdraw(0, "10000000000000000", {
          from: accounts[1],
        });

        // 2 block mined + withdrawing rewards.

        await protocolToken
          .balanceOf(accounts[1])
          .then((c) => console.log(c.toString()));
        assert.equal(
          await protocolToken.balanceOf(accounts[1]),
          13000000000000000
        );
      });
    });
  });
});
