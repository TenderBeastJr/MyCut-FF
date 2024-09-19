// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {IERC20} from "lib/openzeppelin-contracts/contracts/token/ERC20/ERC20.sol";
import {Ownable} from "lib/openzeppelin-contracts/contracts/access/Ownable.sol";

contract Pot is Ownable(msg.sender) {
    error Pot__RewardNotFound();
    error Pot__InsufficientFunds();
    error Pot__StillOpenForClaim();

    address[] private i_players;
    uint256[] private i_rewards;
    address[] private claimants;
    uint256 private immutable i_totalRewards;
    uint256 private immutable i_deployedAt;
    IERC20 private immutable i_token;
    mapping(address => uint256) private playersToRewards;
    uint256 private remainingRewards;
    uint256 private constant managerCutPercent = 10;

    constructor(address[] memory players, uint256[] memory rewards, IERC20 token, uint256 totalRewards) {
        i_players = players;
        i_rewards = rewards;
        i_token = token;
        i_totalRewards = totalRewards;
        remainingRewards = totalRewards;
        i_deployedAt = block.timestamp;

        // i_token.transfer(address(this), i_totalRewards);

        for (uint256 i = 0; i < i_players.length; i++) {
            playersToRewards[i_players[i]] = i_rewards[i];
        }
    }

    // This function is expected to claimCut
    function claimCut() public {
        // Here, the players address is assigned msg.sender value
        // Q-what if a player creates two addresses?
        address player = msg.sender;
        // This line retrieves the reward with the player mapping
        // and assigns value to reward of type uint256-bit
        uint256 reward = playersToRewards[player];
        // if reward is less or equals 0
        if (reward <= 0) {
            // revert the transaction the error "Pot__RewardNotFound"
            revert Pot__RewardNotFound();
        }
        // This line sets the reward of the player to 0
        // by resetting player reward balance in the playersToRewards mapping.
        playersToRewards[player] = 0;
        // This line decreases the value of remainingRewards by the amount of the player's reward.
        remainingRewards -= reward;
        // This line is used to add the address of a player who has claimed their reward to the claimants array
        claimants.push(player);
        // This line transfers reward to the player
        _transferReward(player, reward);
    }
    
    // This function closes the pot
    function closePot() external onlyOwner {
        // Here, if the time difference between the current time (block.timestamp) and the time the contract was deployed (i_deployedAt)
        // is less than 90 days
        if (block.timestamp - i_deployedAt < 90 days) {
            // revert the transaction the error "Pot__StillOpenForClaim"
            revert Pot__StillOpenForClaim();
        }
        // This line checks if there are any remaining rewards left
        if (remainingRewards > 0) {
            // This line calculates the manager's cut of the remaining reward
            // by dividing the total remainingRewards by managerCutPercent
            // managerCutPercent == 10
            // Q-does the timestamp end before calculating remaining rewards?
            // Q-how is manager's cut calculated if there's no remaining rewards?
            // @audit-lead what happens when remainingRewards == managerCutPercent
            uint256 managerCut = remainingRewards / managerCutPercent;
            // This line transfers the calculated amount of manager's cut
            // to the manager's address
            i_token.transfer(msg.sender, managerCut);

            // This line assigns claimantCut the total value of rewards
            // after subtracting the manager's cut from remainingRewards
            // then the remaining reward's divided by the number of players
            // @audit-lead what will happen to players whose cut is lesser than manager's cut?
            uint256 claimantCut = (remainingRewards - managerCut) / i_players.length;
            // This line is a for loop to transfer to each claimants
            // the loop begins with i = 0
            // and runs until i reaches the total number of claimants length
            // after each iteration, i increases plus 1
            for (uint256 i = 0; i < claimants.length; i++) {
                
                // This line transfers the actual rewards
                // to different claimants addresses
                // this process repeats until all claimants have received their share of the rewards.
                _transferReward(claimants[i], claimantCut);
            }
        }
    }
    
    // This function transfers specified reward                                                                                                                 to players address
    function _transferReward(address player, uint256 reward) internal {
        // The specified reward is sent to player
        i_token.transfer(player, reward);
    }

    function getToken() public view returns (IERC20) {
        return i_token;
    }

    function checkCut(address player) public view returns (uint256) {
        return playersToRewards[player];
    }
  
    function getRemainingRewards() public view returns (uint256) {
        return remainingRewards;
    }
}
