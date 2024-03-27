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
                                                                               
                        $FORT -> $TAPA
                         February 2024
*/

pragma solidity ^0.8.9;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "./IChefRush.sol";

contract FortToTapa is Ownable {
    uint256 startDate = 0;
    uint256 endDate = 0;
    uint256[20] tlosPrices;
    mapping(address => uint256[20]) changes;
    mapping(address => uint256[20]) consumed;
    uint256 totalChanged = 0;

    IERC20 tapaToken;
    IERC20 fortToken;

    IChefRush chefRush;

    constructor(address _tapaToken, address _fortToken, address _chefRush) {
        tapaToken = IERC20(_tapaToken);
        fortToken = IERC20(_fortToken);
        chefRush = IChefRush(_chefRush);
    }

    /*
        Public getters
    */

    function getChanges(address addr, uint256 period) public view returns (uint256) {
        return changes[addr][period-1];
    }

    function getStake(address addr, uint256 period) public view returns (uint256) {
        if(chefRush.getCurrentPeriod() < period) return 0;
        else if(changes[addr][period-1] == 0) return 0;
        else {
            uint256 fortToTlos = ((changes[addr][period-1]*1280)/tlosPrices[period-1])/100;
            uint256 myStake = fortToTlos*chefRush.getFinalRatio(period);
            return myStake;
        }
    }
    
    /*
        Public functions
    */

    function change(uint256 period) public {
        require(endDate > block.timestamp, "Exchange finished.");
        uint256 fortBalance = fortToken.balanceOf(msg.sender);
        require(fortToken.transferFrom(msg.sender, address(this), fortBalance), "Transfer from FORT error.");
        if(period != 20){
            uint256 eighty = (((80*fortBalance/100) * 1280)/tlosPrices[period-1])/100;
            require(chefRush.getBuys(msg.sender, period) >= eighty, "Not enough contributed");
        }
        changes[msg.sender][period-1] = fortBalance;

        uint256 fortToTlos = ((fortBalance*1280)/tlosPrices[period-1])/100;
        totalChanged += fortToTlos*chefRush.getFinalRatio(period);
    }

    function availableClaim(address addr, uint256 period) public view returns (uint256) {
        if(block.timestamp < endDate) return 0;
        else if(changes[addr][period-1] == 0) return 0;
        else if((startDate + period * 1 days) + 180 days >= block.timestamp) return 0;
        else {
            uint256 startTime = (startDate + period * 1 days) + 180 days;
            uint256 endTime = startTime + 180 days;
            uint256 fortToTlos = ((changes[addr][period-1]*1280)/tlosPrices[period-1])/100;
            uint256 myStake = fortToTlos*chefRush.getFinalRatio(period);
            uint256 time = 100*(block.timestamp-startTime)/(endTime-startTime);
            uint256 amount = myStake*(time-consumed[addr][period-1])/100;
            return amount;
        }
    }

    function claim(uint256 period) public {
        require(block.timestamp < endDate, "Exchange not finished.");
        require(changes[msg.sender][period-1] > 0, "Balance zero.");
        require((startDate + period * 1 days) + 180 days < block.timestamp, "Claim not opened yet.");

        uint256 startTime = (startDate + period * 1 days) + 180 days;
        uint256 endTime = startTime + 180 days;

        uint256 fortToTlos = ((changes[msg.sender][period-1]*1280)/tlosPrices[period-1])/100;
        uint256 myStake = fortToTlos*chefRush.getFinalRatio(period);
        uint256 time = 100*(block.timestamp-startTime)/(endTime-startTime);
        uint256 amount = myStake*(time-consumed[msg.sender][period-1])/100;
        consumed[msg.sender][period-1] = time;
        require(tapaToken.transfer(msg.sender, amount), "Error transfering funds.");
    }
    

    /*
        Admin functions
    */

    function setStartDate(uint256 _startDate) public onlyOwner {
        startDate = _startDate;
        endDate = _startDate + 30 days;
    }

    function test(uint256 _startDate) public pure returns (uint256){
        return _startDate + 30 days;
    }

    function extractFort() public onlyOwner {
        require(fortToken.transfer(msg.sender, fortToken.balanceOf(address(this))));
    }

    function extractTapas() public onlyOwner {
        require(tapaToken.transfer(msg.sender, tapaToken.balanceOf(address(this))));
    }

    function setTlosPrices(uint256[20] memory input) public onlyOwner {
        tlosPrices = input;
    }

    function setTlosPrice(uint256 period, uint256 input) public onlyOwner {
        tlosPrices[period-1] = input;
    }

    function getTotalChangedInTapas() view public returns (uint256){
        return totalChanged;
    }
}