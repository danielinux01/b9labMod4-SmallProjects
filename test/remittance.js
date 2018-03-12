const Promise = require("bluebird"); // npm install  bluebird --save
const Remittance = artifacts.require("./Remittance.sol");

web3.eth.makeSureHasAtLeast = require("./utils/makeSureHasAtLeast.js");
web3.eth.makeSureAreUnlocked = require("./utils/makeSureAreUnlocked.js");
web3.eth.getTransactionReceiptMined = require("./utils/getTransactionReceiptMined.js");

const expectedException = require("./utils/expectedException.js");

if (typeof web3.eth.getBalancePromise !== "function") {
    Promise.promisifyAll(web3.eth, { suffix: "Promise" });
}



contract('Remittance', function(accounts) {
  const pwdPayee = "PayeePwd", pwdExchange = "ExchangePwd";
  let remittance, giver, payee, exchange ;
  const address0 = "0x0000000000000000000000000000000000000000";

   before("Should have at least 4 unlocked accounts with balance", function(){
    assert.isAtLeast(accounts.length,4,"should have at least 4 accounts");
    [giver, payee,exchange] = accounts;
    return web3.eth.makeSureAreUnlocked([ giver, payee, exchange ]);
  });

  beforeEach(function(){
    return Remittance.new({from:giver})
      .then(function(instance){
          remittance = instance;
        });
  });

  it("should be owned by giver", function() {
    return remittance.owner()
    .then(function(_owner){
        assert.strictEqual(_owner,giver,"Contract is not owned by giver");
    });
  });

  it("should reject direct transaction with value", function() {
        return expectedException(
            () => remittance.sendTransaction({ from: giver, value: 1, gas: 3000000 }),
            3000000);
    });


  describe("deposit", function() {
    let _hashPwdKnownByPayee, _hashPwdKnownByExchange;
    
    before("createHashOfPwd", function() {
        return remittance.hashWithKeccak256(pwdPayee)
            .then(hash => _hashPwdKnownByPayee = hash)
            .then(() => remittance.hashWithKeccak256(pwdExchange))
            .then(hash => _hashPwdKnownByExchange = hash);
    });


    it("should reject without Ether", function() {
        return expectedException(
            () => remittance.deposit( exchange,payee, _hashPwdKnownByPayee,_hashPwdKnownByExchange, 20, { from: giver, gas: 3000000 }),
            3000000);
    });

    it("should reject with 0 duration", function() {
        return expectedException(
            () => remittance.deposit( exchange,payee, _hashPwdKnownByPayee,_hashPwdKnownByExchange, 0, { from: giver, gas: 3000000 }),
            3000000);
    }); 

    it("should keep Weis in contract on deposit", function() {
            return remittance.deposit( exchange,payee, _hashPwdKnownByPayee,_hashPwdKnownByExchange, 350, { from: giver,value:100})
                .then(txObject => web3.eth.getBalancePromise(remittance.address))
                .then(balance => assert.strictEqual(balance.toString(10), "100"));
    });

    it("should emit a single event on deposit", function() {
            return remittance.deposit( exchange,payee, _hashPwdKnownByPayee,_hashPwdKnownByExchange, 350, { from: giver,value:100})
                .then(txObject => {
                    assert.strictEqual(txObject.logs.length, 1);
                    assert.strictEqual(txObject.logs[0].event, "LogDeposited");
                    assert.strictEqual(txObject.logs[0].args.fromAddress,giver);
                    assert.strictEqual(txObject.logs[0].args.toAddress, payee);
                    assert.strictEqual(txObject.logs[0].args.exchange, exchange);
                    assert.strictEqual(txObject.logs[0].args.amount.toString(10), "100");
                    /*assert.strictEqual(
                        txObject.logs[0].args.blockLimit.toString(10),
                        web3.toBigNumber(2102400).plus(txObject.receipt.blockNumber).toString(10));*/
                });
    });
  });

  describe("withdraw", function() {
      let _hashPwdKnownByPayee, _hashPwdKnownByExchange;
      let depositTxHash;

      before("createHashOfPwd", function() {
          return remittance.hashWithKeccak256(pwdPayee)
              .then(hash => _hashPwdKnownByPayee = hash)
              .then(() => remittance.hashWithKeccak256(pwdExchange))
              .then(hash => _hashPwdKnownByExchange = hash);
      });

     
      beforeEach("deposit for bob", function() {
          return remittance.deposit.sendTransaction( exchange,payee, _hashPwdKnownByExchange,_hashPwdKnownByPayee, 350, { from: giver,value:1000})
              .then(txHash => depositTxHash = txHash);
      });

      it("should reject withdraw from giver", function() {
          return expectedException(
              () => remittance.withdraw(exchange, pwdExchange,pwdPayee, { from: giver, gas: 3000000 }),
              3000000);
      });
      
      it("should reject withdraw from exchange", function() {
          return expectedException(
              () => remittance.withdraw(exchange, pwdExchange,pwdPayee, { from: exchange, gas: 3000000 }),
              3000000);
      });
      
      it("should reject withdraw if wrong first password", function() {
            return expectedException(
                () => remittance.withdraw(exchange, "wrongPwdExchange",pwdPayee, { from: payee, gas: 3000000 }),
                3000000); 
      });

      it("should clear balance on withdraw", function() {
            return remittance.withdraw(exchange, pwdExchange,pwdPayee, { from: payee})
                .then(txObject => web3.eth.getBalancePromise(remittance.address))
                .then(balance => assert.strictEqual(balance.toString(10), "0"));
      });

  });

  describe("Stoppable", function() {
    
    it("should stoppable from giver", function() {
            return remittance.runSwitch(false, {from:giver})
            .then(txObject=> { assert.strictEqual(txObject.receipt.status,1);});

    });

    it("should stoppable from giver and start again", function() {
            return remittance.runSwitch(false, {from:giver})
            .then(txObject => remittance.runSwitch(true, {from:giver}))
            .then(txObject => remittance.running())
            .then(runningVar => assert.strictEqual(runningVar,true));

    });

    it("should not stoppable from payee", function() {
            return expectedException(
                () => remittance.runSwitch(false, {from:payee, gas: 3000000 }),
                3000000);
    });


  });

  describe("refund",function(){
      
      let _hashPwdKnownByPayee, _hashPwdKnownByExchange;
      let txObj;
      let giverBalance = 0;
      let contractBalance=0;
      let valToSend = 1000;

      before("createHashOfPwd", function() {
          return remittance.hashWithKeccak256(pwdPayee)
              .then(hash => _hashPwdKnownByPayee = hash)
              .then(() => remittance.hashWithKeccak256(pwdExchange))
              .then(hash => _hashPwdKnownByExchange = hash);
      });

      // deposit first
      beforeEach("deposit for payee and get balance of contract and giver", function() {
          return remittance.deposit.sendTransaction( exchange,payee, _hashPwdKnownByExchange,_hashPwdKnownByPayee, 350, { from: giver,value:valToSend})
              .then(txHash => web3.eth.getBalancePromise(remittance.address))
              .then(balance => 
                  {
                    assert.strictEqual(balance.toString(10), valToSend.toString(10));
                    contractBalance = balance;
                    //console.log("contractBalance:" + contractBalance);
                    return web3.eth.getBalancePromise(giver);
                  })
              .then(balance=>giverBalance = balance );
      });


      it("should refund after deposit", function() {
            let txFee;

            return remittance.refund(exchange,payee,{from:giver})
              .then(txObject => web3.eth.getTransactionPromise(txObject.tx).then(tx => txFee = tx.gasPrice.times(txObject.receipt.gasUsed)))
              .then(() => web3.eth.getBalancePromise(giver))
              .then(balance=> {
                    // Check giver Balance
                    //console.log("txFee=" + txFee);
                    assert.strictEqual(balance.toString(10), web3.toBigNumber(giverBalance).plus(valToSend).minus(txFee).toString(10));
                    //console.log("giverBalance before:" + giverBalance );
                    //console.log("giverBalance after:" + balance );
                    });
    
      });

      it("should not refund after withdraw", function() {
            return remittance.withdraw(exchange, pwdExchange,pwdPayee, { from: payee})
              .then(txObject => web3.eth.getBalancePromise(remittance.address))
              .then(balance => assert.strictEqual(balance.toString(10), (contractBalance-valToSend).toString(10) ) )
              .then(() => expectedException(() => remittance.refund(exchange,payee,{from:giver, gas: 3000000 }),3000000)); 
              
      });
 


  });




});
