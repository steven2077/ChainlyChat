// SPDX-License-Identifier: MIT
pragma solidity ^0.8.1;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC1155/utils/ERC1155Holder.sol";
import "./ChainChat.sol";

contract talk is Ownable, ERC1155Holder {
    ChainChat public proxy;

    constructor(address _chainChatAddress) {
        proxy = ChainChat(_chainChatAddress);
    }

    function setProxy(address _chainChatAddress) public onlyOwner {
        proxy = ChainChat(_chainChatAddress);
    }

    struct Client {
        address _address;
        bytes32 _name;
        bytes32 publicKey;
    }
    mapping(address => Client) clients;
    address[] clientsArray;

    struct Message {
        uint256 id;
        bytes16 date;
        uint128 contentType;
        bytes content; // 32*8=256 bytes per message
    }
    struct Message_history {
        address sender;
        address receiver;
        uint256 nexMessageId;
        Message[] message_sent;
    }

    // senderAddress => ( receiverAddress =>  Message_history ))
    mapping(address => mapping(address => Message_history)) private data;

    uint256 _guildNumber;

    bytes32[] guildNames;
    mapping(bytes32 => Guild) nameToGuild;
    struct Guild {
        GuildInfo info;
        mapping(address => GuildMember) members;
        address[] memberArray;
        GuildApplication[] applicantList;
        GuildMessage[] messageList;
    }
    struct GuildInfo {
        uint256 guildId;
        address president;
        bytes32 guildName;
        uint256 memberNum;
        uint256 messageCount;
        bytes introduction;
    }
    struct GuildMember {
        address _address;
        bytes32 name;
        bytes32 group;
        uint256 level;
        bytes32 data;
    }
    struct GuildApplication {
        address applicant;
        bytes message;
    }
    struct GuildMessage {
        uint256 id;
        address from;
        bytes16 date;
        uint128 contentType;
        bytes content;
    }

    modifier registered() {
        require(clients[msg.sender]._address == msg.sender, "Unregistered!");
        _;
    }

    modifier permitted(address sender, address receiver) {
        require(
            msg.sender == sender ||
                msg.sender == receiver ||
                msg.sender == owner(),
            "Not permitted"
        );
        _;
    }

    modifier hasMemberNFT() {
        require(proxy.hasMemberAccess(msg.sender), "denied");
        _;
    }

    modifier hasPresidentNFT() {
        require(proxy.hasPresidentAccess(msg.sender), "denied");
        _;
    }

    modifier hasAdministratorNFT() {
        require(proxy.hasAdministratorAccess(msg.sender), "denied");
        _;
    }

    modifier isPresidentOfGuild(bytes32 guildName) {
        require(nameToGuild[guildName].info.president == msg.sender, "denied");
        _;
    }

    modifier isMemberOfGuild(bytes32 guildName) {
        require(
            nameToGuild[guildName].members[msg.sender]._address == msg.sender,
            "Not Member!"
        );
        _;
    }

    function addGuild(bytes32 guildName, bytes memory introduction)
        public
        registered
        hasPresidentNFT
    {
        uint256 guildNum = guildNames.length;

        bool conflict = false;
        for (uint256 i = 0; i < guildNum; i++) {
            if (guildNames[i] == guildName) {
                conflict = true;
                break;
            }
        }
        require(!conflict, "Name already exists!");

        address client = msg.sender;
        proxy.burn(client, 1, 1);

        if (nameToGuild[guildName].info.president != address(0)) {
            guildNames.push(guildName);
            return;
        }

        GuildMember memory pre;
        pre._address = msg.sender;
        pre.name = clients[msg.sender]._name;
        nameToGuild[guildName].members[msg.sender] = pre;
        nameToGuild[guildName].memberArray.push(msg.sender);

        GuildInfo memory info;
        info.guildId = _guildNumber;
        info.president = msg.sender;
        info.guildName = guildName;
        info.memberNum = 1;
        info.introduction = introduction;
        nameToGuild[guildName].info = info;

        guildNames.push(guildName);
        _guildNumber += 1;
    }

    function delGuild(bytes32 guildName) public hasAdministratorNFT {
        for (uint256 i = 0; i < guildNames.length; i++) {
            if (guildNames[i] == guildName) {
                guildNames[i] = guildNames[guildNames.length - 1];
                guildNames.pop();
                return;
            }
        }
    }

    function addGuildMember(bytes32 guildName, address account)
        public
        isPresidentOfGuild(guildName)
    {
        require(
            nameToGuild[guildName].members[account]._address != account,
            "already exists"
        );
        require(clients[account]._address == account, "not registered");
        uint256 apNum = nameToGuild[guildName].applicantList.length;
        for (uint256 i = 0; i < apNum; i++) {
            if (nameToGuild[guildName].applicantList[i].applicant == account) {
                nameToGuild[guildName].applicantList[i] = nameToGuild[guildName]
                    .applicantList[apNum - 1];
                nameToGuild[guildName].applicantList.pop();
                break;
            }
        }

        GuildMember memory newMem;
        newMem.name = clients[account]._name;
        newMem._address = clients[account]._address;
        nameToGuild[guildName].members[account] = newMem;
        nameToGuild[guildName].memberArray.push(account);
        nameToGuild[guildName].info.memberNum++;
    }

    function removeGuildMember(bytes32 guildName, address account)
        public
        isPresidentOfGuild(guildName)
    {
        address[] memory memAr = nameToGuild[guildName].memberArray;
        for (uint256 i = 0; i < memAr.length; i++) {
            if (memAr[i] == account) {
                delete nameToGuild[guildName].members[account];
                nameToGuild[guildName].memberArray[i] = nameToGuild[guildName]
                    .memberArray[memAr.length - 1];
                nameToGuild[guildName].memberArray.pop();
                nameToGuild[guildName].info.memberNum--;
                return;
            }
        }
    }

    function editGuildMember(
        bytes32 guildName,
        address usr,
        bytes32 name,
        bytes32 group,
        uint256 level,
        bytes32 _data
    ) public isPresidentOfGuild(guildName) {
        GuildMember memory guildMem;
        guildMem._address = usr;
        guildMem.name = name;
        guildMem.group = group;
        guildMem.level = level;
        guildMem.data = _data;
        nameToGuild[guildName].members[usr] = guildMem;
    }

    function applyToJoinGuild(bytes32 guildName, bytes memory content)
        public
        hasMemberNFT
    {
        GuildApplication memory ap;
        ap.applicant = msg.sender;
        ap.message = content;
        nameToGuild[guildName].applicantList.push(ap);
    }

    function getApList(bytes32 guildName)
        public
        view
        isPresidentOfGuild(guildName)
        returns (GuildApplication[] memory)
    {
        return nameToGuild[guildName].applicantList;
    }

    function getGuildMembers(bytes32 guildName)
        public
        view
        isMemberOfGuild(guildName)
        returns (GuildMember[] memory)
    {
        uint256 mNum = nameToGuild[guildName].memberArray.length;
        GuildMember[] memory mList = new GuildMember[](mNum);
        for (uint256 i = 0; i < mNum; i++) {
            address m = nameToGuild[guildName].memberArray[i];
            mList[i] = nameToGuild[guildName].members[m];
        }
        return mList;
    }

    function sendGuildMessage(
        bytes32 guildName,
        bytes16 date,
        uint128 contentType,
        bytes memory content
    ) public isMemberOfGuild(guildName) {
        GuildMessage memory newMessage;
        newMessage.id = nameToGuild[guildName].info.messageCount;
        newMessage.from = msg.sender;
        newMessage.date = date;
        newMessage.contentType = contentType;
        newMessage.content = content;
        nameToGuild[guildName].messageList.push(newMessage);
        nameToGuild[guildName].info.messageCount += 1;
    }

    function getGuildInfoList() public view returns (GuildInfo[] memory) {
        GuildInfo[] memory gList = new GuildInfo[](guildNames.length);
        for (uint256 i = 0; i < guildNames.length; i++) {
            gList[i] = nameToGuild[guildNames[i]].info;
        }
        return gList;
    }

    function getGuildMessageHistory(bytes32 guildName)
        public
        view
        returns (GuildMessage[] memory)
    {
        return nameToGuild[guildName].messageList;
    }

    function addClient(bytes32 name) public {
        if (clients[msg.sender]._address == address(0)) {
            clients[msg.sender]._address = msg.sender;
            clients[msg.sender]._name = name;
            clientsArray.push(msg.sender);
            return;
        } else if (clients[msg.sender]._address == msg.sender) {
            for (uint256 i = 0; i < clientsArray.length; i++) {
                if (clientsArray[i] == msg.sender) return;
            }
            clientsArray.push(msg.sender);
        }
    }

    function setName(bytes32 name) public {
        clients[msg.sender]._name = name;
    }

    function delClient(address usr) public registered hasAdministratorNFT {
        for (uint256 i = 0; i < clientsArray.length; i++) {
            if (clientsArray[i] == usr) {
                clientsArray[i] = clientsArray[clientsArray.length - 1];
                clientsArray.pop();
            }
        }
    }

    function isRegistered() public view returns (bool) {
        for (uint256 i = 0; i < clientsArray.length; i++) {
            if (clientsArray[i] == msg.sender) return true;
        }
        return false;
    }

    function getClientsObjectArray() public view returns (Client[] memory) {
        Client[] memory clientsObjectArray = new Client[](clientsArray.length);
        for (uint256 i = 0; i < clientsArray.length; i++) {
            Client memory thisClient = clients[clientsArray[i]];
            clientsObjectArray[i] = thisClient;
        }
        return clientsObjectArray;
    }

    function sendMessage(
        address receiver,
        bytes16 date,
        uint128 contentType,
        bytes memory content
    ) public registered {
        if (data[msg.sender][receiver].sender == address(0)) {
            data[msg.sender][receiver].sender = msg.sender;
            data[msg.sender][receiver].receiver = receiver;
        }
        Message memory new_message;
        new_message.date = date;
        new_message.contentType = contentType;
        new_message.content = content;
        new_message.id = data[msg.sender][receiver].nexMessageId;
        data[msg.sender][receiver].message_sent.push(new_message);
        data[msg.sender][receiver].nexMessageId += 1;
        data[receiver][msg.sender].nexMessageId += 1;
    }

    function getMessage(
        address sender,
        address receiver,
        uint256 index
    ) public view returns (Message memory) {
        return data[sender][receiver].message_sent[index];
    }

    function getMessageHistory(address sender, address receiver)
        public
        view
        permitted(sender, receiver)
        returns (Message[] memory)
    {
        return data[sender][receiver].message_sent;
    }
}
