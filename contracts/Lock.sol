// SPDX-License-Identifier: MIT

pragma solidity ^0.8.28;
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract ShooterCoin is ERC20 {
 
    address public owner; // Creating the owner as the contract address

   // this constructor runs once immediately the contracts is deployed  to create the token and send it to the owners address
    constructor() ERC20("ShooterCoin", "SHC") {
        owner = msg.sender; //the deployer becomes the owner, as the contract address is the deployer's address
         // Mint 1,000,000 tokens to the owner's wallet
        _mint(msg.sender, 1000000 * 10 ** decimals()); //minting the tokens to the deployer address
    }

    // this function allow the wallet owner to reward players who play the game.
    function rewardPlayer( address player, uint256 amount) public  {
        require(msg.sender == owner, "Only the owner can reward players"); //only the owner can reward players
       _mint(player, amount * 10 ** 18);
    }

    // the the ERC20 wallet address 
    function getBallance (address wallet) public view returns ( uint256 ) {
        return balanceOf(wallet);
    }

}