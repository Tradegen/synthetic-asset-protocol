const { expect } = require("chai");

describe("UserSettings", () => {
  let deployer;
  let otherUser;

  let userSettings;
  let userSettingsAddress;
  let UserSettingsFactory;

  let protocolSettings;
  let protocolSettingsAddress;
  let ProtocolSettingsFactory;

  before(async () => {
    const signers = await ethers.getSigners();
    deployer = signers[0];
    otherUser = signers[1];

    UserSettingsFactory = await ethers.getContractFactory('UserSettings');
    ProtocolSettingsFactory = await ethers.getContractFactory('ProtocolSettings');

    protocolSettings = await ProtocolSettingsFactory.deploy();
    await protocolSettings.deployed();
    protocolSettingsAddress = protocolSettings.address;
  });

  beforeEach(async () => {
    userSettings = await UserSettingsFactory.deploy(protocolSettingsAddress);
    await userSettings.deployed();
    userSettingsAddress = userSettings.address;
  });

  describe("#registerUser", () => {
    it("minimumTimeUntilDiscountStarts is too low", async () => {
        let tx = userSettings.registerUser(10, 10000, 500, 300);
        await expect(tx).to.be.reverted;

        const minimumTimeUntilDiscountStarts = await userSettings.minimumTimeUntilDiscountStarts(deployer.address);
        expect(minimumTimeUntilDiscountStarts).to.equal(0);
    });

    it("minimumTimeUntilDiscountStarts is too high", async () => {
        let tx = userSettings.registerUser(1000000, 10000, 500, 300);
        await expect(tx).to.be.reverted;

        const minimumTimeUntilDiscountStarts = await userSettings.minimumTimeUntilDiscountStarts(deployer.address);
        expect(minimumTimeUntilDiscountStarts).to.equal(0);
    });

    it("timeUntilMaxDiscount is too low", async () => {
        let tx = userSettings.registerUser(1000, 100, 500, 300);
        await expect(tx).to.be.reverted;

        const timeUntilMaxDiscount = await userSettings.timeUntilMaxDiscount(deployer.address);
        expect(timeUntilMaxDiscount).to.equal(0);
    });

    it("timeUntilMaxDiscount is too high", async () => {
        let tx = userSettings.registerUser(1000, 1000000, 500, 300);
        await expect(tx).to.be.reverted;

        const timeUntilMaxDiscount = await userSettings.timeUntilMaxDiscount(deployer.address);
        expect(timeUntilMaxDiscount).to.equal(0);
    });

    it("maximumDiscount is too low", async () => {
        let tx = userSettings.registerUser(1000, 10000, 100, 300);
        await expect(tx).to.be.reverted;

        const maximumDiscount = await userSettings.maximumDiscount(deployer.address);
        expect(maximumDiscount).to.equal(0);
    });

    it("maximumDiscount is too high", async () => {
        let tx = userSettings.registerUser(1000, 10000, 300, 300);
        await expect(tx).to.be.reverted;

        const maximumDiscount = await userSettings.maximumDiscount(deployer.address);
        expect(maximumDiscount).to.equal(0);
    });

    it("startingDiscount is out of range", async () => {
        let tx = userSettings.registerUser(1000, 10000, 300, 500);
        await expect(tx).to.be.reverted;

        const startingDiscount = await userSettings.startingDiscount(deployer.address);
        expect(startingDiscount).to.equal(0);
    });

    it("meets requirements", async () => {
        let tx = await userSettings.registerUser(1000, 10000, 500, 300);
        await tx.wait();

        const minimumTimeUntilDiscountStarts = await userSettings.minimumTimeUntilDiscountStarts(deployer.address);
        expect(minimumTimeUntilDiscountStarts).to.equal(1000);

        const timeUntilMaxDiscount = await userSettings.timeUntilMaxDiscount(deployer.address);
        expect(timeUntilMaxDiscount).to.equal(10000);

        const maximumDiscount = await userSettings.maximumDiscount(deployer.address);
        expect(maximumDiscount).to.equal(500);

        const startingDiscount = await userSettings.startingDiscount(deployer.address);
        expect(startingDiscount).to.equal(300);
    });

    it("user is already registered", async () => {
        let tx = await userSettings.registerUser(1000, 10000, 500, 300);
        await tx.wait();

        let tx2 = userSettings.registerUser(1000, 10000, 800, 400);
        await expect(tx2).to.be.reverted;

        const minimumTimeUntilDiscountStarts = await userSettings.minimumTimeUntilDiscountStarts(deployer.address);
        expect(minimumTimeUntilDiscountStarts).to.equal(1000);

        const timeUntilMaxDiscount = await userSettings.timeUntilMaxDiscount(deployer.address);
        expect(timeUntilMaxDiscount).to.equal(10000);

        const maximumDiscount = await userSettings.maximumDiscount(deployer.address);
        expect(maximumDiscount).to.equal(500);

        const startingDiscount = await userSettings.startingDiscount(deployer.address);
        expect(startingDiscount).to.equal(300);
    });

    it("multiple users", async () => {
        let tx = await userSettings.registerUser(1000, 10000, 500, 300);
        await tx.wait();

        let tx2 = await userSettings.connect(otherUser).registerUser(2000, 20000, 600, 400);
        await tx2.wait();

        const minimumTimeUntilDiscountStartsDeployer = await userSettings.minimumTimeUntilDiscountStarts(deployer.address);
        expect(minimumTimeUntilDiscountStartsDeployer).to.equal(1000);

        const timeUntilMaxDiscountDeployer = await userSettings.timeUntilMaxDiscount(deployer.address);
        expect(timeUntilMaxDiscountDeployer).to.equal(10000);

        const maximumDiscountDeployer = await userSettings.maximumDiscount(deployer.address);
        expect(maximumDiscountDeployer).to.equal(500);

        const startingDiscountDeployer = await userSettings.startingDiscount(deployer.address);
        expect(startingDiscountDeployer).to.equal(300);

        const minimumTimeUntilDiscountStartsOther = await userSettings.minimumTimeUntilDiscountStarts(otherUser.address);
        expect(minimumTimeUntilDiscountStartsOther).to.equal(2000);

        const timeUntilMaxDiscountOther = await userSettings.timeUntilMaxDiscount(otherUser.address);
        expect(timeUntilMaxDiscountOther).to.equal(20000);

        const maximumDiscountOther = await userSettings.maximumDiscount(otherUser.address);
        expect(maximumDiscountOther).to.equal(600);

        const startingDiscountOther = await userSettings.startingDiscount(otherUser.address);
        expect(startingDiscountOther).to.equal(400);
    });
  });

  describe("#updateMinimumTimeUntilDiscountStarts", () => {
    it("user is not registered", async () => {
        let tx = userSettings.updateMinimumTimeUntilDiscountStarts(5000);
        await expect(tx).to.be.reverted;

        const minimumTimeUntilDiscountStarts = await userSettings.minimumTimeUntilDiscountStarts(deployer.address);
        expect(minimumTimeUntilDiscountStarts).to.equal(0);
    });

    it("new value is too low", async () => {
        let tx = await userSettings.registerUser(1000, 10000, 500, 300);
        await tx.wait();

        let tx2 = userSettings.updateMinimumTimeUntilDiscountStarts(10);
        await expect(tx2).to.be.reverted;

        const minimumTimeUntilDiscountStarts = await userSettings.minimumTimeUntilDiscountStarts(deployer.address);
        expect(minimumTimeUntilDiscountStarts).to.equal(1000);
    });

    it("new value is too high", async () => {
        let tx = await userSettings.registerUser(1000, 10000, 500, 300);
        await tx.wait();

        let tx2 = userSettings.updateMinimumTimeUntilDiscountStarts(10000000);
        await expect(tx2).to.be.reverted;

        const minimumTimeUntilDiscountStarts = await userSettings.minimumTimeUntilDiscountStarts(deployer.address);
        expect(minimumTimeUntilDiscountStarts).to.equal(1000);
    });

    it("meets requirements", async () => {
        let tx = await userSettings.registerUser(1000, 10000, 500, 300);
        await tx.wait();

        let tx2 = await userSettings.updateMinimumTimeUntilDiscountStarts(5000);
        await tx2.wait();

        const minimumTimeUntilDiscountStarts = await userSettings.minimumTimeUntilDiscountStarts(deployer.address);
        expect(minimumTimeUntilDiscountStarts).to.equal(5000);
    });
  });

  describe("#updateTimeUntilMaxDiscount", () => {
    it("user is not registered", async () => {
        let tx = userSettings.updateTimeUntilMaxDiscount(5000);
        await expect(tx).to.be.reverted;

        const timeUntilMaxDiscount = await userSettings.timeUntilMaxDiscount(deployer.address);
        expect(timeUntilMaxDiscount).to.equal(0);
    });

    it("new value is too low", async () => {
        let tx = await userSettings.registerUser(1000, 10000, 500, 300);
        await tx.wait();

        let tx2 = userSettings.updateTimeUntilMaxDiscount(10);
        await expect(tx2).to.be.reverted;

        const timeUntilMaxDiscount = await userSettings.timeUntilMaxDiscount(deployer.address);
        expect(timeUntilMaxDiscount).to.equal(10000);
    });

    it("new value is too high", async () => {
        let tx = await userSettings.registerUser(1000, 10000, 500, 300);
        await tx.wait();

        let tx2 = userSettings.updateTimeUntilMaxDiscount(100000000);
        await expect(tx2).to.be.reverted;

        const timeUntilMaxDiscount = await userSettings.timeUntilMaxDiscount(deployer.address);
        expect(timeUntilMaxDiscount).to.equal(10000);
    });

    it("meets requirements", async () => {
        let tx = await userSettings.registerUser(1000, 10000, 500, 300);
        await tx.wait();

        let tx2 = await userSettings.updateTimeUntilMaxDiscount(5000);
        await tx2.wait();

        const timeUntilMaxDiscount = await userSettings.timeUntilMaxDiscount(deployer.address);
        expect(timeUntilMaxDiscount).to.equal(5000);
    });
  });

  describe("#updateMaximumDiscount", () => {
    it("user is not registered", async () => {
        let tx = userSettings.updateMaximumDiscount(5000);
        await expect(tx).to.be.reverted;

        const maximumDiscount = await userSettings.maximumDiscount(deployer.address);
        expect(maximumDiscount).to.equal(0);
    });

    it("new value is too low", async () => {
        let tx = await userSettings.registerUser(1000, 10000, 500, 300);
        await tx.wait();

        let tx2 = userSettings.updateMaximumDiscount(10);
        await expect(tx2).to.be.reverted;

        const maximumDiscount = await userSettings.maximumDiscount(deployer.address);
        expect(maximumDiscount).to.equal(500);
    });

    it("new value is too high", async () => {
        let tx = await userSettings.registerUser(1000, 10000, 500, 300);
        await tx.wait();

        let tx2 = userSettings.updateMaximumDiscount(10000);
        await expect(tx2).to.be.reverted;

        const maximumDiscount = await userSettings.maximumDiscount(deployer.address);
        expect(maximumDiscount).to.equal(500);
    });

    it("meets requirements", async () => {
        let tx = await userSettings.registerUser(1000, 10000, 500, 300);
        await tx.wait();

        let tx2 = await userSettings.updateMaximumDiscount(600);
        await tx2.wait();

        const maximumDiscount = await userSettings.maximumDiscount(deployer.address);
        expect(maximumDiscount).to.equal(600);
    });
  });

  describe("#updateStartingDiscount", () => {
    it("user is not registered", async () => {
        let tx = userSettings.updateStartingDiscount(5000);
        await expect(tx).to.be.reverted;

        const startingDiscount = await userSettings.startingDiscount(deployer.address);
        expect(startingDiscount).to.equal(0);
    });

    it("new value is out of bounds", async () => {
        let tx = await userSettings.registerUser(1000, 10000, 500, 300);
        await tx.wait();

        let tx2 = userSettings.updateStartingDiscount(600);
        await expect(tx2).to.be.reverted;

        const startingDiscount = await userSettings.startingDiscount(deployer.address);
        expect(startingDiscount).to.equal(300);
    });

    it("meets requirements", async () => {
        let tx = await userSettings.registerUser(1000, 10000, 500, 300);
        await tx.wait();

        let tx2 = await userSettings.updateStartingDiscount(400);
        await tx2.wait();

        const startingDiscount = await userSettings.startingDiscount(deployer.address);
        expect(startingDiscount).to.equal(400);
    });
  });
});