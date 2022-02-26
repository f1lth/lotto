pragma solidity 0.8.10;

contract Lotto {
    // list of open pots
    Lottery[] private lotteries;

    function returnAllPots() external view returns(Lottery[] memory) {
        return lotteries;
    }

}


contract Lottery {
    // Data structures
    enum State {
        Open,
        Payout,
        Closed
    }
    // State Variables
    address payable public winner;     // Winner of pot
    uint public currentAmt;            // Current value of pot
    uint public minEntry;         // Min to enter 
    string public rules;           // rules of pot
    State public state = State.Open;   // Start contract on open
    mapping (address => uint) public participants;

    event depositFunds(address sender, uint amt);
    
    modifier inState(State _state) {
        require (state == _state);
        _;
    }

    constructor
        (
            address payable lottoWinner


        ) public {
            winner = lottoWinner;
            currentAmt = 0;
    }
    

}