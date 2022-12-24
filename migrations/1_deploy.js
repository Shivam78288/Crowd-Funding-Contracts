const CrowdFundingUpgradeable = artifacts.require("CrowdFundingUpgradeable");
const FundingToken = artifacts.require("FundingToken");
const { deployProxy } = require("@openzeppelin/truffle-upgrades");
const deployments = require("../deployments/deployments.json");
const fs = require("fs");

module.exports = async function (deployer) {
  await deployer.deploy(FundingToken, "Funding Token", "FTK");
  const token = await FundingToken.deployed();
  console.log("Token deployed at: ", token.address);
  deployments["FundingToken"] = token.address;

  const crowdFunding = await deployProxy(
    CrowdFundingUpgradeable,
    [token.address],
    {
      deployer,
    }
  );

  deployments["CrowdFunding"] = crowdFunding.address;

  console.log("Crowd funding deployed at: ", crowdFunding.address);
  fs.writeFileSync("deployments/deployments.json", JSON.stringify(deployments));
};
