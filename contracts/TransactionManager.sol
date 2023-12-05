// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import './Nifty.sol';
import '@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol';

contract TransactionManager is IERC721Receiver
{
    function onERC721Received(address, address, uint256, bytes memory) public virtual override returns (bytes4) {
        return this.onERC721Received.selector;
    }
    
    Nifty maincontract;
    bool linkstatus = false;
    address maincontractaddr;
    function linkMainContract(address contractaddr) public
    {
        if(linkstatus != true)
        {
            maincontractaddr = contractaddr;
            maincontract = Nifty(contractaddr);
            maincontract.setApprovalForAll(contractaddr,true);
            linkstatus = true;
        }
    }
    
    function sendnft(uint256 id, address receiver) public
    {
        maincontract.transferNifty(address(this),receiver,id);
    }
    
    
    
    constructor(){
        
    }
    
    
    
    
}