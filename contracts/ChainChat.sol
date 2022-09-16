// SPDX-License-Identifier: MIT
pragma solidity ^0.8.1;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/token/ERC1155/utils/ERC1155Holder.sol";

contract ChainChat is Ownable, ERC1155, ERC1155Holder, AccessControl {
    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");
    bytes32 public constant BURNER_ROLE = keccak256("BURNER_ROLE");
    uint256 public constant C = 0;
    uint256 public constant E = 1;
    uint256 public constant S = 2;
    string talkAddress;
    mapping(uint256 => uint256) public idToPrice;

    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override(ERC1155, AccessControl, ERC1155Receiver)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }

    constructor()
        ERC1155(
            "https://gateway.pinata.cloud/ipfs/QmbzY3dt9EwBnBCNEDQdunAFi61hFcJg2DqFHn2WWt2gV4/{id}.json"
        )
    {
        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _setupRole(MINTER_ROLE, msg.sender);
        _setupRole(BURNER_ROLE, msg.sender);
        _mint(msg.sender, C, 10000, "");
        _mint(msg.sender, E, 1000, "");
        _mint(msg.sender, S, 100, "");
        idToPrice[0] = 10 * 10**18;
        idToPrice[1] = 10 * 10**18;
        idToPrice[2] = 1000000000 * 10**18;
    }

    function hasMemberAccess(address usr) public view returns (bool) {
        if (balanceOf(usr, 0) > 0) {
            return true;
        } else {
            return false;
        }
    }

    function hasPresidentAccess(address usr) public view returns (bool) {
        if (balanceOf(usr, 1) > 0) {
            return true;
        } else {
            return false;
        }
    }

    function hasAdministratorAccess(address usr) public view returns (bool) {
        if (balanceOf(usr, 2) > 0) {
            return true;
        } else {
            return false;
        }
    }

    function setPrice(uint256 id, uint256 price) public onlyOwner {
        idToPrice[id] = price;
    }

    function getAllPrice()
        public
        view
        returns (
            uint256,
            uint256,
            uint256
        )
    {
        return (idToPrice[0], idToPrice[1], idToPrice[2]);
    }

    function getAllBalance()
        public
        view
        returns (
            uint256,
            uint256,
            uint256
        )
    {
        return (
            balanceOf(msg.sender, 0),
            balanceOf(msg.sender, 1),
            balanceOf(msg.sender, 2)
        );
    }

    function mint(
        address to,
        uint256 id,
        uint256 amount
    ) public {
        require(hasRole(MINTER_ROLE, msg.sender), "Caller is not a miner");
        _mint(to, id, amount, "");
    }

    function buy(
        address to,
        uint256 id,
        uint256 amount
    ) public payable {
        require(
            msg.value >= amount * idToPrice[id],
            "You need to pay more CFX"
        );
        _mint(to, id, amount, "");
    }

    function setBurnRole(address client) public onlyOwner {
        _setupRole(BURNER_ROLE, client);
    }

    function burn(
        address from,
        uint256 id,
        uint256 amount
    ) public {
        require(hasRole(BURNER_ROLE, msg.sender), "Caller is not a burner");
        _burn(from, id, amount);
    }

    function withdraw() public payable onlyOwner {
        // require msg.sender == owner
        // require(msg.sender == owner);
        payable(msg.sender).transfer(address(this).balance);
    }
}
