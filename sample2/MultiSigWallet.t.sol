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

