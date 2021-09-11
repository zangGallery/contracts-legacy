// contracts/ZangNFT.sol
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;
import {Base64} from "./MetadataUtils.sol";

import "@openzeppelin/contracts/utils/Counters.sol";
import "./ERC721TextStorage.sol";
import "./ERC2981PerTokenRoyalties.sol";

contract ZangNFT is ERC721TextStorage, ERC2981PerTokenRoyalties {
    using Counters for Counters.Counter;
    Counters.Counter private _tokenIds;

    // tokenId to token name
    mapping(uint256 => string) private _names;
    // tokenId to token description
    mapping(uint256 => string) private _descriptions;

    constructor() ERC721("ZangNFT", "ZNG") {}

    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC721, ERC2981PerTokenRoyalties) returns (bool) {
        return super.supportsInterface(interfaceId);
    }

    function mint(string memory textURI, string memory name, string memory description)
        public
        returns (uint256)
    {
        _tokenIds.increment();

        uint256 newItemId = _tokenIds.current();
        _mint(msg.sender, newItemId);
        _setTextURI(newItemId, textURI);
        _setName(newItemId, name);
        _setDescription(newItemId, description);
        _setTokenRoyalty(newItemId, msg.sender, 10); //TODO: change to func params 

        return newItemId;
    }

    function _setName(uint256 tokenId, string memory _name) internal virtual {
        require(_exists(tokenId), "ERC721URIStorage: URI set of nonexistent token");
        _names[tokenId] = _name;
    }

    function _setDescription(uint256 tokenId, string memory _description) internal virtual {
        require(_exists(tokenId), "ERC721URIStorage: URI set of nonexistent token");
        _descriptions[tokenId] = _description;
    }

    function tokenURI(uint256 tokenId) public view override returns (string memory) {
        require(_exists(tokenId), "ERC721TextStorage: URI query for nonexistent token");
        /*string[4] memory parts;
        parts[
            0
        ] = '<svg xmlns="http://www.w3.org/2000/svg" preserveAspectRatio="xMinYMin meet" viewBox="0 0 350 350"><style>.base { fill: white; font-family: serif; font-size: 14px; }</style><rect width="100%" height="100%" fill="black" /><text x="10" y="20" class="base">';

        //parts[1] = t

        parts[2] = '</text><text x="10" y="40" class="base">';

        parts[3] = "</text></svg>";

        string memory output = string(
            abi.encodePacked(parts[0], parts[1], parts[2], parts[3])
        );*/

        string memory json = Base64.encode(
            bytes(
                string(
                    abi.encodePacked(
                        '{ "name": "', _names[tokenId],'", ', 
                        '"description" : ', '"', _descriptions[tokenId], '", ',
                        //'"image": "data:image/svg+xml;base64,', Base64.encode(bytes(output)), '", ' 
                        '"textURI" : ', '"', textURI(tokenId), '"',
                        '}'
                    )
                )
            )
        );
        string memory output = string(
            abi.encodePacked("data:application/json;base64,", json)
        );

        return output;
    }
}