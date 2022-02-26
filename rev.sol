pragma solidity 0.8.10;

contract LotteryProject {
    // List of existing projects
    Lottery[] private lotteries;

    // Event that will be emitted whenever a new project is started
    event LotteryStarted(
        address contractAddress,
        string projectTitle,
        string projectDesc,
        uint265 entrance,
        uint256 duration,
    );

    /** @dev Function to start a new project.
      * @param title Title of the project to be created
      * @param description Brief description about the project
      * @param durationInDays Project deadline in days
      * @param amountToRaise Project goal in wei
      */
    function startProject(
        string calldata title,
        string calldata description,
        uint durationInDays,
        uint entryFee
    ) external {
        uint raiseUntil = now + durationInDays;
        Lottery newLotto = new Lottery(msg.sender, title, description, raiseUntil, entryLowerbound);
        lotteries.push(newLotto);
        emit LotteryStarted(
            address(newLotto),
            msg.sender,
            title,
            description,
            raiseUntil,
            entryLowerbound
        );
    }                                                                                                                                   

    /** @dev Function to get all projects' contract addresses.
      * @return A list of all projects' contract addreses
      */
    function getAllLotteries() external view returns(Lottery[] memory){
        return lotteries;
    }
}

contract Lottery {
    // Data structures
    enum State {
        Open,
        Terminated,
        Expired
    }

    // State variables
    address payable public winner;
    uint public maxPlayers; // payout when threshold number of players hit
    uint public numPlayers; // number of players in a given project
    uint256 public currentBalance;
    uint public entrance;  // how much a player will put into a given pot specified at initialization
    string public title;  
    uint public raiseBy;  
    State public state = State.Open; // initialize on create
    mapping (address => bool) public playersIn;
    mapping (address => uint) public players;

    // Event that will be emitted whenever funding will be received
    event PlayerJoins(address contributor, uint amount, uint currentTotal);
    // Event that will be emitted whenever the winner has received the funds
    event WinnerPaid(address winner);

    // Modifier to check current state
    modifier inState(State _state) {
        require(state == _state);
        _;
    }

    constructor
    (
        string memory projectTitle,
        uint fundRaisingDeadline,
        uint playerLimit,
        uint entranceFee, 
    ) public {
        title = projectTitle;
        maxPlayers = playerLimit;
        raiseBy = fundRaisingDeadline;
        entrance = entranceFee;
        currentBalance = 0;
        numPlayers = 0;
    }

     /** @dev Function to see if player already in the pot
      */
    function contains(address _player) private returns (bool){
        return playersIn[_player];
    }

     /** @dev Function to generate random number
      */
    function random() private view returns (uint) {
        // sha3 and now have been deprecated
        return uint(keccak256(abi.encodePacked(block.difficulty, block.timestamp, players)));
        // convert hash to integer
        // players is an array of entrants
    }

    /** @dev Function to fund a certain project.
      */
    function contribute() external inState(State.Open) payable {
        require(contains(msg.sender) == false);
        require(numPlayers + 1 <= maxPlayers);
        require(msg.value == raiseBy);
        // put into active players array
        players[msg.sender] = true;
        // incremement players
        numPlayers += 1;
        currentBalance = currentBalance.add(msg.value);
        // check if this player would terminate game.
        checkIfFundingCompleteOrExpired();
    }

    /** @dev Function to change the project state depending on conditions.
      */
    function checkIfFundingCompleteOrExpired() public {
        if (numPlayers = maxPlayers) {
            state = State.Terminated;
            // max players reached, calculate winner and pay
            getWinner();
        } else if (now > raiseBy)  {
            // project has expired. refund all members but IDK who is paying gas LMAO
            state = State.Terminated;
            getWinner();
        }
    }

    /** @dev Function to get winner of lotto and payout
      */
    function getWinner() internal inState(State.Terminated) returns (bool) {
        uint256 totalRaised = currentBalance;
        currentBalance = 0;
        // generate a "random" number - could use chainLINK but im broke 
        // so here is a psudorandom number 
        // but tbh, id be pissed if my lottery was 
        // determined by a psudorandom rng... anyway

        // yeah this is really bad but im not paying for an oracle.
        // given a known block hash, win 100% by only join pools that are 
        // in block hash % n and join when pool is filled with k/5 players
        // == you can always win lol... 
        uint winningIndex = random() % players.length;
        winner = players[winningIndex];
        // payout.
        if (winner.send(totalRaised)) {
            emit WinnerPaid(winner);
            return true;
        } else {
            // handle failed transaction
            currentBalance = totalRaised;
            // not sure abt this line, but if transaction fails what shoudl i do?
            return false;
        }
    }

    /** @dev Function to get specific information about the project.
      * @return Returns all the project's details
      */
    function getDetails() public view returns 
    (
        address payable projectStarter,
        string memory projectTitle,
        string memory projectDesc,
        uint256 deadline,
        State currentState,
    ) {
        lottoWinner = winner;
        projectTitle = title;
        projectDesc = description;
        deadline = raiseBy;
        currentState = state;
    }
}