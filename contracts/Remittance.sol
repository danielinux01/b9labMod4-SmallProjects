pragma solidity ^0.4.6;

import "./Stoppable.sol";

contract Remittance is Stoppable
{
	
	struct PendingOperation {
		address senderAddress;
		uint amount;
		uint deadline;
		bytes32 hashPwdKnownByExchange;
		bytes32 hashPwdKnownByPayee;
		
	}

	event LogDeposited( address indexed fromAddress,address indexed toAddress,address indexed exchange, uint amount,uint blockLimit);
    
    event LogWithdrawn(address indexed fromAddress, address indexed toAddress,address indexed exchange,uint amount);
    
    event LogRefund(address indexed fromAddress,address indexed toAddress,address indexed exchange,uint amount);


	struct PendingOperations
	{
		// map with recipient address
		mapping(address=>PendingOperation) operationsList;
	}

	// map with exchange address
	mapping(address => PendingOperations) pendingOperations;

	uint avgBlockTime=12 ;


	function hashWithKeccak256(bytes32 password)
        constant public
        returns(bytes32 hash) {
        return keccak256(password);
    }

	// Called by Alice
	// Add deposit function with 
	// msg.sender= (Alice), Recipient address=(Bob), ExchangeAddress = (Carl)
	// hashPwdKnownByExchange and hashPwdKnownByPayee = keccak256 (pwd_in_plain)
	function deposit(address exchange,address recipient,bytes32 _hashPwdKnownByExchange,bytes32 _hashPwdKnownByPayee,uint durationInMinutes)
		public
		onlyIfRunning
		payable
		returns(bool) 
	{
		// check value
		require (msg.value>0); 
		// check address validity
		require(exchange!=address(0));
		require(recipient!=address(0));
		// check pwd validity
		require(_hashPwdKnownByPayee.length>0);
		require(_hashPwdKnownByExchange.length>0);
		// check duration
		require(durationInMinutes>0);

		require(pendingOperations[exchange].operationsList[recipient].amount==0); // Is struct already used?

		uint blockLimit = block.number + (durationInMinutes*60)/avgBlockTime ;
		pendingOperations[exchange].operationsList[recipient] = PendingOperation(msg.sender,msg.value,blockLimit ,_hashPwdKnownByExchange,_hashPwdKnownByPayee);

 		LogDeposited( msg.sender,recipient,exchange, msg.value,blockLimit);

		return true;
	}

	// Called by Bob
	function withdraw(address exchange, bytes32 pwdKnownByExchange,bytes32 pwdKnownByPayee)
		public
		onlyIfRunning
		returns(bool)
	{
		// check address validity
		require(exchange!=address(0));
		// check pwd validity
		require(pwdKnownByExchange.length>0);
		require(pwdKnownByPayee.length>0);

		// use a pointer to struct...
		PendingOperation storage pendingOp = pendingOperations[exchange].operationsList[msg.sender];

		require(keccak256(pwdKnownByExchange) == pendingOp.hashPwdKnownByExchange);
		require(keccak256(pwdKnownByPayee)    == pendingOp.hashPwdKnownByPayee);
		require(pendingOp.deadline >= block.number);

		require(pendingOp.amount>0); // is current struct element empty?

		LogWithdrawn(pendingOp.senderAddress,msg.sender,exchange,amount);

		uint amount 			= pendingOp.amount;
		pendingOp.amount 		= 0;
		pendingOp.deadline 		= 0;
		pendingOp.senderAddress = 0;

		
		msg.sender.transfer(amount);

		return true; 
	}
	    
	// In this contract, Alice can use different exchanges for sent ether to different recipient
	// but she can't use the same exchange to send ether to different recipients
	// Alice can specify exchange and recipient address 
	function refund(address exchange,address recipient)
		public
		onlyIfRunning
		returns(bool)
	{
		require(exchange!=address(0));
		require(recipient!=address(0));
		
		PendingOperation storage pendingOp = pendingOperations[exchange].operationsList[recipient];

		require(pendingOp.amount>0);						// check struct element empty or not (exist for current exchange/recipient)
		require(pendingOp.deadline >= block.number);			// check expiration
		require(pendingOp.senderAddress == msg.sender);		// check correct sender

		LogRefund(msg.sender,recipient,exchange,pendingOp.amount);
				
		uint amount 			= pendingOp.amount;
		pendingOp.amount 		= 0;
		pendingOp.deadline 		= 0;
		pendingOp.senderAddress = 0;
		msg.sender.transfer(amount);
	    
		return true;

	}
	
}