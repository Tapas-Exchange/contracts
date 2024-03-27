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
                                                                               
                   $TAPA Chef Rush Interface
                         January 2024
*/

pragma solidity ^0.8.9;

interface IChefRush {
    function getCurrentPeriod() external view returns (uint256);
    function getBuys(address addr, uint256 period) external view returns (uint256);
    function getFinalRatio(uint256 period) external view returns (uint256);
    function getMinRatio() external view returns (uint256);
}