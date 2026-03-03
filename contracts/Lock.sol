// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
// import "@thirdweb-dev/contracts/extension/ContractMetadata.sol";

contract ShooterCoin is ERC20, ContractMetadata {
 
    address public owner;

    constructor() ERC20("ShooterCoin", "SHC") {
        owner = msg.sender;
        _mint(msg.sender, 1000000 * 10 ** decimals());
    }

    // REQUIRED: ThirdWeb needs this to verify who can set contract metadata
    function _canSetContractURI() internal view override returns (bool) {
        return msg.sender == owner;
    }

    // Reward players with tokens
    function rewardPlayer(address player, uint256 amount) public {
        require(msg.sender == owner, "Only the owner can reward players");
        _mint(player, amount * 10 ** 18);
    }

    // Get token balance of any wallet
    function getBalance(address wallet) public view returns (uint256) {
        return balanceOf(wallet);
    }
}