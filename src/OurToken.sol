/* OpenZeppelin Contracts provide pre-built, secure, and reusable smart contracts for Solidity, 
Ethereum, and other EVM blockchains. They offer a foundation for building decentralized 
applications (dApps) by providing commonly used functionalities like tokens, access control, 
and more. 
*/
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract OurToken is ERC20 {
    constructor(uint256 initialSupply) ERC20("Our Token", "OT") /* We need to give a name and symbol */ {
        _mint(msg.sender, initialSupply);
    }
}
