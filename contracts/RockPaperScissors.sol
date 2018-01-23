pragma solidity ^0.4.6;

import "./SoftKillable.sol";

contract RockPaperScissors is SoftKillable
{

	enum ActionChoice { None,Rock, Paper, Scissor }
	enum MatchState {NotSet,Enroll,Started,BetsMade,Ended}

	struct MatchStruct
	{
		MatchState state;
		address player1 ;
		address player2;
		uint expirationBlock;
		bytes32 hashMove1;
		bytes32 hashMove2;
	}
	
	mapping(address=>uint) winnerList;
	mapping(bytes32=>MatchStruct) matchList;
	uint blockForExpiration=50 ; // (10 minutes * 60 sec / 12 sec x block )  -> how many blocks in 10 minutes
	uint betAmount = 1 finney;

	function enrollMatch(address competitor) 
		payable
		returns(bytes32 hashMatchId)
	{
		require(msg.value==betAmount);
		require(competitor!=address(0));

		if(msg.sender>competitor) // because this function is invoked by player1 and player2, calculate hashMatchId in the same way!
			hashMatchId=keccak256(msg.sender,competitor);
		else
			hashMatchId=keccak256(competitor,msg.sender);
		
		if(matchList[hashMatchId].state==MatchState.NotSet)
		{
			// new 
			matchList[hashMatchId] = MatchStruct(MatchState.Enroll,msg.sender,competitor,block.number + blockForExpiration,bytes32(0),bytes32(0));
		}
		else
		{
			// exist, enroll?
			MatchStruct storage matchTmp = matchList[hashMatchId];
			require(matchTmp.state==MatchState.Enroll);
			require(msg.sender==matchTmp.player2); //the player1 is the first that enroll	
			require(matchTmp.expirationBlock >= block.number); // not expired

			matchList[hashMatchId].state = MatchState.Started;		
		}

	}


	// vote: 0: None 1: rock, 2: paper, 3: scissors
	function bet(bytes32 hashMatchId,uint8 vote,bytes32 _secretPwd) 
	{
		MatchStruct storage matchTmp = matchList[hashMatchId];
		require(matchTmp.state==MatchState.Started);
		require(matchTmp.expirationBlock >= block.number); // not expired
		require(vote>0 && vote<4);
		require(_secretPwd.length>0);

		if(matchTmp.player1 == msg.sender  && matchTmp.hashMove1 ==bytes32(0)) // hash not set
		{
			matchTmp.hashMove1 = keccak256(_secretPwd,matchTmp.player1,vote); 
		}
		else if(matchTmp.player2 ==msg.sender &&  matchTmp.hashMove2==bytes32(0)) // hash not set
		{
			matchTmp.hashMove2 = keccak256(_secretPwd,matchTmp.player2,vote); 
			matchTmp.state= MatchState.BetsMade;
		}
		else
		{
			revert();
		}
		
	}
	
	function getWinnings(bytes32 hashMatchId,bytes32 _secretPwd1,bytes32 _secretPwd2)
		returns(address winner)
	{
		MatchStruct storage matchTmp = matchList[hashMatchId];
		require(matchTmp.state==MatchState.BetsMade);
		require(matchTmp.expirationBlock >= block.number); // expiration
		require(matchTmp.player1 == msg.sender ||  matchTmp.player2==msg.sender);
		require(_secretPwd1.length>0 && _secretPwd2.length>0);

		// Who is the winner?

		ActionChoice movePlayer1 = ActionChoice.None;
		ActionChoice movePlayer2 = ActionChoice.None;

		if(keccak256(_secretPwd1,matchTmp.player1,ActionChoice.Rock) == matchTmp.hashMove1)
			movePlayer1 = ActionChoice.Rock;
		else if(keccak256(_secretPwd1,matchTmp.player1,ActionChoice.Paper) == matchTmp.hashMove1 )
			movePlayer1 = ActionChoice.Paper;
		else if(keccak256(_secretPwd1,matchTmp.player1,ActionChoice.Scissor) == matchTmp.hashMove1 )
			movePlayer1 = ActionChoice.Scissor;
		else
			revert();


		if(keccak256(_secretPwd2,matchTmp.player2,ActionChoice.Rock) == matchTmp.hashMove2)
			movePlayer2 = ActionChoice.Rock;
		else if(keccak256(_secretPwd2,matchTmp.player2,ActionChoice.Paper) == matchTmp.hashMove2 )
			movePlayer2 = ActionChoice.Paper;
		else if(keccak256(_secretPwd2,matchTmp.player2,ActionChoice.Scissor) == matchTmp.hashMove2 )
			movePlayer2 = ActionChoice.Scissor;
		else
			revert();
        
        if(movePlayer1 == movePlayer2)
        {
            winnerList[matchTmp.player1]+= betAmount;
            winnerList[matchTmp.player2]+= betAmount;
        }
        else
		{
    		if( (movePlayer1 == ActionChoice.Paper && movePlayer2 == ActionChoice.Rock) || 
    			(movePlayer1 == ActionChoice.Rock && movePlayer2 == ActionChoice.Scissor) ||
    			(movePlayer1 == ActionChoice.Scissor && movePlayer2 == ActionChoice.Paper) )
    			
    			winner = matchTmp.player1;
    		else
    			winner = matchTmp.player2;
    
    		winnerList[winner]+= betAmount*2;
		}
		matchTmp.state== MatchState.Ended;
		matchTmp.hashMove1 = bytes32(0);
        matchTmp.hashMove2 = bytes32(0);
	}


	function withdraw() returns(bool)
	{
		require(winnerList[msg.sender]>0);

		uint amount = winnerList[msg.sender];
		winnerList[msg.sender]=0;
		msg.sender.transfer(amount);
		return true;
	}

	function refund(bytes32 matchid) returns(bool)
	{
		MatchStruct storage matchTmp = matchList[matchid];
		require(matchTmp.player1 == msg.sender ||  matchTmp.player2==msg.sender);
		require(matchTmp.expirationBlock < block.number); // only if expired

		address tmpAddress = address(0);
		if(matchTmp.player1 == msg.sender)
		{
			tmpAddress = matchTmp.player1;
			matchTmp.player1 = address(0);	
		}
		else
		{
			tmpAddress = matchTmp.player2;
			matchTmp.player2 = address(0);		
		}

		tmpAddress.transfer(betAmount);
				
		return true;
	}

}