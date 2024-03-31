// SPDX-License-Identifier: MIT

pragma solidity ^0.8.3;

interface ITreasury {
    /**
    * @notice Records the funds received from minting tokens.
    * @param _syntheticAssetToken Address of the minted tokens.
    * @param _mintedValue Dollar value of tokens minted.
    * @param _mintFeePaid Dollar value of the mint fee paid.
    */
    function recordMintedTokens(address _syntheticAssetToken, uint256 _mintedValue, uint256 _mintFeePaid) external;
}