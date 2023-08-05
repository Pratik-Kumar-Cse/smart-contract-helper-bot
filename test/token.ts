import { expect } from "chai";
import { ethers } from "hardhat";
import { LNQToken } from "../typechain/LNQToken";

describe("LNQToken", () => {
  let lnqToken: LNQToken;
  let owner: any;
  let minter: any;
  let recipient: any;

  before(async () => {
    [owner, minter, recipient] = await ethers.getSigners();
    const LNQTokenFactory = await ethers.getContractFactory("LNQToken", owner);
    lnqToken = (await LNQTokenFactory.deploy()) as LNQToken;
    await lnqToken.deployed();
  });

  it("Should deploy contract and set initial values", async () => {
    expect(await lnqToken.name()).to.equal("LNQToken");
    expect(await lnqToken.symbol()).to.equal("LNQ");
    expect(await lnqToken.decimals()).to.equal(18);
    expect(await lnqToken.totalSupply()).to.equal(0);
    expect(await lnqToken.mintable()).to.equal(true);
    expect(await lnqToken.minter()).to.equal(await owner.getAddress());
  });

  it("Should change mintable state by only owner", async () => {
    await lnqToken.changeMintable(true);
    expect(await lnqToken.mintable()).to.equal(true);
  });

  it("Should not change mintable state by non-owner", async () => {
    await expect(lnqToken.connect(minter).changeMintable(false)).to.be.revertedWith(
      "Ownable: caller is not the owner"
    );
  });

  it("Should set minter address by only owner", async () => {
    await lnqToken.setMinter(await minter.getAddress());
    expect(await lnqToken.minter()).to.equal(await minter.getAddress());
  });

  it("Should not set minter address by non-owner", async () => {
    await expect(lnqToken.connect(minter).setMinter(await owner.getAddress())).to.be.revertedWith(
      "Ownable: caller is not the owner"
    );
  });

  context("Minting", () => {
    beforeEach(async () => {
      await lnqToken.changeMintable(true);
      await lnqToken.setMinter(await minter.getAddress());
    });

    it("Should mint tokens by only minter", async () => {
      const amount = ethers.utils.parseEther("100");
      await lnqToken.connect(minter).mint(await recipient.getAddress(), amount);
      expect(await lnqToken.balanceOf(await recipient.getAddress())).to.equal(amount);
      expect(await lnqToken.totalSupply()).to.equal(amount);
    });

    it("Should not mint tokens by non-minter", async () => {
      await expect(lnqToken.connect(owner).mint(await recipient.getAddress(), ethers.utils.parseEther("100"))).to.be.revertedWith(
        "LNQToken: only minter can mint"
      );
    });

    it("Should not mint tokens when mintable is false", async () => {
      await lnqToken.changeMintable(false);
      await expect(lnqToken.connect(minter).mint(await recipient.getAddress(), ethers.utils.parseEther("100"))).to.be.revertedWith(
        "LNQToken: not mintable"
      );
    });
  });

  context("Burning", () => {
    beforeEach(async () => {
      await lnqToken.changeMintable(true);
      await lnqToken.setMinter(await minter.getAddress());
      await lnqToken.connect(minter).mint(await recipient.getAddress(), ethers.utils.parseEther("100"));
    });

    it("Should burn tokens by owner", async () => {
      const amount = ethers.utils.parseEther("50");
      await lnqToken.connect(recipient).burn(amount);
      expect(await lnqToken.balanceOf(await recipient.getAddress())).to.equal(ethers.utils.parseEther("50"));
      expect(await lnqToken.totalSupply()).to.equal(ethers.utils.parseEther("50"));
    });

    it("Should not burn tokens by non-owner", async () => {
      await expect(lnqToken.connect(minter).burn(ethers.utils.parseEther("50"))).to.be.revertedWith(
        "PlayToken: balance is low to burn"
      );
    });

    it("Should burn tokens from approved address", async () => {
      const amount = ethers.utils.parseEther("25");
      await lnqToken.approve(await minter.getAddress(), amount);
      await lnqToken.connect(minter).burnFrom(await recipient.getAddress(), amount);
      expect(await lnqToken.balanceOf(await recipient.getAddress())).to.equal(ethers.utils.parseEther("75"));
      expect(await lnqToken.totalSupply()).to.equal(ethers.utils.parseEther("75"));
    });

    it("Should not burn tokens when allowance is low", async () => {
      await lnqToken.approve(await minter.getAddress(), ethers.utils.parseEther("10"));
      await expect(lnqToken.connect(minter).burnFrom(await recipient.getAddress(), ethers.utils.parseEther("50"))).to.be.revertedWith(
        "ERC20: transfer amount exceeds allowance"
      );
    });
  });
});