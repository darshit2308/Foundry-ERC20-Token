// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

// To Create your ERC20 token. (which we are currently making) , follow the ERC20 - EIP token standards (see on website https://eips.ethereum.org/erc

contract ManualToken {
    mapping(address => uint256) private s_balances; // Mapping of address of user to their balance
    // Address 1 -> 4 Tokens
    // Address 2 -> 10 Tokens
    // Address 3 -> 100 Tokens
    // like this, mapping is done ...

    function name() public pure returns (string memory) {
        return "Manual Token" ;
    }

    function totalSupply() public pure returns (uint256) {
        return 100 ether; // 1 Ether = 1 * 10 power 18 
    }
    function decimals() public pure returns (uint256) {
        return 19;
    }
    function balanceOf(address _owner) public view returns (uint256) {
        return s_balances[_owner];
    }
    function transfer(address _to, uint256 _amount) public {
        uint256 perviousBalances = balanceOf(msg.sender) + balanceOf(_to);// msg.sender is the address of the user who is calling this function
        s_balances[msg.sender] -= _amount;
        s_balances[_to] += _amount;
        require(balanceOf(msg.sender) + balanceOf(_to) == perviousBalances, "Transfer failed");

    }
}