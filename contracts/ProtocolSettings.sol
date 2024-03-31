// SPDX-License-Identifier: MIT

pragma solidity ^0.8.3;

// OpenZeppelin.
import "./openzeppelin-solidity/contracts/Ownable.sol";

// Inheritance.
import './interfaces/IProtocolSettings.sol';

contract ProtocolSettings is IProtocolSettings, Ownable {
    uint256 public override maxDiscount;
    uint256 public override mintFee;

    constructor() Ownable() {}

    /* ========== RESTRICTED FUNCTIONS ========== */

    /**
    * @notice Updates the value of maxDiscount.
    * @dev This function can only be called by the ProtocolSettings contract owner.
    * @param _newMaxDiscount The new value for max discount.
    */
    function updateMaxDiscount(uint256 _newMaxDiscount) external onlyOwner {
        require(_newMaxDiscount > 0 && _newMaxDiscount < 10000, "ProtocolSettings: Max discount is out of bounds.");

        uint256 oldMaxDiscount = maxDiscount;
        maxDiscount = _newMaxDiscount;

        emit UpdateMaxDiscount(oldMaxDiscount, _newMaxDiscount);
    }

    /**
    * @notice Updates the value of mintFee.
    * @dev This function can only be called by the ProtocolSettings contract owner.
    * @param _newMintFee The new value for mint fee.
    */
    function updateMintFee(uint256 _newMintFee) external onlyOwner {
        require(_newMintFee > 0 && _newMintFee < 10000, "ProtocolSettings: Mint fee is out of bounds.");

        uint256 oldMintFee = mintFee;
        mintFee = _newMintFee;

        emit UpdateMintFee(oldMintFee, _newMintFee);
    }

    /* ========== EVENTS ========== */

    event UpdateMaxDiscount(uint256 oldMaxDiscount, uint256 newMaxDiscount);
    event UpdateMintFee(uint256 oldMintFee, uint256 newMintFee);
}