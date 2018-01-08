pragma solidity ^0.4.6;

contract Splitter
{
    address public owner;
    
    address giver;
    address payee1;
    address payee2;
  
    event LogContribution(address sender,uint amount);
    event LogTransferToPayee1(address payee,uint amount);
    event LogTransferToPayee2(address payee,uint amount);
    
  
    //********************************************************************
    // Constructor
    //********************************************************************
    function Splitter(address _giver,address _payee1,address _payee2)
    {
        
      owner = msg.sender;
      giver = _giver;
      payee1 = _payee1;
      payee2 = _payee2;
    }
  
    //********************************************************************
    //we can see the balance of the Splitter contract on the web page
    //********************************************************************
    function getBalance() constant returns (uint) {
      return this.balance;
    }
    //--------------------------------------------------------------------
  
    //********************************************************************
    // we can see the balances of Alice, Bob and Carol on the web page
    //********************************************************************
    function getBalanceOfGiver() constant returns (uint) {
       return giver.balance;
    }
    
    function getBalanceOfPayee1() constant returns (uint) {
       return payee1.balance;
    }
    
    function getBalanceOfPayee2() constant returns (uint) {
      return payee2.balance;
    }
    //--------------------------------------------------------------------
  
    //********************************************************************
    // whenever Alice sends ether to the contract, half of it goes to Bob and the other half to Carol
    //********************************************************************
    function split() 
        payable
        returns(bool success)
    {
      require(msg.value>0 && msg.value%2==0); // >0 and divisible
      require(msg.sender == giver);
      
      uint valToSend = msg.value / 2;
      
      payee1.transfer(valToSend);
      LogTransferToPayee1(payee1,valToSend);
      
      payee2.transfer(valToSend);
      LogTransferToPayee2(payee2,valToSend);
      
      return true;
    }
    //--------------------------------------------------------------------
  
    //********************************************************************
    //we can send ether to it from the web page
    //********************************************************************
    function() payable
    {
      // Log event 
      LogContribution(msg.sender,msg.value);
    }
    //--------------------------------------------------------------------
    
    //todo: make the contract a utility that can be used by David, Emma and 
    //anybody with an address to split Ether between any 2 other addresses of their own choice
      
    //********************************************************************
    //add a kill switch to the whole contract
    //********************************************************************
    function killMe() returns (bool) {
        require(msg.sender == owner);
    selfdestruct(owner);
        return true;
    }
    //--------------------------------------------------------------------
}