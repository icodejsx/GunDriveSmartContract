// SPDX-License-Identifier: MIT


pragma solidity ^0.8.28;

// We need USDC interface again — same as GameSkins
interface IUSDC {
    function transferFrom(address from, address to, uint256 amount) 
        external returns (bool);
    function transfer(address to, uint256 amount) 
        external returns (bool);
    function balanceOf(address account) 
        external view returns (uint256);
}


contract StakeToPlay {

    address public owner;
    address public usdcAddress;

    //----ENUM-----------------------
    // A match can only be in one of these states 
    enum MatchStatus {
        WAITING,   // Created, waiting for players to join
        ACTIVE,    // Match is been played 
        FINISHED,  // rewards has been paid 
        CANCELLED  // Match was cancelled reward refunded 
    }

    // -----STRUCT------------------------
    // Everything about the match lives here.  
    // Thhink of it as one row in a data base 
    struct Match {
        uint256 matchId;
        address[] players;
        uint256 stakeAmount;
        uint256 totalPot;
        MatchStatus status;
        bool exists;
    }
    

    //----STORAGE -----------------------------
    // matchId => Match Struct
    // "give me match number 5 → get all its data"
    mapping(uint256 => Match) public matches;

    // Generate a unique match ID
    uint256 public matchGenerator; 

     // ── MODIFIER ─────────────────────────────────────────
    modifier onlyOwner() {
        require(msg.sender == owner, "Only owner can call this");
        _;
    }

      // ── CONSTRUCTOR ──────────────────────────────────────
      // address assign used to call the or deploy is == the usdcaddress
    constructor(address _usdc) {
        owner = msg.sender;
        usdcAddress = _usdc;
    }


    // ── EVENTS ───────────────────────────────────────────
    // Events are like notifications — Unity listens for these
    // When emitted, Unity knows something happened on-chain
    event MatchCreated(uint256 matchId, address creator, uint256 stakeAmount);
    event PlayerJoined(uint256 matchId, address player);
    event MatchStarted(uint256 matchId);
    event RewardsPaid(uint256 matchId, address first, address second);



    // ---- CREATE A MATCH--------------------------
    function createMatch (uint256 stakeAmount) public returns (uint256) {
        // must stake at list 1 usdc 
        require(stakeAmount >= 1 * 10**6, "Minimun stake is 1 Usdc");

         // Pull stake from creator's wallet into this contract
        // Creator must have called USDC.approve() first
        bool success = IUSDC(usdcAddress).transferFrom(
            msg.sender,
            address(this),
            stakeAmount
        );
        require(success, "USDC transfer failed");

        // Generate a unique Match ID 
        matchGenerator++;
        uint256 newMatchId = matchGenerator;

        // Create empty players array then push creator in
        address[] memory initialPlayers = new address[](1);
        initialPlayers[0] = msg.sender;

        // Store the new match in our mapping
        matches[newMatchId] = Match({
            matchId:     newMatchId,
            players:     initialPlayers,
            stakeAmount: stakeAmount,
            totalPot:    stakeAmount,
            status:      MatchStatus.WAITING,
            exists:      true
        });

        // Fire the event so Unity knows a match was created
        emit MatchCreated(newMatchId, msg.sender, stakeAmount);

        return newMatchId;

    }


    //-- JOIN A MATCH --------------------------------------

    function JoinMatch(uint256 matchId) public  {
        // safty checks 
       require(matches[matchId].exists, "Match does not exist");
        require(matches[matchId].status == MatchStatus.WAITING, "Match is not open");
        require(matches[matchId].players.length < 4 , "Match is full");

        // Make sure player isnt already in this match
        address[] memory players = matches[matchId].players;
        for (uint256 i = 0; i < players.length; i++) {
            require(players[i] != msg.sender, "Already in this match");
        }

          // Pull stake from joining player
        bool success = IUSDC(usdcAddress).transferFrom(
            msg.sender,
            address(this),
            matches[matchId].stakeAmount  // must match creator's stake
        );
        require(success, "USDC transfer failed");

        // Add player to match
        matches[matchId].players.push(msg.sender);
        matches[matchId].totalPot += matches[matchId].stakeAmount;

        emit PlayerJoined(matchId, msg.sender);

        // If 2+ players joined, match is ready to start
        if (matches[matchId].players.length >= 2) {
            matches[matchId].status = MatchStatus.ACTIVE;
            emit MatchStarted(matchId);
        }

    }



        // ── SUBMIT SCORES ────────────────────────────────────
        // ONLY your game server calls this after match ends
        // players[] and scores[] must be in same order
        // players[0] scored scores[0], players[1] scored scores[1] etc.

        function submitScores (uint256 matchId, address[] memory players, uint256[] memory scores ) public onlyOwner {

            // safty checks 
            require(matches[matchId].exists, "Match does not exist");
            require(matches[matchId].status == MatchStatus.ACTIVE, "Match not active");
            require(players.length == scores.length, "Player and scores array size mismatch");
            require(players.length >= 2, "Need atleast 2 player ");

            // Find 1st and 2nd place by looping through scores
            address firstPlace;
            address secondPlace;
            uint256 highestScore;
            uint256 secondScore;

            for (uint256 i = 0; i < players.length; i++) {

                if (scores[i] > highestScore) {
                // This player beats current 1st place
                // Old 1st place drops to 2nd place
                secondPlace = firstPlace;
                secondScore = highestScore;

                // New 1st place
                firstPlace  = players[i];
                highestScore = scores[i];

                } else if (scores[i] > secondScore) {
                // This player beats current 2nd place
                secondPlace = players[i];
                secondScore = scores[i];
                }
            }
                 // Now pay out the winners
                 _distributeRewards(matchId, firstPlace, secondPlace);


        }

    // ── DISTRIBUTE REWARDS ───────────────────────────────
    // internal = only THIS contract can call it
    // nobody outside can call it directly
    function _distributeRewards(
        uint256 matchId,
        address firstPlace,
        address secondPlace
    ) internal {

        uint256 totalPot = matches[matchId].totalPot;

        // 70% to 1st place
        // We do multiply BEFORE divide to avoid decimal problems
        uint256 firstReward  = (totalPot * 70) / 100;

        // 30% to 2nd place
        uint256 secondReward = (totalPot * 30) / 100;

        // Mark match as finished BEFORE sending money
        // This prevents a hacking technique called reentrancy
        matches[matchId].status = MatchStatus.FINISHED;

        // Send USDC to winners
        IUSDC(usdcAddress).transfer(firstPlace, firstReward);
        IUSDC(usdcAddress).transfer(secondPlace, secondReward);

        emit RewardsPaid(matchId, firstPlace, secondPlace);
    }

    // ── CANCEL MATCH ─────────────────────────────────────
    // If nobody joins, creator can cancel and get refund
    function cancelMatch(uint256 matchId) public {
        require(matches[matchId].exists, "Match does not exist");
        require(
            matches[matchId].status == MatchStatus.WAITING,
            "Can only cancel waiting matches"
        );
        require(
            matches[matchId].players[0] == msg.sender,
            "Only creator can cancel"
        );

        // Mark cancelled first (security)
        matches[matchId].status = MatchStatus.CANCELLED;

        // Refund the creator
        IUSDC(usdcAddress).transfer(
            msg.sender,
            matches[matchId].stakeAmount
        );
    }

    // ── VIEW MATCH INFO ──────────────────────────────────
    // Unity calls this to show match details in the lobby
    function getMatch(uint256 matchId) public view returns (
        uint256 id,
        uint256 playerCount,
        uint256 stakeAmount,
        uint256 totalPot,
        MatchStatus status
    ) {
        require(matches[matchId].exists, "Match does not exist");
        Match storage m = matches[matchId];
        return (
            m.matchId,
            m.players.length,
            m.stakeAmount,
            m.totalPot,
            m.status
        );
    }



}
