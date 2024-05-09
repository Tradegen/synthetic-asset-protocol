const { expect } = require("chai");
const { parseEther } = require("@ethersproject/units");

describe("VTEDataSource", () => {
  let deployer;
  let otherUser;

  let dataSource;
  let dataSourceAddress;
  let DataSourceFactory;

  let registry;
  let registryAddress;
  let RegistryFactory;

  let testToken;
  let testTokenAddress;
  let TestTokenFactory;

  before(async () => {
    const signers = await ethers.getSigners();
    deployer = signers[0];
    otherUser = signers[1];

    DataSourceFactory = await ethers.getContractFactory('VTEDataSource');
    RegistryFactory = await ethers.getContractFactory('TestRegistry');
    TestTokenFactory = await ethers.getContractFactory('TestTokenERC20');

    testToken = await TestTokenFactory.deploy("Test Token", "TEST");
    await testToken.deployed();
    testTokenAddress = testToken.address;

    registry = await RegistryFactory.deploy(testTokenAddress, parseEther("1"));
    await registry.deployed();
    registryAddress = registry.address;
  });

  beforeEach(async () => {
    dataSource = await DataSourceFactory.deploy(registryAddress);
    await dataSource.deployed();
    dataSourceAddress = dataSource.address;
  });

  describe("#getUsageFeeInfo", () => {
    it("returns fee token and usage fee", async () => {
        const feeToken = await dataSource.getUsageFeeInfo(deployer.address)[0];
        expect(feeToken).to.equal(testTokenAddress);

        const usageFee = await dataSource.getUsageFeeInfo(deployer.address)[1];
        expect(usageFee).to.equal(parseEther("1"));
    });
  });

  describe("#getLatestPrice", () => {
    it("fails when fee token is not approved", async () => {
        let tx = await registry.setLatestPrice(deployer.address, parseEther("42"));
        await tx.wait();

        let tx2 = dataSource.getLatestPrice(deployer.address);
        await expect(tx2).to.be.reverted;
    });

    it("returns the latest price", async () => {
        let tx = await registry.setLatestPrice(deployer.address, parseEther("42"));
        await tx.wait();

        let initialDeployerBalance = await testToken.balanceOf(deployer.address);
        let initialRegistryBalance = await testToken.balanceOf(registryAddress);

        let tx2 = await testToken.approve(dataSourceAddress, parseEther("1"));
        await tx2.wait();

        let tx3 = await dataSource.getLatestPrice(deployer.address);
        await tx3.wait();
        expect(tx3).to.equal(parseEther("42"));

        let newDeployerBalance = await testToken.balanceOf(deployer.address);
        expect(newDeployerBalance).to.equal(initialDeployerBalance - parseEther("1"));

        let newRegistryBalance = await testToken.balanceOf(registryAddress);
        expect(newRegistryBalance).to.equal(initialRegistryBalance + parseEther("1"));
    });
  });
});