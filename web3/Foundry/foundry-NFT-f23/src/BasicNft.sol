// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;
import {ERC721} from '../lib/openzeppelin-contracts/contracts/token/ERC721/ERC721.sol';
// /Users/chiranshu/Desktop/WebDevelopment/web3/Foundry/foundry-NFT-f23/lib/openzeppelin-contracts/contracts/token/ERC721/ERC721.sol
contract BasicNft is ERC721 {

    uint256 private s_tokenCounter  ; // this will be used to give indexing to each of our NFTs
    // When we prepare the constructor for any contract, we need to write the constructor for all those contracts which are inherited by it.
    mapping(uint256 => string) private s_tokenToUri;
    constructor() ERC721("Daredevil" , "DD")
    {
        s_tokenCounter = 0;  // initialising its value
    }
    function mintNft(string memory tokenUri) public {
        s_tokenToUri[s_tokenCounter] = tokenUri; // mapping of indexes and its corresponding uri
        _safeMint(msg.sender,s_tokenCounter); // It safely mints a new NFT and assigns it to the caller (msg.sender) with a unique token ID (s_tokenCounter).
        s_tokenCounter++; 


    }

    function tokenURI(uint256 tokenId)  public view override returns(string memory) {
        // When we pass parameters to a tokenURI function , we get a link, and on clicking on that link, we get a json file consisting of all the traits of that NFT
        // whereas image link takes us to the image of the NFT
        return s_tokenToUri[tokenId];
    }
}