
// for use import, npm install what???
//import expectedExceptionPromise from './expected_exception_testRPC_and_geth';

/* after truffle test I have this error:
import expectedExceptionPromise from './expected_exception_testRPC_and_geth';
^^^^^^

SyntaxError: Unexpected token import
    at createScript (vm.js:80:10)

  what can I install?

*/

const Splitter = artifacts.require("./Splitter.sol");

contract('Splitter', function(accounts) {
  //console.log("network:", network);
  console.log("accounts:", accounts);

  var owner = accounts[0];
  var giver = accounts[1];
  var payee1 = accounts[2];
  var payee2 = accounts[3];
  var myContract ;

  // npm --save bluebird
  const Promise = require("bluebird");
  const getBalancePromise = Promise.promisify(web3.eth.getBalance);

  // Building custom getBalancePromise ...
  /*function getBalancePromise(queryAddress)
  {
    return new Promise((resolve, reject) => {
      web3.eth.getBalance(queryAddress, function(error, balance) { 
                  if (error) reject(error)
                  else resolve(balance)
              });
    });
  };*/


  beforeEach(function(){
    return Splitter.new({from:owner})
    .then(function(instance){
      myContract = instance;
    });
  });

  it("should be owned by owner", function() {
    return myContract.owner.call({from:owner})
    .then(function(_owner){
        
        assert.strictEqual(_owner,owner,"Contract is not owned by owner");

    });

  });
  

  it("balance of giver should be splitted to payee1 and payee2",function(){ 
    var initialBalanceOfContract;
    var initialBalanceOfGiver;
    var initialBalanceOfPayee1;
    var initialBalanceOfPayee2;
    
    var currentBalanceOfContract;
    var currentBalanceOfGiver;
    var currentBalanceOfPayee1;
    var currentBalanceOfPayee2;
    
    var contribution = 100000;
    var oddContribution = 1000001;




    return getBalancePromise(myContract.address)
    .then(balance => {
        initialBalanceOfContract = balance;       
        return getBalancePromise(giver);
    })
    .then(balance=> {
      initialBalanceOfGiver = balance;
       return getBalancePromise(payee1);
    })
    .then(balance=> {
      initialBalanceOfPayee1 = balance;
       return getBalancePromise(payee2);
    })
    .then(balance=> {
      initialBalanceOfPayee2 = balance;
      return myContract.split(payee1,payee2,{from:giver,value:contribution})

    })
    .then(function(txn){
      return getBalancePromise(myContract.address)
    })
    .then(balance => {
        currentBalanceOfContract = balance;       
        return getBalancePromise(giver);
    })
    .then(balance=> {
      currentBalanceOfGiver = balance;
      assert.strictEqual(currentBalanceOfContract.toNumber(),initialBalanceOfContract.toNumber()+contribution,"Wrong Contract balance!");
      return myContract.withdraw({from:payee1});
    })
    .then(txn => {
      
      return getBalancePromise(payee1);
    })
    .then(balance=> {
      currentBalanceOfPayee1 = balance;
      
      assert.isBelow(currentBalanceOfPayee1.toNumber(),initialBalanceOfPayee1.toNumber()+contribution/2,"Wrong payee1 balance!");
      
      return myContract.withdraw({from:payee2});
    })
    .then(txn => {
      
      return getBalancePromise(payee2);
    })
    .then(balance=> {
      currentBalanceOfPayee2 = balance;
      assert.isBelow(currentBalanceOfPayee2.toNumber(),initialBalanceOfPayee2.toNumber()+contribution/2,"Wrong payee2 balance!");
      return getBalancePromise(myContract.address);
    })
    .then(balance=>{
      currentBalanceOfContract = balance;
      assert.strictEqual(currentBalanceOfContract.toNumber(),initialBalanceOfContract.toNumber(),"Wrong final Contract balance!");
    });

  }); // it("balance of giver should be splitted to payee1 and payee2"


  it("balance of giver should not be splitted to payee1 and payee2 because amount is not divisible",function(){ 
    
    var wrongContribution = 100001;    
    var transaction=undefined;

/*
    return expectedExceptionPromise(function () {
        return myContract.split(payee1,payee2,{from:giver,value:wrongContribution});
    },3000000);
*/
    return myContract.split(payee1,payee2,{from:giver,value:wrongContribution})
    .then(function(txn){
      transaction = txn;
      assert.isTrue(false,"Transacion executed without exception");
    })
    .catch(error => {assert.strictEqual(transaction,undefined,"Transaction revert");});
    

  }); // it("balance of giver should not be splitted to payee1 and payee2 because amount is not divisible"

  

});
