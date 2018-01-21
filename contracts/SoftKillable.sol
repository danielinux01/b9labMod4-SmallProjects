pragma solidity ^0.4.6;

import "./Owned.sol";

contract SoftKillable is Owned
{
    
    bool public bStopSignal;
    
    event LogSelfDestruct(address indexed owner,uint amount);
    event LogStopSignal();
    
    modifier isAlive
    {
        require(!bStopSignal);
        _;
    }
    
    modifier isStopped
    {
        require(bStopSignal);
        _;
    }
            
    
    function stop()
      public
      onlyowner
      isAlive
      returns (bool)
    {
        bStopSignal = true;
        LogStopSignal();
        return true;
    }
    
    function killMe() 
      public
      onlyowner
      isStopped
      returns (bool) 
    {      
      LogSelfDestruct(owner,this.balance);
      selfdestruct(owner);
      return true;
    }
}