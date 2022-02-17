//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0; 

import "@openzeppelin/contracts/token/ERC20/presets/ERC20PresetFixedSupply.sol";

contract USDC is ERC20PresetFixedSupply {

    constructor() ERC20PresetFixedSupply("usdc", "USDC", 100000000000000000, msg.sender) {
   _mint(msg.sender, 10000000000); 
    }

    function decimals() public view virtual override returns (uint8) {
        return 6;
    }

}