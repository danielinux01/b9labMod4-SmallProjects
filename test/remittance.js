const Remittance = artifacts.require("./Remittance.sol");

// ToDo...
contract('Remittance', function(accounts) {
  var myContract ;
  var owner = accounts[0];

  beforeEach(function(){
    return Remittance.new({from:owner})
    .then(function(instance){
      myContract = instance;
    });
  });

  it("should be owned by owner", function() {
    return myContract.owner()
    .then(function(_owner){
        assert.strictEqual(_owner,owner,"Contract is not owned by owner");
    });

  });
});