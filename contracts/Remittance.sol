pragma solidity ^0.4.6;

import "./SoftKillable.sol";

contract Remittance is SoftKillable
{
	
	struct PendingOperation {
		address senderAddress;
		uint amount;
		uint deadline;
		bytes32 hashPwdKnownByExchange;
		bytes32 hashPwdKnownByPayee;
		
	}

	struct PendingOperations
	{
		// map with recipient address
		mapping(address=>PendingOperation) operationsList;
	}

	// map with exchange address
	mapping(address => PendingOperations) pendingOperations;

	uint avgBlockTime=12 ;

	// Add deposit function with 
	// msg.sender= (A), Recipient address=(B), ExchangeAddress = (C)
	// hashPwdKnownByExchange and hashPwdKnownByPayee = keccak256 (pwd_in_plain)
	function deposit(address exchange,address recipient,bytes32 _hashPwdKnownByExchange,bytes32 _hashPwdKnownByPayee,uint durationInMinutes)
		public
		isAlive
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

		require(pendingOperations[exchange].operationsList[recipient].amount>0); // Is struct already used?

		pendingOperations[exchange].operationsList[recipient] = PendingOperation(msg.sender,msg.value,block.number + (durationInMinutes*60)/avgBlockTime  ,_hashPwdKnownByExchange,_hashPwdKnownByPayee);

		return true;
	}


	function withdraw(address recipient, bytes32 pwdKnownByExchange,bytes32 pwdKnownByPayee)
		public
		isAlive
		returns(bool)
	{
		// check address validity
		require(recipient!=address(0));
		// check pwd validity
		require(pwdKnownByExchange.length>0);
		require(pwdKnownByPayee.length>0);

		// use a pointer to struct...
		PendingOperation storage pendingOp = pendingOperations[msg.sender].operationsList[recipient];

		require(keccak256(pwdKnownByExchange) == pendingOp.hashPwdKnownByExchange);
		require(keccak256(pwdKnownByPayee)    == pendingOp.hashPwdKnownByPayee);
		require(pendingOp.deadline >= block.number);

		require(pendingOp.amount>0); // is current struct element empty?

		uint amount = pendingOp.amount;
		pendingOp.amount = 0;
		msg.sender.transfer(amount);


		return true; 
	}
    
    
	// In this contract, Alice can use different exchanges for sent ether to different recipient
	// but she can't use the same exchange to send ether to different recipients
	// Alice can specify exchange and recipient address 
	function refund(address exchange,address recipient)
		public
		isAlive
		returns(bool)
	{
		require(exchange!=address(0));

		PendingOperation storage pendingOp = pendingOperations[exchange].operationsList[recipient];

		require(pendingOp.amount>0);						// check struct element empty or not (exist for current exchange/recipient)
		require(pendingOp.deadline < block.number);			// check expiration
		require(pendingOp.senderAddress == msg.sender);		// check correct sender

		uint amount = pendingOp.amount;
		pendingOp.amount = 0;
		msg.sender.transfer(amount);
	    
		return true;

	}
	
}