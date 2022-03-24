// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.7;

library ArrayUtils {
    function contains(string[] storage haystack, string memory needle) public view returns (bool){
        for(uint i = 0; i < haystack.length; i++){
            if(sha256(bytes(haystack[i])) == sha256(bytes(needle))){
                return true;
            }
        }
        return false;
    }

    function increments(uint[] storage array, uint8 percentage) public{
        require(percentage <= 100, "percentage must be between 0 and 100");
        for(uint i = 0; i < array.length; i++){
            array[i] += (array[i] * percentage) / 100;
        }
    }

    function sum(uint[] storage array)public view returns (uint){
        uint res = 0;
        for(uint i = 0; i < array.length; i++){
            res += array[i];
        }
        return res;
    }
}

interface ERC721simplified{
    function approve(address approved, uint256 tokenId) external payable;
    function transferFrom(address from, address to, uint256 tokenId) external payable;
    function balanceOf(address owner) external view returns (uint256);
    function ownerOf(uint256 tokenId)external view returns (address);
    function getApproved(uint256 tokenId)external view returns (address);
    event Transfer(address indexed _from, address indexed _to, uint256 indexed _tokenId);
    event Approval(address indexed _owner, address indexed _approved, uint256 indexed _tokenId);
}

contract MonsterTokens is ERC721simplified{
    address payable private owner;
    address secondary_owner;
    uint last_token_id;
    mapping(uint => Character) characters;
    event Print(string message);

    constructor() {
         owner = payable(msg.sender);
         last_token_id = 10000;
    }

    struct Weapons {
        string[] names;
        uint[] firePowers;
    }

    struct Character {
        string name;
        Weapons weapons;
        address owner;
        address secondary_owner;
    }

    modifier onlyOwner {
        require(msg.sender == owner, "This function can only be called by the owner of the contract");
        _;
    }

    modifier onlyTokenOwner(uint token_id) {
        require(msg.sender == characters[token_id].owner, "This function can only be called by the owner of the token");
        _;
    }

    modifier onlyTokenOwnerOrApproved(uint token_id) {
        require(msg.sender == characters[token_id].owner || msg.sender == characters[token_id].secondary_owner, "This function can only be called by the owner or approved address of the token");
        _;
    }

    modifier existingCharacter(uint token_id) {
        require(bytes(characters[token_id].name).length != 0, "This character doesn't exist");
        _;
    }

    function createMonsterToken(string calldata name, address token_owner_address) external onlyOwner returns (uint){
        last_token_id++;
        Weapons memory weapons = Weapons(new string[](0), new uint[](0));
        characters[last_token_id] = Character(name, weapons, token_owner_address, address(0));
        return last_token_id;
    }

    function addWeapon(uint token_id, string calldata name, uint fire_power) public onlyTokenOwnerOrApproved(token_id) existingCharacter(token_id) {
        Character storage character = characters[token_id];
        require(!ArrayUtils.contains(character.weapons.names, name), "Weapon already exists");
        character.weapons.names.push(name);
        character.weapons.firePowers.push(fire_power);
    }

    function incrementFirePower(uint token_id, uint8 percentage) public existingCharacter(token_id) {
        Character storage character = characters[token_id];
        require(bytes(character.name).length != 0, "This character doesn't exist");
        ArrayUtils.increments(character.weapons.firePowers, percentage);
    }

    function collectProfits() public onlyOwner {
        payable(owner).transfer(address(this).balance);
    }

    function approve(address approved, uint256 tokenId) external payable override onlyTokenOwner(tokenId) existingCharacter(tokenId){
        require(msg.value >= ArrayUtils.sum(characters[tokenId].weapons.firePowers), "Value must be ge than the sum of the fire powers of the weapons");
        characters[tokenId].secondary_owner = approved;
        emit Approval(msg.sender, approved, tokenId);
    }

    
    function transferFrom(address from, address to, uint256 tokenId) external payable override onlyTokenOwnerOrApproved(tokenId) existingCharacter(tokenId){
        require(msg.value >= ArrayUtils.sum(characters[tokenId].weapons.firePowers), "Value must be ge than the sum of the fire powers of the weapons");
        characters[tokenId].secondary_owner = address(0);
        characters[tokenId].owner = to;
        emit Transfer(from, to, tokenId);
    }

    function balanceOf(address add_owner)external view override returns (uint256){
        uint256 res = 0;
        for(uint i = 10001; i <= last_token_id; i++){
            if(characters[i].owner == add_owner){
                res++;
            }
        }
        return res;
    }

    function ownerOf(uint256 tokenId)external view override returns (address){
        Character storage character = characters[tokenId];
        if(character.owner == address(0)){
            revert("Token is invalid");
        }
        return characters[tokenId].owner;
    }

    function getApproved(uint256 tokenId)external view override returns (address){
        Character storage character = characters[tokenId];
        if(character.owner == address(0)){
            revert("Token is invalid");
        }
        return characters[tokenId].secondary_owner;
    }
}
