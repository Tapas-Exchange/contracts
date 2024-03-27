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
                                                                               
                        $TAPA Chef Rush
                         March 2024
*/

pragma solidity ^0.8.9;

import "@openzeppelin/contracts@4.8.0/access/Ownable.sol";
import "@openzeppelin/contracts@4.8.0/token/ERC20/IERC20.sol";

contract ChefRush is Ownable {
    uint256 startDate = 0;
    uint256 maxPeriods = 20;
    uint256 currentPeriod = 0;
    uint256 tokensPerPeriod;
    uint256[20] totalBuys;
    uint256[20] ratios;
    uint256 minRatio;
    uint256[20] distribution;
    mapping(address => uint256[20]) buys;
    mapping(address => uint256[20]) consumed;

    IERC20 tapaToken;

    constructor(address _tapaToken) {
        tapaToken = IERC20(_tapaToken);
    }

    /*
        Public getters
    */

    function getCurrentPeriod() public view returns (uint256) {
        return currentPeriod;
    }

    function getCurrentPeriodAvailableTokens() public view returns (uint256) {
        return tokensPerPeriod;
    }

    function getCurrentPeriodBuys() public view returns (uint256) {
        return totalBuys[currentPeriod-1];
    }

    function getPeriodBuys(uint256 period) public view returns (uint256) {
        return totalBuys[period-1];
    }

    function getBuys(address addr, uint256 period) public view returns (uint256) {
        return buys[addr][period-1];
    }

    function getTotalRaised() public view returns (uint256) {
        return address(this).balance;
    }

    function getFinalRatio(uint256 period) public view returns (uint256) {
        return ratios[period-1];
    }

    function getDistribution(uint256 period) public view returns (uint256) {
        return distribution[period-1];
    }

    function getMinRatio() public view returns (uint256) {
        return minRatio;
    }

    /*
        Public functions
    */

    function buy() payable public {
        require(currentPeriod > 0 && currentPeriod < maxPeriods + 1, "Chef Rush finished.");
        buys[msg.sender][currentPeriod-1] += msg.value;
        totalBuys[currentPeriod-1] += msg.value;
    }

    function getStake(address addr, uint256 period) public view returns (uint256) {
        if(currentPeriod < period) return 0;
        else if(buys[addr][period-1] == 0) return 0;
        else {
            uint256 myStake = buys[addr][period-1] * ratios[period-1];
            return myStake;
        }
    }

    function getAllStakes(address addr) public view returns (uint256[20] memory) {
        uint256[20] memory temp;
        for(uint8 i = 0; i<20; i++){
            temp[i] = getStake(addr, i+1);
        }
        return temp;
    }
    
    function availableClaim(address addr, uint256 period) public view returns (uint256) {
        if(currentPeriod != maxPeriods + 1) return 0;
        else if(buys[addr][period-1] == 0) return 0;
        else if((startDate + period * 1 days) + 180 days >= block.timestamp) return 0;
        else {
            uint256 startTime = (startDate + period * 1 days) + 180 days;
            uint256 endTime = startTime + 180 days;
            uint256 myStake = buys[addr][period-1] * ratios[period-1];
            uint256 time = 100*(block.timestamp-startTime)/(endTime-startTime);
            uint256 amount = myStake*(time-consumed[addr][period-1])/100;
            return amount;
        }
    }

    function claim(uint256 period) public {
        require(currentPeriod == maxPeriods + 1, "Chef Rush not finished.");
        require(buys[msg.sender][period-1] > 0, "Balance zero.");
        require((startDate + period * 1 days) + 180 days < block.timestamp, "Claim not opened yet.");

        uint256 startTime = (startDate + period * 1 days) + 180 days;
        uint256 endTime = startTime + 180 days;

        uint256 myStake = buys[msg.sender][period-1] * ratios[period-1];
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
    }

    function addTokens(uint256 tokens) public onlyOwner {
        require(tokens > 0, "Tokens must be greater than 0.");
        require(tapaToken.transferFrom(msg.sender, address(this), tokens), "Can't transfer tokens.");
        tokensPerPeriod = tokens/20;
    }

    function startPeriod() public onlyOwner {
        require(startDate != 0, "Start date not set.");
        require(currentPeriod+1 <= maxPeriods, "Max period reached.");
        if(currentPeriod != 0){
            if(totalBuys[currentPeriod-1] != 0){
                if(currentPeriod == 1){
                    ratios[currentPeriod-1] = tokensPerPeriod/totalBuys[currentPeriod-1];
                    minRatio = tokensPerPeriod/totalBuys[currentPeriod-1];
                    distribution[currentPeriod-1] = tokensPerPeriod;
                }else{
                    uint256 r = tokensPerPeriod/totalBuys[currentPeriod-1];
                    if(r < minRatio){
                        ratios[currentPeriod-1] = r;
                        minRatio = r;
                        distribution[currentPeriod-1] = tokensPerPeriod;
                    }else{
                        ratios[currentPeriod-1] = minRatio;
                        distribution[currentPeriod-1] = totalBuys[currentPeriod-1] * minRatio;
                    }
                }
            }
        }
        currentPeriod++;
    }

    function finish() public onlyOwner {
        require(currentPeriod == maxPeriods, "Periods not completed.");
        uint256 r = tokensPerPeriod/totalBuys[currentPeriod-1];
        if(r < minRatio){
            ratios[currentPeriod-1] = r;
            minRatio = r;
            distribution[currentPeriod-1] = tokensPerPeriod;
        }else{
            ratios[currentPeriod-1] = minRatio;
            distribution[currentPeriod-1] = totalBuys[currentPeriod-1] * minRatio;
        }
        currentPeriod++;
    }

    function retireFunds() public onlyOwner {
        require(currentPeriod > maxPeriods, "Chef Rush not finished.");
        address payable to = payable(msg.sender);
        to.transfer(address(this).balance);
    }

    function retireExcess(uint256 period) public onlyOwner {
        require(currentPeriod > period, "Period hasn't finish yet.");
        uint256 excess = tokensPerPeriod-distribution[period-1];
        require(tapaToken.transfer(msg.sender, excess), "Error transfering funds.");
    }
}