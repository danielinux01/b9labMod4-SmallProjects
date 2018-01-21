pragma solidity ^0.4.6;

import "./SoftKillable.sol";

contract Splitter is SoftKillable
{
    
    mapping(address => uint) public pendingWithdrawals;

    event LogPendingAmount(address indexed from,address indexed payee1,address indexed payee2,uint amount);
    event LogWithdraw(address indexed toAddress,uint amount);
    
    //********************************************************************
    // whenever Alice sends ether to the contract, half of it goes to Bob and the other half to Carol
    // make the contract a utility that can be used by David, Emma and 
    // anybody with an address to split Ether between any 2 other addresses of their own choice
    //********************************************************************
    // store how many ethers go to payee1 and payee2 without sending them
    function split(address payee1, address payee2) 
        public
        payable
        isAlive
        returns(bool success)
    {
      require(msg.value>0);         // Positive
      require((msg.value&1)==0);      // Divisible 
      require(payee1!=address(0));  // Check address
      require(payee2!=address(0));  // Check address
            
      uint valToSend = msg.value / 2;
      
      pendingWithdrawals[payee1]+=valToSend;
      pendingWithdrawals[payee2]+=valToSend;
            
      LogPendingAmount(msg.sender,payee1,payee2,valToSend);

      return true;
    }

    // Using Withdrawal pattern for transfer ether to msg.sender 
    // msg.sender must pay gas fee for withdraw
    function withdraw() 
      public 
      isAlive
      returns (bool result)
    {
        uint amount = pendingWithdrawals[msg.sender];
        require(amount>0); 
        
        pendingWithdrawals[msg.sender] = 0;
        LogWithdraw(msg.sender,amount);
        msg.sender.transfer(amount);
                
        return true;
      
    }
    //--------------------------------------------------------------------
  
    
    //********************************************************************
    //Fallback function: 
    //********************************************************************
    
    // Don't accidentally call other functions, revert!
    function() 
      public
    {
      revert();
    }
    //--------------------------------------------------------------------
          
}