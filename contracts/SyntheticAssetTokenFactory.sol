// SPDX-License-Identifier: MIT

pragma solidity ^0.8.3;

// OpenZeppelin.
import "./openzeppelin-solidity/contracts/Ownable.sol";

// Internal references.
import './SyntheticAssetToken.sol';

// Inheritance.
import './interfaces/ISyntheticAssetTokenFactory.sol';

contract SyntheticAssetTokenFactory is ISyntheticAssetTokenFactory, Ownable {
    address public immutable oracle;
    address public immutable treasury;
    address public immutable protocolSettings;
    address public immutable stablecoin;
    address public registry;

    constructor(address _oracle, address _treasury, address _protocolSettings, address _stablecoin) Ownable() {
        oracle = _oracle;
        treasury = _treasury;
        protocolSettings = _protocolSettings;
        stablecoin = _stablecoin;
    }

    /* ========== MUTATIVE FUNCTIONS ========== */

    /**
    * @notice Deploys a SyntheticAssetToken contract and returns the contract's address.
    * @dev This function can only be called by the SyntheticAssetTokenRegistry contract.
    * @param _asset Address of the synthetic asset's data feed.
    * @param _maxSupply The maximum number of tokens that can be minted.
    * @param _name A custom name for this asset.
    * @param _symbol A custom symbol for this asset.
    * @return address Address of the deployed SyntheticAssetToken contract.
    */
    function createSyntheticAssetToken(address _asset, uint256 _maxSupply, string memory _name, string memory _symbol) external override returns (address) {
        address syntheticAssetToken = address(new SyntheticAssetToken(registry, oracle, protocolSettings, treasury, stablecoin, _asset, _maxSupply, _name, _symbol));

        emit CreatedSyntheticAssetToken(_asset, _maxSupply, _name, _symbol);

        return syntheticAssetToken;
    }

    /* ========== RESTRICTED FUNCTIONS ========== */

    /**
    * @notice Sets the address of the SyntheticAssetTokenRegistry contract.
    * @dev The address is initialized outside of the constructor to avoid a circular dependency with SyntheticAssetTokenRegistry.
    * @dev This function can only be called by the SyntheticAssetTokenFactory owner.
    * @param _registry Address of the SyntheticAssetTokenRegistry contract.
    */
    function initializeContract(address _registry) external onlyOwner {
        registry = _registry;

        emit InitializedContract(_registry);
    }

    /* ========== MODIFIERS ========== */

    modifier onlyRegistry() {
        require(msg.sender == registry,
                "SyntheticAssetTokenFactory: Only the SyntheticAssetTokenRegistry contract can call this function.");
        _;
    }

    /* ========== EVENTS ========== */

    event CreatedSyntheticAssetToken(address asset, uint256 maxSupply, string name, string symbol);
    event InitializedContract(address registryAddress);
}