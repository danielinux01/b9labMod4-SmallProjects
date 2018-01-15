var Splitter = artifacts.require("./Splitter.sol");
var Remittance = artifacts.require("./Remittance.sol");

module.exports = function(deployer,network,accounts) {
	console.log("accounts:", accounts);
	console.log("network:", network);
  	deployer.deploy(Splitter);
  	deployer.deploy(Remittance);
};
