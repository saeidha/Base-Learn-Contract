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

            const tx = await multiSigWallet.getTransaction(0);
            expect(tx.destination).to.equal(to);
            expect(tx.value).to.equal(value);
            expect(tx.executed).to.be.false;
        });

        it("should automatically confirm the transaction for the submitter", async function () {
            const to = nonOwner.address;
            const value = ethers.parseEther("1.0");
            const data = "0x";
            await multiSigWallet.connect(owner1).submitTransaction(to, value, data);
            
            expect(await multiSigWallet.isConfirmed(0, owner1.address)).to.be.true;
        });

        it("should fail if a non-owner tries to submit a transaction", async function () {
            const to = nonOwner.address;
            const value = ethers.parseEther("1.0");
            const data = "0x";

            await expect(
                multiSigWallet.connect(nonOwner).submitTransaction(to, value, data)
            ).to.be.revertedWith("MultiSigWallet: Not an owner");
        });
    });

    // 3. Test Transaction Confirmation
    describe("confirmTransaction", function () {
        beforeEach(async function () {
            const to = nonOwner.address;
            const value = ethers.parseEther("1.0");
            const data = "0x";
            await multiSigWallet.connect(owner1).submitTransaction(to, value, data);
        });

        it("should allow another owner to confirm a transaction", async function () {
            await expect(multiSigWallet.connect(owner2).confirmTransaction(0))
                .to.emit(multiSigWallet, "TransactionConfirmed")
                .withArgs(0, owner2.address);

            expect(await multiSigWallet.isConfirmed(0, owner2.address)).to.be.true;
        });

        it("should fail if a non-owner tries to confirm", async function () {
            await expect(multiSigWallet.connect(nonOwner).confirmTransaction(0)).to.be.revertedWith(
                "MultiSigWallet: Not an owner"
            );
        });

        it("should fail if an owner tries to confirm a non-existent transaction", async function () {
            await expect(multiSigWallet.connect(owner1).confirmTransaction(99)).to.be.revertedWith(
                "MultiSigWallet: Transaction does not exist"
            );
        });

        it("should fail if an owner tries to confirm a transaction they already confirmed", async function () {
            await expect(multiSigWallet.connect(owner1).confirmTransaction(0)).to.be.revertedWith(
                "MultiSigWallet: Transaction already confirmed by you"
            );
        });
    });

    // 4. Test Confirmation Revocation
    describe("revokeConfirmation", function () {
        beforeEach(async function () {
            const to = nonOwner.address;
            const value = ethers.parseEther("1.0");
            const data = "0x";
            await multiSigWallet.connect(owner1).submitTransaction(to, value, data); // txIndex 0
            await multiSigWallet.connect(owner2).confirmTransaction(0);
        });

        it("should allow an owner to revoke their confirmation", async function () {
            await expect(multiSigWallet.connect(owner2).revokeConfirmation(0))
                .to.emit(multiSigWallet, "ConfirmationRevoked")
                .withArgs(0, owner2.address);
            
            expect(await multiSigWallet.isConfirmed(0, owner2.address)).to.be.false;
        });

        it("should fail if an owner tries to revoke a confirmation they haven't made", async function () {
             await expect(multiSigWallet.connect(owner3).revokeConfirmation(0)).to.be.revertedWith(
                "MultiSigWallet: You have not confirmed this transaction"
            );
        });

        it("should fail if a non-owner tries to revoke", async function () {
            await expect(multiSigWallet.connect(nonOwner).revokeConfirmation(0)).to.be.revertedWith(
                "MultiSigWallet: Not an owner"
            );
        });
    });

    // 5. Test Transaction Execution
    describe("executeTransaction", function () {
        let to, value, data;
        beforeEach(async function () {
            to = nonOwner.address;
            value = ethers.parseEther("1.0");
            data = "0x";
            
            // Fund the wallet
            await owner1.sendTransaction({
                to: await multiSigWallet.getAddress(),
                value: ethers.parseEther("2.0")
            });

            await multiSigWallet.connect(owner1).submitTransaction(to, value, data);
        });

        it("should fail to execute if confirmations are not met", async function () {
            await expect(multiSigWallet.connect(owner1).executeTransaction(0)).to.be.revertedWith(
                "MultiSigWallet: Not enough confirmations"
            );
        });

        it("should execute the transaction when enough confirmations are met", async function () {
            await multiSigWallet.connect(owner2).confirmTransaction(0);
            
            const initialBalance = await ethers.provider.getBalance(to);
            
            await expect(multiSigWallet.connect(owner1).executeTransaction(0))
                .to.emit(multiSigWallet, "TransactionExecuted")
                .withArgs(0, owner1.address);

            const tx = await multiSigWallet.getTransaction(0);
            expect(tx.executed).to.be.true;

            const finalBalance = await ethers.provider.getBalance(to);
            expect(finalBalance - initialBalance).to.equal(value);
        });

        it("should fail if trying to execute a non-existent transaction", async function () {
            await expect(multiSigWallet.connect(owner1).executeTransaction(99)).to.be.revertedWith(
                "MultiSigWallet: Transaction does not exist"
            );
        });

        it("should fail if trying to execute an already executed transaction", async function () {
            await multiSigWallet.connect(owner2).confirmTransaction(0);
            await multiSigWallet.connect(owner1).executeTransaction(0); // First execution
            
            await expect(multiSigWallet.connect(owner1).executeTransaction(0)).to.be.revertedWith(
                "MultiSigWallet: Transaction already executed"
            );
        });
    });

    // 6. Test Owner Management (via multi-sig transactions)
    describe("Owner Management", function () {
        it("should be able to add a new owner through a proposal", async function () {
            const newOwner = nonOwner.address;
            const addOwnerData = multiSigWallet.interface.encodeFunctionData("addOwner", [newOwner]);

            // Submit the proposal to add an owner
            await multiSigWallet.connect(owner1).submitTransaction(await multiSigWallet.getAddress(), 0, addOwnerData);
            
            // Confirm and execute
            await multiSigWallet.connect(owner2).confirmTransaction(0);
            await multiSigWallet.connect(owner1).executeTransaction(0);

            expect(await multiSigWallet.isOwner(newOwner)).to.be.true;
        });

        it("should be able to remove an owner through a proposal", async function () {
            const ownerToRemove = owner3.address;
            const removeOwnerData = multiSigWallet.interface.encodeFunctionData("removeOwner", [ownerToRemove]);

