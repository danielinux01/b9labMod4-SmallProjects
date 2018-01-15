pragma solidity ^0.4.6;

contract SoftKill
{
    address public owner;
    bool internal bStopSignal;
    
    event LogSelfDestruct(address indexed owner,uint amount);
    event LogDestroySignal(address indexed owner,uint amount);
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
    
    
    modifier onlyowner 
    { 
          require (msg.sender == owner);
          _;
    }
    
    function stopSignal()
      public
      onlyowner
      isAlive
      returns (bool)
    {
        bStopSignal = true;
        LogStopSignal();
        return true;
    }

    function destroy() 
        public
        onlyowner
        isStopped
        returns(bool)
    {
        
        if(this.balance>0)
          owner.transfer(this.balance);
        
        LogDestroySignal(owner,this.balance);   
        
        return killMe(); // call the private killMe
    }

    function killMe() 
      private
      onlyowner
      returns (bool) 
    {
      
      
      LogSelfDestruct(owner,this.balance);
      selfdestruct(owner);
      return true;
    }
}

contract Remittance is SoftKill
{
	
    struct PendingOperation {
		address senderAddress;
		uint amount;
		uint deadline;
		bytes32 pwdKnownByExchange;
		bytes32 pwdKnownByPayee;
		bool used;
		
	}

	struct PendingOperations
	{
		// map with recipient address
		mapping(address=>PendingOperation) operationsList;
	}

	// map with exchange address
	mapping(address => PendingOperations) pendingOperations;
    
    bool bStopSignal;
    uint avgBlockTime=12 ;

    function Remittance()
    	public
	{
		owner = msg.sender;
	}

	// Add deposit function with 
	// msg.sender= (A), Recipient address=(B), ExchangeAddress = (C)
	// pwdKnownByExchange and pwdKnownByPayee = keccak256 (pwd_in_plain)
	function deposit(address exchange,address recipient,bytes32 pwdKnownByExchange,bytes32 pwdKnownByPayee,uint durationInMinutes)
		public
		isAlive
		payable
		returns(bool) 
	{
        require (msg.value>0); // check value
		// check address validity
		require(exchange!=address(0));
		require(recipient!=address(0));
        // check pwd validity
		require(pwdKnownByPayee.length>0);
		require(pwdKnownByExchange.length>0);
        require(durationInMinutes>0);
		
		if(pendingOperations[exchange].operationsList[recipient].used==false)
		{
			pendingOperations[exchange].operationsList[recipient] = PendingOperation(msg.sender,msg.value,block.number + (durationInMinutes*60)/avgBlockTime  ,pwdKnownByExchange,pwdKnownByPayee,true);
		}
		else
			revert(); // pending operation exist,revert!

        return true;
	}
    
    
    function withdraw(address recipient, string pwdKnownByExchange,string pwdKnownByPayee)
        public
        isAlive
        returns(bool)
    {
		// check address validity
		require(recipient!=address(0));
        // check pwd validity
		require(bytes(pwdKnownByExchange).length>0);
		require(bytes(pwdKnownByPayee).length>0);
        
        // use a pointer to struct...
        PendingOperation storage pendingOp = pendingOperations[msg.sender].operationsList[recipient];
        
        require(pendingOp.used==true); // is used?
        
        if(keccak256(pwdKnownByExchange) == pendingOp.pwdKnownByExchange &&
           keccak256(pwdKnownByPayee)    == pendingOp.pwdKnownByPayee &&
           pendingOp.deadline >= block.number)
        {
            uint amount = pendingOp.amount;
            pendingOp.amount = 0;
            pendingOp.used = false; 
            msg.sender.transfer(amount);
        }
        else
            revert();
        
        return true; 
    }
    
    
	// In this contract, Alice can use different exchanges for sent ether to different recipient
	// but she can't use the same exchange to send ether to different recipient
	// Alice can specify exchange and recipient address 
	function refund(address exchange,address recipient)
	    public
	    isAlive
	    returns(bool)
	{
	    require(exchange!=address(0));
	    
	    PendingOperation storage pendingOp = pendingOperations[exchange].operationsList[recipient];
	    
	    if(pendingOp.used==true && 
	       pendingOp.deadline < block.number)
	    {
	        // check expiration
	        uint amount = pendingOp.amount;
            pendingOp.amount = 0;
            pendingOp.used = false;
            msg.sender.transfer(amount);
	    }
	    else
	        revert();
	        
	    return true;
	   
	}
	
	/*
	// Commented for debug (and view not compile, why?!
	function getCurrentDeadline(address exchange,address recipient)
        view
	    public
	    returns(uint deadline,uint currentblock)
	{
	    PendingOperation storage pendingOp = pendingOperations[exchange].operationsList[recipient];
	    deadline=pendingOp.deadline;
	    currentblock = block.number;
	}
	*/

}