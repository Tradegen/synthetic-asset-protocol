const { expect } = require("chai");
const { parseEther } = require("@ethersproject/units");

describe("Oracle", () => {
  let deployer;
  let otherUser;

  let dataSource;
  let dataSourceAddress;
  let DataSourceFactory;

  let oracle;
  let oracleAddress;
  let OracleFactory;

  let testToken;
  let testTokenAddress;
  let TestTokenFactory;

  before(async () => {
    const signers = await ethers.getSigners();
    deployer = signers[0];
    otherUser = signers[1];

    DataSourceFactory = await ethers.getContractFactory('TeestSource');
    OracleFactory = await ethers.getContractFactory('Oracle');
    TestTokenFactory = await ethers.getContractFactory('TestTokenERC20');

    testToken = await TestTokenFactory.deploy("Test Token", "TEST");
    await testToken.deployed();
    testTokenAddress = testToken.address;

    dataSource = await DataSourceFactory.deploy(testTokenAddress, parseEther("1"));
    await dataSource.deployed();
    dataSourceAddress = dataSource.address;
  });

  beforeEach(async () => {
    oracle = await OracleFactory.deploy(dataSourceAddress);
    await oracle.deployed();
    oracleAddress = oracle.address;
  });

  describe("#getUsageFeeInfo", () => {
    it("returns fee token and usage fee", async () => {
        const feeToken = await oracle.getUsageFeeInfo(deployer.address)[0];
        expect(feeToken).to.equal(testTokenAddress);

        const usageFee = await oracle.getUsageFeeInfo(deployer.address)[1];
        expect(usageFee).to.equal(parseEther("1"));
    });
  });

  describe("#getLatestPrice", () => {
    it("fails when fee token is not approved", async () => {
        let tx = await dataSource.setLatestPrice(deployer.address, parseEther("42"));
        await tx.wait();

        let tx2 = oracle.getLatestPrice(deployer.address);
        await expect(tx2).to.be.reverted;
    });

    it("returns the latest price", async () => {
        let tx = await dataSource.setLatestPrice(deployer.address, parseEther("42"));
        await tx.wait();

        let initialDeployerBalance = await testToken.balanceOf(deployer.address);
        let initialDataSourceBalance = await testToken.balanceOf(dataSourceAddress);

        let tx2 = await testToken.approve(oracleAddress, parseEther("1"));
        await tx2.wait();

        let tx3 = await oracle.getLatestPrice(deployer.address);
        await tx3.wait();
        expect(tx3).to.equal(parseEther("42"));

        let newDeployerBalance = await testToken.balanceOf(deployer.address);
        expect(newDeployerBalance).to.equal(initialDeployerBalance - parseEther("1"));

        let newDataSourceBalance = await testToken.balanceOf(dataSourceAddress);
        expect(newDataSourceBalance).to.equal(initialDataSourceBalance + parseEther("1"));
    });
  });
});