// SPDX-License-Identifier: MIT

/*

       _            _                   _          _                  _        
      /\ \         / /\                /\ \       / /\               / /\      
      \_\ \       / /  \              /  \ \     / /  \             / /  \     
      /\__ \     / / /\ \            / /\ \ \   / / /\ \           / / /\ \__  
     / /_ \ \   / / /\ \ \          / / /\ \_\ / / /\ \ \         / / /\ \___\ 
    / / /\ \ \ / / /  \ \ \        / / /_/ / // / /  \ \ \        \ \ \ \/___/ 
   / / /  \/_// / /___/ /\ \      / / /__\/ // / /___/ /\ \        \ \ \       
  / / /      / / /_____/ /\ \    / / /_____// / /_____/ /\ \   _    \ \ \      
 / / /      / /_________/\ \ \  / / /      / /_________/\ \ \ /_/\__/ / /      
/_/ /      / / /_       __\ \_\/ / /      / / /_       __\ \_\\ \/___/ /       
\_\/       \_\___\     /____/_/\/_/       \_\___\     /____/_/ \_____\/        
                                                                               
                         $TAPA Token
                         March 2024
*/

pragma solidity ^0.8.9;

import "@openzeppelin/contracts@4.8.0/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts@4.8.0/access/Ownable.sol";
import "@openzeppelin/contracts@4.8.0/token/ERC20/extensions/ERC20Votes.sol";

contract TapaToken is ERC20, Ownable, ERC20Permit, ERC20Votes {
    uint256 public maxSupply = 2000000000 * 10 ** decimals(); // Maximum supply is 2 billion $TAPA

    constructor()
        ERC20("Tapas Token", "TAPA")
        ERC20Permit("Tapas Token")
    {
        _mint(msg.sender, 60000000 * 10 ** decimals());
    }

    function mint(address to, uint256 amount) public onlyOwner {
        require(totalSupply() + amount <= maxSupply, "Maximum supply reached.");
        _mint(to, amount);
    }

    function burn(uint256 amount) public onlyOwner {
        _burn(msg.sender, amount);
    }

    function _afterTokenTransfer(address from, address to, uint256 amount)
        internal
        override(ERC20, ERC20Votes)
    {
        super._afterTokenTransfer(from, to, amount);
    }

    function _mint(address to, uint256 amount)
        internal
        override(ERC20, ERC20Votes)
    {
        super._mint(to, amount);
    }

    function _burn(address account, uint256 amount)
        internal
        override(ERC20, ERC20Votes)
    {
        super._burn(account, amount);
    }

}