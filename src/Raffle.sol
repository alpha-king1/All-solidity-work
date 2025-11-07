// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface ERC721i 
{
    function balanceOf(address owner) external view returns (uint256);
}

contract Raffle {
    
    // ===== STATE VARIABLES =====
    ERC721i public nftContract;  // 0xc96eE45A7afe24f549B4480Cd60d7C2B7fd14871
    address public owner;
    uint256 public currentRaffleId;
    uint256 public prizePool;
    uint256 public raffleEndTime;//1765362692   set to december
    address[] public raffleAddress;

    event enteredRaffle (address useraddress, bool successful);
    event revealWinner(address winnerAddress, uint prize, bool successful);
    
    mapping(uint256 => address[]) public raffleEntries;  // raffleId => array of participants
    mapping(uint256 => mapping(address => bool)) public hasEntered;  // raffleId => user => entered?
    mapping(uint256 => address) public raffleWinners;  // raffleId => winner address

    constructor(ERC721i _contract, uint _firstRaffleEndTime)
    {
        nftContract = _contract;
        owner = msg.sender;
        prizePool = 50 * 1 ether;
        raffleEndTime = _firstRaffleEndTime;
        currentRaffleId = 1;
    }
    
    function enterRaffle() external payable
    {
        // Check if user holds NFT
        require(nftContract.balanceOf(msg.sender) > 0, "Not eligible: No NFT");

        // Check if raffle is still open
        require(block.timestamp < raffleEndTime, "Raffle has ended");

        // Check if user hasn't entered yet
        require(!hasEntered[currentRaffleId][msg.sender], "user already in draw");

        // Add user to entries
        raffleEntries[currentRaffleId].push(msg.sender);
        hasEntered[currentRaffleId][msg.sender] = true;

        (bool success, ) = (msg.sender).call{value:msg.value - 1 ether}("");
        require(success);    

        emit enteredRaffle(msg.sender, success); 
    }
    
    function hasUserEntered(address user) external view returns (bool) 
    {
        return hasEntered[currentRaffleId][user];
    }
    
    
    // 6. Get winner of a specific raffle
    function getWinner(uint256 raffleId) external view returns (address) 
    {
        return raffleWinners[raffleId];
    }
    
    // 8. Get total entries for current raffle
    function getTotalEntries() external view returns (uint256) 
    {
        return raffleEntries[currentRaffleId].length;
    }

    function isEligible(address user) external view returns (bool) 
    {
        //return nftContract.balanceOf(user) > 0;
    }
    

    // ===== ADMIN FUNCTIONS ===== 
    function selectWinner() external /*onlyOwner*/ {
        require(msg.sender == owner, "only owner can call this function");
        require(address(this).balance > prizePool, "not enough liquid");
        require(raffleEntries[currentRaffleId].length > 0, "No entries");

    
        // Generate random index
        uint256 randomIndex = uint256(keccak256(abi.encodePacked(
            block.timestamp,
            block.prevrandao,
            msg.sender
        ))) % raffleEntries[currentRaffleId].length;
    
        // Get winner
        address winner = raffleEntries[currentRaffleId][randomIndex];

        raffleWinners[currentRaffleId] = winner;
        currentRaffleId += 1;
        raffleEndTime += 6 days;
   
        (bool success, ) = winner.call{value: prizePool}("");
        require(success);
        
        emit revealWinner(msg.sender, prizePool, success);

        // Use Chainlink VRF or other randomness source
        // Pick random winner from raffleEntries
        // Transfer prize to winner
        // Start new raffle
    }

    function getContractBalance() public view returns (uint256) 
    {
        require(msg.sender==owner);
        return address(this).balance;
    }
    
    function fundPrizePool() external payable /*onlyOwner*/ 
    {
        prizePool += msg.value;
    }

    function ownerWithdraw(uint _amount) public 
    {
        require(msg.sender == owner, "only owners are allowed to withdraw this amount");
        uint value = _amount * 1 ether;
        (bool success, ) = owner.call{value: value}('');
        require(success, "fail to withdraw funds");

    }

}


    // function getCurrentRaffleId() external view returns (uint256) 
    // {
    //     return currentRaffleId;
    // }
    
    // function getRaffleEndTime() external view returns (uint256) 
    // {
    //     return raffleEndTime;
    // }
    
    // function getPrizePool() external view returns (uint256) 
    // {
    //     return prizePool;
    // }
    