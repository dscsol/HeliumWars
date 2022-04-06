// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract Heliumwars is ERC721, ERC721Enumerable, ERC721URIStorage, Ownable {
    bool public publicSaleIsActive = false;
    bool public whitelistSaleIsActive = false;
    string private baseURI;
    uint256 public constant MAX_SUPPLY = 8888;
    uint256 public constant MAX_PUBLIC_MINT = 1;
    uint256 public constant PRICE_PER_TOKEN = 0.12 ether;
    mapping(address => uint8) private _whitelist;

    constructor() ERC721("Heliumwars", "HELIUMWARS") {}

    function setBaseURI(string memory uri) external onlyOwner {
        baseURI = uri;
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return baseURI;
    }

    function setPublicSaleState(bool newState) external onlyOwner {
        publicSaleIsActive = newState;
    }

    function setWhitelistSaleState(bool newState) external onlyOwner {
        whitelistSaleIsActive = newState;
    }

    function setWhiteList(address[] calldata addresses, uint8 numAllowedToMint)
        external
        onlyOwner
    {
        for (uint256 i = 0; i < addresses.length; i++) {
            _whitelist[addresses[i]] = numAllowedToMint;
        }
    }

    function numAvailableToMint(address addr) external view returns (uint8) {
        return _whitelist[addr];
    }

    function whitelistMint(uint8 numberOfTokens) external payable {
        uint256 ts = totalSupply();
        require(whitelistSaleIsActive, "whitlist sale is not active");
        require(
            numberOfTokens <= _whitelist[msg.sender],
            "Exceeded max available to purchase"
        );
        require(
            ts + numberOfTokens <= MAX_SUPPLY,
            "Purchase would exceed max tokens"
        );
        require(
            PRICE_PER_TOKEN * numberOfTokens <= msg.value,
            "Ether value sent is not correct"
        );

        _whitelist[msg.sender] -= numberOfTokens;
        for (uint256 i = 0; i < numberOfTokens; i++) {
            _safeMint(msg.sender, ts + i);
            _setTokenURI(ts + i, Strings.toString(ts + i));
        }
    }

    function publicMint(uint256 numberOfTokens) external payable {
        uint256 ts = totalSupply();
        require(publicSaleIsActive, "public sale is not active");
        require(
            numberOfTokens <= MAX_PUBLIC_MINT,
            "Exceeded max token purchase"
        );
        require(
            ts + numberOfTokens <= MAX_SUPPLY,
            "Purchase would exceed max tokens"
        );
        require(
            PRICE_PER_TOKEN * numberOfTokens <= msg.value,
            "Ether value sent is not correct"
        );

        for (uint256 i = 0; i < numberOfTokens; i++) {
            _safeMint(msg.sender, ts + i);
            _setTokenURI(ts + i, Strings.toString(ts + i));
        }
    }

    function withdraw() public onlyOwner {
        uint256 balance = address(this).balance;
        payable(msg.sender).transfer(balance);
    }

    // The following functions are overrides required by Solidity.

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal override(ERC721, ERC721Enumerable) {
        super._beforeTokenTransfer(from, to, tokenId);
    }

    function _burn(uint256 tokenId)
        internal
        override(ERC721, ERC721URIStorage)
    {
        super._burn(tokenId);
    }

    function tokenURI(uint256 tokenId)
        public
        view
        override(ERC721, ERC721URIStorage)
        returns (string memory)
    {
        return super.tokenURI(tokenId);
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(ERC721, ERC721Enumerable)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }
}
