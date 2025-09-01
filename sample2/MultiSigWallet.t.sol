const { expect } = require("chai");
const { ethers } = require("hardhat");

describe("MultiSigWallet", function () {
    let MultiSigWallet;
    let multiSigWallet;
    let owners;
    let requiredConfirmations;

    // Hook to run before each test
    beforeEach(async function () {
        // Get signers
        [owner1, owner2, owner3, nonOwner] = await ethers.getSigners();
        owners = [owner1.address, owner2.address, owner3.address];
        requiredConfirmations = 2;

        // Deploy the contract
        MultiSigWallet = await ethers.getContractFactory("MultiSigWallet");
        multiSigWallet = await MultiSigWallet.deploy(owners, requiredConfirmations);
    });

    // 1. Test Deployment and Initialization
    describe("Deployment", function () {
        it("should set the correct owners", async function () {
            const contractOwners = await multiSigWallet.getOwners();
            expect(contractOwners).to.have.members(owners);
        });

        it("should set the correct required confirmations", async function () {
            expect(await multiSigWallet.requiredConfirmations()).to.equal(requiredConfirmations);
        });

        it("should fail deployment with zero owners", async function () {
            await expect(MultiSigWallet.deploy([], requiredConfirmations)).to.be.revertedWith(
                "MultiSigWallet: Owners required"
            );
        });

        it("should fail deployment with invalid required confirmations", async function () {
            await expect(MultiSigWallet.deploy(owners, 0)).to.be.revertedWith(
                "MultiSigWallet: Invalid number of required confirmations"
            );
            await expect(MultiSigWallet.deploy(owners, owners.length + 1)).to.be.revertedWith(
                "MultiSigWallet: Invalid number of required confirmations"
            );
        });
    });

    // 2. Test Transaction Submission
    describe("submitTransaction", function () {
        it("should allow an owner to submit a transaction", async function () {
            const to = nonOwner.address;
            const value = ethers.parseEther("1.0");
            const data = "0x";

            await expect(multiSigWallet.connect(owner1).submitTransaction(to, value, data))
                .to.emit(multiSigWallet, "TransactionSubmitted")
                .withArgs(0, owner1.address, to, value, data);
