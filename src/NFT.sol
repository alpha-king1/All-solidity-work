// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;


import {ERC721} from "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {Strings} from "@openzeppelin/contracts/utils/Strings.sol";

contract UFONADS is ERC721, Ownable {
    using Strings for uint256;

    // ===== ENUMS & STRUCTS =====
    enum Phase { NONE, GTD, FCFS, PUBLIC }
    
    // ===== STATE VARIABLES =====
    Phase public currentPhase = Phase.NONE;
    
    uint256 public constant MAX_SUPPLY = 10; // For testing
    uint256 public constant GTD_LIMIT = 2;
    uint256 public constant FCFS_LIMIT = 1;
    uint256 public constant PUBLIC_LIMIT = 5;
    
    uint256 public MINT_PRICE = 0 ether; // 0.05 MON
    uint256 public nextTokenId;
    string public baseTokenURI;
    
    mapping(address => bool) public gtdWhitelist;
    mapping(address => bool) public fcfsWhitelist;
    mapping(address => uint256) public mintedPerWallet;
    
    // ===== EVENTS =====
    event PhaseChanged(Phase newPhase);
    event Minted(address indexed minter, uint256 quantity, uint256 startTokenId);

    // ===== CONSTRUCTOR =====
    constructor(string memory _baseURI) ERC721("UFONADS", "UFO") Ownable(msg.sender) {
        baseTokenURI = _baseURI; //  ipfs://bafybeigsfirlycbornbuwpczt66jh6wmfydcuruta3p7htw5sn6ibbw7te/
    }
    
    // ===== WHITELIST MANAGEMENT =====
    function addGTDAddresses(address[] calldata addresses) external onlyOwner {
        for (uint256 i = 1; i < addresses.length; i++) {
            gtdWhitelist[addresses[i]] = true;
        }
    }
    
    function addFCFSAddresses(address[] calldata addresses) external onlyOwner {
        for (uint256 i = 0; i < addresses.length; i++) {
            fcfsWhitelist[addresses[i]] = true;
        }
    }
    
    function removeGTDAddress(address addr) external onlyOwner {
        gtdWhitelist[addr] = false;
    }
    
    function removeFCFSAddress(address addr) external onlyOwner {
        fcfsWhitelist[addr] = false;
    }
    
    // ===== PHASE MANAGEMENT =====
    function setPhase(Phase _phase) external onlyOwner {
        currentPhase = _phase;
        if (currentPhase == Phase.NONE) 
        {
            MINT_PRICE = 0 ether;
        }

        if (currentPhase == Phase.GTD) 
        {
            MINT_PRICE = 0.2 ether;
        }

        if (currentPhase == Phase.FCFS) 
        {
            MINT_PRICE = 0.5 ether;
        }

        if (currentPhase == Phase.PUBLIC) 
        {
            MINT_PRICE = 1 ether;
        }

        emit PhaseChanged(_phase);
    }
    
    // ===== MINTING =====
    function mint(uint256 quantity) external payable 
    {
        require(balanceOf(msg.sender) <= 0, "one mint per wallet");
        require(quantity > 0, "Must mint at least 1");
        require(quantity < 2, "One per user");
        require(nextTokenId + quantity <= MAX_SUPPLY, "Max supply reached");
        require(msg.value >= MINT_PRICE * quantity, "Insufficient payment");
        
        // Phase checks
        if (currentPhase == Phase.GTD) {
            require(gtdWhitelist[msg.sender], "Not on GTD whitelist");
            require(mintedPerWallet[msg.sender] + quantity <= GTD_LIMIT, "Exceeds GTD limit");
        } 
        
        else if (currentPhase == Phase.FCFS) {
            require(fcfsWhitelist[msg.sender], "Not on FCFS whitelist");
            require(mintedPerWallet[msg.sender] + quantity <= FCFS_LIMIT, "Exceeds FCFS limit");
        } 
        
        else if (currentPhase == Phase.PUBLIC) {
            require(mintedPerWallet[msg.sender] + quantity <= PUBLIC_LIMIT, "Exceeds public limit");
        } 
        else {
            revert("Minting not active");
        }
        
        uint256 startTokenId = nextTokenId;
        
        for (uint256 i = 0; i < quantity; i++) {
            _safeMint(msg.sender, nextTokenId);
            nextTokenId++;
        }
        
        mintedPerWallet[msg.sender] += quantity;
        
        emit Minted(msg.sender, quantity, startTokenId);
    }
    
    // ===== METADATA =====
    function tokenURI(uint256 tokenId) public view override returns (string memory) {
        require(ownerOf(tokenId) != address(0), "Token does not exist");
        return string(abi.encodePacked(baseTokenURI, tokenId.toString(), ".json"));
    }
    
    function setBaseURI(string memory _baseURI) external onlyOwner {
        baseTokenURI = _baseURI;
    }
    
    // ===== PRICING =====
    function setPrice(uint256 _price) external onlyOwner {
        MINT_PRICE = _price;
    }
    
    // ===== WITHDRAW =====
    function withdraw() external onlyOwner {
        uint256 balance = address(this).balance;
        require(balance > 0, "No funds to withdraw");
        (bool success, ) = payable(owner()).call{value: balance}("");
        require(success, "Withdrawal failed");
    }
    
    // ===== VIEW FUNCTIONS =====
    function getCurrentPhase() external view returns (string memory) {
        if (currentPhase == Phase.NONE) return "Not Started";
        if (currentPhase == Phase.GTD) return "GTD Whitelist";
        if (currentPhase == Phase.FCFS) return "FCFS Whitelist";
        if (currentPhase == Phase.PUBLIC) return "Public Mint";
        return "Unknown";
    }
    
    function isWhitelisted(address addr) external view returns (bool gtd, bool fcfs) {
        return (gtdWhitelist[addr], fcfsWhitelist[addr]);
    }
    
    function getMintedCount(address addr) external view returns (uint256) {
        return mintedPerWallet[addr];
    }
    
    function getRemainingMints(address addr) external view returns (uint256) {
        if (currentPhase == Phase.GTD && gtdWhitelist[addr]) {
            return GTD_LIMIT - mintedPerWallet[addr];
        } 
        
        else if (currentPhase == Phase.FCFS && fcfsWhitelist[addr]) {
            return FCFS_LIMIT - mintedPerWallet[addr];
        } 
        
        else if (currentPhase == Phase.PUBLIC) {
            return PUBLIC_LIMIT - mintedPerWallet[addr];
        }
        return 0;
    }
    
    function totalMinted() external view returns (uint256) 
    {
        return nextTokenId;
    }

}