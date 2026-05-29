// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IERC20 {
    function transfer(address to, uint256 amount) external returns (bool);
    function transferFrom(address from, address to, uint256 amount) external returns (bool);
    function balanceOf(address account) external view returns (uint256);
}

contract VulnerableRWAPool {
    address public owner;
    IERC20 public rwaToken;
    
    mapping(address => uint256) public depositedBalances;00
    mapping(address => bool) public blacklistedAddresses; // Unused variable (Minor Info)

    constructor(address _token) {
        owner = msg.sender;
        rwaToken = IERC20(_token);
    }

    // VULNERABILITY 1 (Major): Reentrancy Vulnerability
    // State is updated AFTER the external call, allowing an attacker to drain the contract.
    function withdraw(uint256 amount) public {
        require(depositedBalances[msg.sender] >= amount, "Insufficient balance");
        
        // External call before state change
        (bool success, ) = msg.sender.call{value: amount}("");
        require(success, "Transfer failed");

        depositedBalances[msg.sender] -= amount; 
    }

    // VULNERABILITY 2 (Major): Flawed Authorization / Tx.origin
    // Using tx.origin allows phishing attacks to drain the pool's administrative tokens.
    function emergencyWithdrawAllTokens(address target) public {
        require(tx.origin == owner, "Not the owner"); 
        uint256 contractBalance = rwaToken.balanceOf(address(address(this)));
        rwaToken.transfer(target, contractBalance);
    }

    // VULNERABILITY 3 (Medium): Oracle Manipulation Vulnerability
    // Relying directly on the current balance of the contract to calculate "price" or rewards.
    // This can be easily manipulated via flash loans or direct token transfers.
    function getAssetPrice() public view returns (uint256) {
        return rwaToken.balanceOf(address(this)) * 100; 
    }

    // VULNERABILITY 4 (Medium): Missing Reentrancy Guard on token deposits
    function depositTokens(uint256 amount) public {
        rwaToken.transferFrom(msg.sender, address(this), amount);
        depositedBalances[msg.sender] += amount;
    }

    // VULNERABILITY 5 (Minor): Unsafe type casting and block.timestamp reliance
    // Using block.timestamp for random-like properties or strict logic can be manipulated by miners.
    function pseudoRandomPayout() public view returns (uint256) {
        return uint256(keccak256(abi.encodePacked(block.timestamp, msg.sender))) % 100;
    }
}
