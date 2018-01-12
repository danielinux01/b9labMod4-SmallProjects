var Splitter = artifacts.require("./Splitter.sol");

contract('Splitter', function(accounts) {
  //console.log("network:", network);
  console.log("accounts:", accounts);

  var owner = accounts[0];
  var giver = accounts[1];
  var payee1 = accounts[2];
  var payee2 = accounts[3];
  var myContract ;

  beforeEach(function(){
    return Splitter.new({from:owner})
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


  it("balance of giver should be splitted to payee1 and payee2",function(){ // TO COMPLETE!
    var initialBalanceOfContract;
    var initialBalanceOfGiver;
    var initialBalanceOfPayee1;
    var initialBalanceOfPayee2;
    var contractBalance;

    var contribution = web3.toWei(1);
    
    initialBalanceOfContract = web3.eth.getBalance(myContract.address);
    initialBalanceOfGiver= web3.eth.getBalance(giver);
    initialBalanceOfPayee1= web3.eth.getBalance(payee1);
    initialBalanceOfPayee2= web3.eth.getBalance(payee2);

    return myContract.split(payee1,payee2,{from:giver,value:contribution})
    .then(function(txn){
      contractBalance = web3.eth.getBalance(myContract.address);
      assert.equal(contractBalance,contribution,"Giver contribution not sent to contract");
      //assert.equal(initialBalanceOfGiver,initialBalanceOfGiver.toNumber()-contribution,"Giver balance incorrect"); // todo with correct conversion
      return myContract.withdraw({from:payee1});
    })
    .then(function(tnx){
        var tmpContractBalance = web3.eth.getBalance(myContract.address);
        contractBalance = web3.eth.getBalance(myContract.address);
        assert.equal(contractBalance,contribution/2,"The contract balance is not correct"); 
        //assert.equal(initialBalanceOfPayee1,initialBalanceOfPayee1+contribution/2,"Payee1 not receive contribution"); // todo with correct conversion
    });
    
  });

});
