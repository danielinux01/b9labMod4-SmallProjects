pragma solidity ^0.4.6;

contract Splitter
{
    address public owner;
    
    address public giver;
    address public payee1;
    address public payee2;
  
    event LogContribution(address indexed sender,uint amount);
    event LogTransferToPayee(address indexed payee1,address indexed payee2,uint amount);
        
  
    //********************************************************************
    // Constructor
    //********************************************************************
    function Splitter(address _giver,address _payee1,address _payee2)
    {
      require(_giver!=address(0));
      require(_payee1!=address(0));  
      require(_payee2!=address(0));

      owner = msg.sender;
      giver = _giver;
      payee1 = _payee1;
      payee2 = _payee2;
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
      require(msg.value>0);
      require(msg.value%2==0); 
      require(msg.sender == giver);
      
      uint valToSend = msg.value / 2;
      
      payee1.transfer(valToSend);      
      payee2.transfer(valToSend);
      
      LogTransferToPayee(payee1,payee2,valToSend);

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