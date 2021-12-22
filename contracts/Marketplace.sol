// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

interface IZangNFT {
    function safeTransferFrom(address from, address to, uint256 id, uint256 amount, bytes calldata data) external;
    function exists(uint256 _tokenId) external view returns (bool);
    function balanceOf(address account, uint256 id) external view returns (uint256);
    function royaltyInfo(uint256 tokenId, uint256 value) external view returns (address receiver, uint256 royaltyAmount);
}

contract zangMarketplace is Pausable, Ownable {

    event TokenListed(
        uint256 indexed _tokenId,
        address indexed _seller,
        uint256 amount,
        uint256 _price
    );

    event TokenDelisted(
        uint256 indexed _tokenId
    );

    event TokenPurchased(
        uint256 indexed _tokenId,
        address indexed _buyer,
        address indexed _seller,
        uint256 _amount,
        uint256 _price
    );

    IZangNFT public ZangNFTAddress;
    uint256 public platformFeePercentage = 500; //two decimals, so 500 = 5.00%
    address public ZangCommissionAccount;

    struct Listing {
        uint256 price;
        address seller;
        uint256 amount;
    }

    // a token can have multiple listings
    mapping(uint256 => Listing[]) public listings;

    constructor(IZangNFT _zangNFTAddress, address _ZangCommissionAccount) {
        ZangNFTAddress = _zangNFTAddress;
        ZangCommissionAccount = _ZangCommissionAccount;
    }

    function listToken(uint256 _tokenId, uint256 _price, uint256 _amount) public whenNotPaused {
        require(_amount <= ZangNFTAddress.balanceOf(msg.sender, _tokenId), "Not enough tokens to list"); // Opz.
        require(_price > 0, "Price must be greater than 0");

        listings[_tokenId].push(Listing(_price, msg.sender, _amount));
        emit TokenListed(_tokenId, msg.sender, _amount, _price);
    }

    function delistToken(uint256 _tokenId, uint256 _listingIndex) public whenNotPaused {
        require(listings[_tokenId].length > _listingIndex, "Listing index out of bounds");
        require(listings[_tokenId][_listingIndex].seller == msg.sender, "Only the seller can delist");
        _delistToken(_tokenId, _listingIndex);
    }

    function _removeListing(uint256 _tokenId, uint256 _listingIndex) private {
        listings[_tokenId][_listingIndex] = listings[_tokenId][listings[_tokenId].length - 1];
        listings[_tokenId].pop();
    }

    function _delistToken(uint256 _tokenId, uint256 _listingIndex) private {
        _removeListing(_tokenId, _listingIndex);
        emit TokenDelisted(_tokenId);
    }

    function _handleFunds(uint256 _tokenId, address seller) private {
        // TODO: Platform fee + Zang commission must not go over 100%
        // TODO: Test integer division rounding errors
        uint256 platformFee = (msg.value * platformFeePercentage) / 10000;
        (address creator, uint256 creatorFee) = ZangNFTAddress.royaltyInfo(_tokenId, msg.value);
        uint256 sellerEarnings = msg.value - platformFee - creatorFee;
        // Test: The sum of three of them must be equal to msg.value
        payable(ZangCommissionAccount).transfer(platformFee);
        payable(creator).transfer(creatorFee);
        payable(seller).transfer(sellerEarnings);
    }

    function buyToken(uint256 _tokenId, uint256 _listingIndex, uint256 _amount) public payable whenNotPaused {
        require(listings[_tokenId].length > _listingIndex, "Listing index out of bounds");
        require(listings[_tokenId][_listingIndex].seller != msg.sender, "Cannot buy from yourself");
        // TODO: Invert for clarity
        require(listings[_tokenId][_listingIndex].amount >= _amount, "Not enough tokens to buy");
        address seller = listings[_tokenId][_listingIndex].seller;
        // if seller transfers tokens "for free", their listing is still active! if they get them back they can still be bought
        require(ZangNFTAddress.balanceOf(seller, _tokenId) >= _amount, "Seller has not enough tokens anymore");

        uint256 price = listings[_tokenId][_listingIndex].price;
        // check if listing is satisfied
        require(msg.value == price * _amount, "Price does not match");

        _handleFunds(_tokenId, seller);

        ZangNFTAddress.safeTransferFrom(seller, msg.sender, _tokenId, _amount, "");
        // TODO: Delist only if there are no more tokens left
        _delistToken(_tokenId, _listingIndex);
        // TODO: Decrease listing amount

        emit TokenPurchased(_tokenId, msg.sender, seller, _amount, price);
    }

}