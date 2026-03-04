// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol" ;

// trying to communicate and intract with the ShooterCOin contract to be abke to excute the function
interface IShooterCoin {
    function transferFrom (address from, address to, uint256 amount)
    external returns (bool);
    
}

interface IUSDC {
    function transferFrom(address from, address to, uint256 amount)
    external returns (bool);
    function balanceOf(address account) external view returns (uint256);
    function transfer (address to, uint256 amount) external returns (bool);
}

 contract GameSkins is ERC1155 {

    // ------- STATE VAIRBALES --------------------

    address public owner; // owner of the contract 
    address public shooterCoinAddress; // address of the SHC
    address public usdcAddress; // owner usdc address


    // assigning an Id to each of the skins 
    uint256 public constant DESERT = 1;
    uint256 public constant JUNGLE = 2;
    uint256 public constant SNOW = 3;

    // Price of each skin in USDC  and SHC(remember 6 decimals!)
    //10 USDC = 10 * 10**6 = 10,000,000
    uint256 public skinPriceUSDC = 10 * 10**6;
    uint256 public skinPriceSHC = 10 * 10**18;

 
    // maping though the skinId to get the mapName
    mapping (uint256 => string) public skinUnlocks;

    //Tracking how may of this skins exist (the total supply of the skin)
    mapping (uint256 => uint256) public skinToallySupply;

    // this function is expected to run once this contract is deployed 
    constructor(address _shooterCoin, address _usdc) ERC1155 ("https://mygame.com/api/skin/{id}.json") {
        
        owner = msg.sender;
        shooterCoinAddress = _shooterCoin; 
        usdcAddress = _usdc;

        // assigning the map to each skin
        skinUnlocks[DESERT] = "Desert Map";
        skinUnlocks[JUNGLE] = "Jungle Map";
        skinUnlocks[SNOW] = "Snow Map";
    }


    //----- MODIFIER ------------------------------ 
    // Only the owner can call this function
    modifier onlyOwner() {
        require(msg.sender == owner, "Only owner can call this function");
        _; // means "now run the rest of the function"
    }


    // ---- BUY With SHC --------
    function buyWithSHC (uint256 skinId) public {
        // checking if skin Exist
        require(skinId >=1 && skinId <= 3, "Skin does not exist");

        // check if player dosent already own it 
      require(balanceOf(msg.sender, skinId) == 0, "You already own this skin");



        // Pull SHC from player wallet into this Contract
        //player must have called SHC.approved before this.

        bool success = IShooterCoin(shooterCoinAddress).transferFrom(
            msg.sender,     // from the player 
            address(this), // to this contract address
            skinPriceSHC // Amount: 100 SHC
        );

        require(success, "SHC payment Failed");
        _mint(msg.sender,skinId, 1, "");
        skinToallySupply[skinId] += 1;

    }


    //-----BUY WITH USDC---------------
    function buyWithUSDC (uint256 skinId) public {
        // checking with the skin Exist
        require (skinId >= 1 && skinId <= 3, "Skin does not exist" );

        // check if the player dosent already own it 
      require(balanceOf(msg.sender, skinId) == 0, "You already own this skin");


        // Pull USDC frfom players wallet into this contract
        //player must have called USDC.approve() before this. 

        bool success =IUSDC(usdcAddress).transferFrom(
            msg.sender,
            address(this),
            skinPriceUSDC
        ); 

        require(success, "USDC payment failed");

        //mint Nft to the player 
        _mint(msg.sender, skinId, 1, "");
        skinToallySupply[skinId] += 1;
    }



    //-----MAP ACCESS CHECK--------------------
    //Unity calls this when a player clicks on a map
    function canAccessMap(address player, uint256 skinId)
        public view returns (bool)
    {
        return balanceOf(player, skinId) > 0; 
    }

    // Get Map name for a Skin 
    function getUnlockedMap(uint256 skinId) public view returns ( string memory) {
        return skinUnlocks[skinId];
    }

    //---------ADMIN--------------------
    // Withdraw collected USDC to owners wallet 
    function withdrawUSDC() public onlyOwner {
        uint256 balance = IUSDC(usdcAddress).balanceOf(address(this));
        require(balance > 0, "No USDC to Withdraw");
        IUSDC(usdcAddress).transfer(owner, balance);
    }

    // Update Price if Needed
    function updatePrice(uint256 newSHCPrice, uint256 newUSDCPrice) public onlyOwner {
        skinPriceSHC = newSHCPrice;
        skinPriceUSDC = newUSDCPrice;
    }
    
// SOULBOUND — block all transfers
    function _update(
    address from,
    address to,
    uint256[] memory ids,
    uint256[] memory values
    ) internal override {
    require(from == address(0), "Skins are soulbound");
    super._update(from, to, ids, values);
    }
 }