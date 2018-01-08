var Splitter = artifacts.require("./Splitter.sol");

contract('Splitter', function(accounts) {
  var owner = accounts[0];
  var giver = accounts[1];
  var payee1 = accounts[2];
  var payee2 = accounts[3];

  beforeEach(function(){
    return Splitter.new(giver,payee1,payee2,{from:owner})
    .then(function(instance){
      contract = instance;
    });
  });
  it("should be owned by owner", function() {
    return contract.owner({from:owner})
    .then(function(_owner){
        assert.strictEqual(_owner,owner,"Contract is not owned by owner");
    });

  });

  

});
