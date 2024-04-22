const { expect } = require("chai");

describe("ProtocolSettings", () => {
  let deployer;
  let otherUser;

  let protocolSettings;
  let protocolSettingsAddress;
  let ProtocolSettingsFactory;

  before(async () => {
    const signers = await ethers.getSigners();
    deployer = signers[0];
    otherUser = signers[1];

    ProtocolSettingsFactory = await ethers.getContractFactory('ProtocolSettings');

    scheduleCurrent = await ScheduleFactory.deploy(CYCLE_DURATION * 4, startTimeCurrent);
    await scheduleCurrent.deployed();
    scheduleCurrentAddress = scheduleCurrent.address;
  });

  beforeEach(async () => {
    protocolSettings = await ProtocolSettingsFactory.deploy();
    await protocolSettings.deployed();
    protocolSettingsAddress = protocolSettings.address;
  });

  describe("#updateMaxDiscount", () => {
    it("onlyOwner", async () => {
        let tx = protocolSettings.connect(otherUser).updateMaxDiscount(5000);
        await expect(tx).to.be.reverted;

        const maxDiscount = await protocolSettings.maxDiscount();
        expect(maxDiscount).to.equal(2000);
    });

    it("out of bounds", async () => {
        let tx = protocolSettings.updateMaxDiscount(400000);
        await expect(tx).to.be.reverted;

        const maxDiscount = await protocolSettings.maxDiscount();
        expect(maxDiscount).to.equal(2000);
    });

    it("meets requirements", async () => {
        let tx = await protocolSettings.updateMaxDiscount(3000);
        await tx.wait();

        const maxDiscount = await protocolSettings.maxDiscount();
        expect(maxDiscount).to.equal(3000);
    });
  });

  describe("#updateMintFee", () => {
    it("onlyOwner", async () => {
        let tx = protocolSettings.connect(otherUser).updateMintFee(5000);
        await expect(tx).to.be.reverted;

        const mintFee = await protocolSettings.mintFee();
        expect(mintFee).to.equal(100);
    });

    it("out of bounds", async () => {
        let tx = protocolSettings.updateMintFee(400000);
        await expect(tx).to.be.reverted;

        const mintFee = await protocolSettings.mintFee();
        expect(mintFee).to.equal(100);
    });

    it("meets requirements", async () => {
        let tx = await protocolSettings.updateMintFee(3000);
        await tx.wait();

        const mintFee = await protocolSettings.mintFee();
        expect(mintFee).to.equal(3000);
    });
  });

  describe("#updateMinimumMinimumTimeUntilDiscountStarts", () => {
    it("onlyOwner", async () => {
        let tx = protocolSettings.connect(otherUser).updateMinimumMinimumTimeUntilDiscountStarts(5000);
        await expect(tx).to.be.reverted;

        const time = await protocolSettings.minimumMinimumTimeUntilDiscountStarts();
        expect(time).to.equal(600);
    });

    it("out of bounds", async () => {
        let tx = protocolSettings.updateMinimumMinimumTimeUntilDiscountStarts(400000);
        await expect(tx).to.be.reverted;

        const time = await protocolSettings.minimumMinimumTimeUntilDiscountStarts();
        expect(time).to.equal(600);
    });

    it("meets requirements", async () => {
        let tx = await protocolSettings.updateMinimumMinimumTimeUntilDiscountStarts(3000);
        await tx.wait();

        const time = await protocolSettings.minimumMinimumTimeUntilDiscountStarts();
        expect(time).to.equal(3000);
    });
  });

  describe("#updateMaximumMinimumTimeUntilDiscountStarts", () => {
    it("onlyOwner", async () => {
        let tx = protocolSettings.connect(otherUser).updateMaximumMinimumTimeUntilDiscountStarts(5000);
        await expect(tx).to.be.reverted;

        const time = await protocolSettings.maximumMinimumTimeUntilDiscountStarts();
        expect(time).to.equal(86400); // 1 day.
    });

    it("out of bounds", async () => {
        let tx = protocolSettings.updateMaximumMinimumTimeUntilDiscountStarts(40);
        await expect(tx).to.be.reverted;

        const time = await protocolSettings.maximumMinimumTimeUntilDiscountStarts();
        expect(time).to.equal(86400);
    });

    it("meets requirements", async () => {
        let tx = await protocolSettings.updateMaximumMinimumTimeUntilDiscountStarts(3000);
        await tx.wait();

        const time = await protocolSettings.maximumMinimumTimeUntilDiscountStarts();
        expect(time).to.equal(3000);
    });
  });

  describe("#updateMinimumTimeUntilMaxDiscount", () => {
    it("onlyOwner", async () => {
        let tx = protocolSettings.connect(otherUser).updateMinimumTimeUntilMaxDiscount(5000);
        await expect(tx).to.be.reverted;

        const time = await protocolSettings.minimumTimeUntilMaxDiscount();
        expect(time).to.equal(3600); // 1 hour.
    });

    it("out of bounds", async () => {
        let tx = protocolSettings.updateMinimumTimeUntilMaxDiscount(1000000);
        await expect(tx).to.be.reverted;

        const time = await protocolSettings.minimumTimeUntilMaxDiscount();
        expect(time).to.equal(3600);
    });

    it("meets requirements", async () => {
        let tx = await protocolSettings.updateMinimumTimeUntilMaxDiscount(3000);
        await tx.wait();

        const time = await protocolSettings.minimumTimeUntilMaxDiscount();
        expect(time).to.equal(3000);
    });
  });

  describe("#updateMaximumTimeUntilMaxDiscount", () => {
    it("onlyOwner", async () => {
        let tx = protocolSettings.connect(otherUser).updateMaximumTimeUntilMaxDiscount(5000);
        await expect(tx).to.be.reverted;

        const time = await protocolSettings.maximumTimeUntilMaxDiscount();
        expect(time).to.equal(604800); // 1 week.
    });

    it("out of bounds", async () => {
        let tx = protocolSettings.updateMaximumTimeUntilMaxDiscount(100);
        await expect(tx).to.be.reverted;

        const time = await protocolSettings.maximumTimeUntilMaxDiscount();
        expect(time).to.equal(604800);
    });

    it("meets requirements", async () => {
        let tx = await protocolSettings.updateMaximumTimeUntilMaxDiscount(86400); // 1 day.
        await tx.wait();

        const time = await protocolSettings.maximumTimeUntilMaxDiscount();
        expect(time).to.equal(86400);
    });
  });
});