pragma solidity ^0.4.6;

contract Owned
{
	address public owner;
	
	modifier onlyowner
    { 
          require (msg.sender == owner);
          _;
    }


	function Owned()
		public 
	{
		owner = msg.sender;
	}

}