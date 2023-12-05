// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import '@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol';
import '@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol';
import './TransactionManager.sol';
contract Nifty is ERC721Enumerable, IERC721Receiver{
    
    function onERC721Received(address, address, uint256, bytes memory) public virtual override returns (bytes4) {
        return this.onERC721Received.selector;
    }
    
    
    address private TransactionManagerAddress;
    TransactionManager transactionmanager;
    // array to store our nfts
    NiftyNFTInfo[] private niftyStorage;

    // Mapping from token ID to owner address
    mapping(uint256 => address) private _owners;

    // Mapping owner address to token count
    mapping(address => uint256) private _balances;

    // Mapping from token ID to approved address
    mapping(uint256 => address) private _tokenApprovals;
    
    mapping(address => uint256) private userCurrencyBalance;
    
    mapping(uint256 => bool) private _niftyExists;

    mapping(uint256 => address) private listings;
    // Mapping from owner to operator approvals
    mapping(address => mapping(address => bool)) private _operatorApprovals;

    struct NiftyNFTInfo
    {
        string collection;
        string link;
        string filetype;
        bool listed;
        uint256 price;
    }
    
    function getNiftyNFTInfo(uint256 ID,string memory infotype) external view returns(string memory)
    {
        // *** IMPORTANT *** add require function that checks if ID exists or not to stop null pointer
        require(_niftyExists[ID] == true);
        if(keccak256(abi.encodePacked(infotype)) == keccak256(abi.encodePacked('collection')))  
        {
            return niftyStorage[ID].collection;
        }
        else if(keccak256(abi.encodePacked(infotype)) == keccak256(abi.encodePacked('link')))
        {
            return niftyStorage[ID].link;
        }
        else if(keccak256(abi.encodePacked(infotype)) == keccak256(abi.encodePacked('filetype')))
        {
            return niftyStorage[ID].filetype;
        }
        else if(keccak256(abi.encodePacked(infotype)) == keccak256(abi.encodePacked('listed')))
        {
            if(niftyStorage[ID].listed == true)
            {
                return 'true';
            }
            else
            {
                return 'false';
            }
        }
        return('Not a valid info type');        
    }
    function listNiftyNFT(uint256 ID, uint256 price) external
    {
         require(_niftyExists[ID] == true);
         listings[ID] = ownerOf(ID);
         safeTransferFrom(msg.sender,TransactionManagerAddress,ID);
         niftyStorage[ID].price = price;
         
    }
    function deListNiftyNFT(uint256 ID) public
    {
        //create
    }
    function purchaseNiftyNFT(uint256 ID) payable public
    {
        require(msg.value >= niftyStorage[ID].price,'not enough matic');
        userCurrencyBalance[listings[ID]] += niftyStorage[ID].price;
        transactionmanager.sendnft(ID,msg.sender);
        listings[ID] = address(0);
    }
    function claimFunds() public  //NOTE IMPORTANT: ADD REENTRANCY GUARD
    {
        //require(userCurrencyBalance[msg.sender] > 0);
         (bool success, ) = payable(msg.sender).call{value: userCurrencyBalance[msg.sender]}("");
        require(success, "Failed to send Ether");
        userCurrencyBalance[msg.sender] = 0;
    }
    function getBalance() public view returns (uint256)
    {
        return(userCurrencyBalance[msg.sender]);
    }
    function transferNifty(address fromaddr, address to, uint256 id) public
    {
        safeTransferFrom(fromaddr,to,id);
    }
    function mintNiftyNFT(string memory collection, string memory link, string memory filetype) external {


        NiftyNFTInfo memory tempNiftyNFTInfo;
        tempNiftyNFTInfo.collection = collection;
        tempNiftyNFTInfo.link = link;
        tempNiftyNFTInfo.filetype = filetype;
        niftyStorage.push(tempNiftyNFTInfo);

        uint _id = niftyStorage.length - 1;
        require(_niftyExists[_id] == false);
        _niftyExists[_id] = true;
        // .push no longer returns the length but a ref to the added element
        _safeMint(msg.sender, _id);

    }
    //maps contract address to a mapping of NFT ID to struct containing
    //NFT info
    mapping(address => mapping(uint256 => ExternalNFTInfo)) private _externalNFTLedger;



    struct ExternalNFTInfo{
        bool alreadyListed;
        uint256 price;
        address owner;

    }

    //uses the mapping to create a listing
    function listNewExternalNFT(address nftcontract , uint256 nftID, uint256 price) external{
        //requires that the msg sender also be the owner of the NFT from a specific project contract
        require(_externalNFTLedger[nftcontract][nftID].owner == msg.sender , "NFT is not owned by message sender");

        //requires that the nft is not listed
        require(_externalNFTLedger[nftcontract][nftID].alreadyListed == true, "NFT is already listed");
        //sets listing status as true
        _externalNFTLedger[nftcontract][nftID].alreadyListed = true;
        //sets the price 
        _externalNFTLedger[nftcontract][nftID].price = price;



    }

    function purchaseExternalNFT(address nftcontract, uint256 nftID) payable external
    {
        //require check for approval(to do) *** IMPORTANT ***

        require(msg.value >= _externalNFTLedger[nftcontract][nftID].price);
        payable(_externalNFTLedger[nftcontract][nftID].owner).transfer(_externalNFTLedger[nftcontract][nftID].price);
        _externalNFTLedger[nftcontract][nftID].owner = msg.sender;
        _externalNFTLedger[nftcontract][nftID].price = 0;
        _externalNFTLedger[nftcontract][nftID].alreadyListed = false;



    }

        





    constructor(address tmanageaddr) ERC721('Nifty','NFTY')
    {
        transactionmanager = TransactionManager(tmanageaddr);
        TransactionManagerAddress = tmanageaddr;
    }

}





