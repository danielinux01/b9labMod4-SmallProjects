const Promise = require("bluebird"); // npm install  bluebird --save
const Splitter = artifacts.require("./Splitter.sol");

web3.eth.makeSureHasAtLeast = require("./utils/makeSureHasAtLeast.js");
web3.eth.makeSureAreUnlocked = require("./utils/makeSureAreUnlocked.js");
web3.eth.getTransactionReceiptMined = require("./utils/getTransactionReceiptMined.js");

const expectedException = require("./utils/expectedException.js");

if (typeof web3.eth.getBalancePromise !== "function") {
    Promise.promisifyAll(web3.eth, { suffix: "Promise" });
}

contract('Splitter', function(accounts) {
  //console.log("network:", network);
  //console.log("accounts passed:", accounts);

  let giver, payee1, payee2, splitter ;
  
  before("Should have at least 3 unlocked accounts with balance", function(){
    assert.isAtLeast(accounts.length,3,"should have at least 3 accounts");
    [giver, payee1,payee2] = accounts;
    return web3.eth.makeSureAreUnlocked([ giver, payee1, payee2 ])
            .then(() => web3.eth.makeSureHasAtLeast(giver, [ payee1, payee2 ], web3.toWei(2)))
            .then(txHashes => web3.eth.getTransactionReceiptMined(txHashes));
  });


  beforeEach("deploy new Splitter",function(){
    return Splitter.new({from:giver})
    .then(function(instance){
      splitter = instance;
    });
  });

  it("should be owned by giver", function() {
    return splitter.owner.call({from:giver})
    .then(function(_owner){
        assert.strictEqual(_owner,giver,"Contract is not owned by owner");
    });

  });

  it("should reject direct transaction with value", function() {
        return expectedException(
            () => splitter.sendTransaction({ from: giver, value: 1, gas: 3000000 }),
            3000000);
  });



  describe("split", function() {

    it("should reject without Eth",function(){
        return expectedException(
          () => splitter.split(payee1,payee2,{from: giver,gas:3000000}),
          3000000 );      
    });

    it("should reject with 1 wei", function() {
        return expectedException(
            () => splitter.split(payee1, payee2, { from: giver, value: 1, gas: 3000000 }),
            3000000);
    });

    it("should reject with odd Eth", function() {
        return expectedException(
            () => splitter.split(payee1, payee2, { from: giver, value: 7, gas: 3000000 }),
            3000000);
    });

    it("should reject without payees", function() {
        return expectedException(
            () => splitter.split(0, 0, { from: giver, value: 2, gas: 3000000 }),
            3000000);
    });

    it("should reject without payee1", function() {
        return expectedException(
            () => splitter.split(payee1, 0, { from: giver, value: 2, gas: 3000000 }),
            3000000);
    });

    it("should reject without payee2", function() {
        return expectedException(
            () => splitter.split(0, payee2, { from: giver, value: 2, gas: 3000000 }),
            3000000);
    });

    it("should keep Weis in contract when split", function() {
        return splitter.split(payee1, payee2, { from: giver, value: 2 })
            .then(txObject => web3.eth.getBalancePromise(splitter.address))
            .then(balance => assert.strictEqual(balance.toString(10), "2"));
    });

    it("should record owed un/equally when split", function() {
        return splitter.split(payee1, payee2, { from: giver, value: 2  })
            .then(txObject => splitter.pendingWithdrawals(payee1))
            .then(owedP1 => assert.strictEqual(owedP1.toString(10), "1"))
            .then(() => splitter.pendingWithdrawals(payee2))
            .then(owedP2 => assert.strictEqual(owedP2.toString(10), "1"));
    });
  });

  describe("withdraw", function() {

        beforeEach("split 100 first", function() {
            return splitter.split(payee1, payee2, { from: giver, value: 100 });
        });

        it("should reject withdraw by giver", function() {
            return expectedException(
                () => splitter.withdraw({ from: giver, gas: 3000000 }),
                3000000);
        });

        it("should reject withdraw if value passed", function() {
            return splitter.withdraw({ from: payee1, value: 10 })
                .then(
                    txObject => assert.fail("Should not have been accepted"),
                    e => assert.isAtLeast(e.message.indexOf("Cannot send value to non-payable function"), 0)
                );
        });


        it("should reduce splitter balance by withdrawn amount", function() {
            return splitter.withdraw({ from: payee1 })
                .then(txObject => web3.eth.getBalancePromise(splitter.address))
                .then(balance => assert.strictEqual(balance.toString(10), "50"));
        });

        it("should increase payee1 balance with amount", function() {
            let P1BalanceBefore, txFee;
            return web3.eth.getBalancePromise(payee1)
                .then(balance => P1BalanceBefore = balance)
                .then(() => splitter.withdraw({ from: payee1 }))
                .then(txObject => web3.eth.getTransactionPromise(txObject.tx)
                .then(tx => txFee = tx.gasPrice.times(txObject.receipt.gasUsed)))
                .then(() => web3.eth.getBalancePromise(payee1))
                .then(balance => assert.strictEqual(
                    P1BalanceBefore.plus(50).minus(txFee).toString(10),
                    balance.toString(10)));
        });

        it("should reject payee1 withdrawing twice", function() {
            return splitter.withdraw({ from: payee1 })
                .then(txObject => expectedException(
                    () => splitter.withdraw({ from: payee1, gas: 3000000 }),
                    3000000));
        });

        it("should not withdraw after stop", function(){
            return splitter.runSwitch(false,{from:giver})
                .then(txObject => expectedException(
                    () => splitter.withdraw({ from: payee1, gas: 3000000 }),
                    3000000));
             
        });

        it("should withdraw after stop and start", function(){
            return splitter.runSwitch(false,{from:giver})
                .then(txObject => splitter.runSwitch(true,{from:giver}))
                .then(txObject => splitter.withdraw({ from: payee1}))
                .then(txObject => {/*console.log(txObject.receipt);*/ assert.strictEqual(txObject.receipt.status,1);});
        });


  });


  describe("Stoppable", function() {
    
    it("should stoppable from giver", function() {
            return splitter.runSwitch(false, {from:giver})
            .then(txObject=> { assert.strictEqual(txObject.receipt.status,1);});

    });

    it("should not stoppable from payee1", function() {
            return expectedException(
                () => splitter.runSwitch(false, {from:payee1, gas: 3000000 }),
                3000000);
        });


  });

   

});
