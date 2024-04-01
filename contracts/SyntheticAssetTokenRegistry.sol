// SPDX-License-Identifier: MIT

pragma solidity ^0.8.3;

// OpenZeppelin.
import "./openzeppelin-solidity/contracts/SafeMath.sol";
import "./openzeppelin-solidity/contracts/Ownable.sol";
import "./openzeppelin-solidity/contracts/ERC20/IERC20.sol";

// Interfaces.
import './interfaces/ISyntheticAssetTokenFactory.sol';
import './interfaces/ISyntheticAssetToken.sol';

// Inheritance.
import './interfaces/ISyntheticAssetTokenRegistry.sol';

contract SyntheticAssetTokenRegistry is ISyntheticAssetTokenRegistry, Ownable {
    using SafeMath for uint256;

    ISyntheticAssetTokenFactory public immutable factory;

    address public operator;
    address public registrar;

    uint256 public numberOfSyntheticAssets;
    // (synthetic asset index => synthetic asset contract address).
    // Starts at index 1.
    mapping (uint256 => address) public indexToAsset;
    // (synthetic asset contract address => synthetic asset index).
    mapping (address => uint256) public assetToIndex;

    constructor(address _factory) Ownable() {
        factory = ISyntheticAssetTokenFactory(_factory);

        operator = msg.sender;
        registrar = msg.sender;
    }

    /* ========== VIEWS ========== */

    /**
    * @notice Returns the address of the synthetic asset's underlying data feed.
    * @dev Returns address(0) if the synthetic asset is not found.
    * @dev Either [_index] or [_syntheticAsset] is used for getting the data.
    * @dev If [_index] is 0, then [_syntheticAsset] is used.
    * @dev If [_syntheticAsset] is address(0), then [_syntheticAsset] is used.
    * @dev If [_index] and [_syntheticAsset] are both valid values, then [_index] is used.
    * @param _index Index of the synthetic asset.
    * @param _syntheticAsset Address of the synthetic asset.
    * @return address Address of the synthetic asset's underlying data feed.
    */
    function getDataFeed(uint256 _index, address _syntheticAsset) external view override returns (address) {
        if (_index != 0) {
            return ISyntheticAssetToken(indexToAsset[_index]).asset();
        }

        if (_syntheticAsset != address(0)) {
            return ISyntheticAssetToken(_syntheticAsset).asset();
        }

        return address(0);
    }

    /**
    * @notice Returns the synthetic asset's maximum supply of tokens.
    * @dev Returns 0 if the synthetic asset is not found.
    * @dev Either [_index] or [_syntheticAsset] is used for getting the data.
    * @dev If [_index] is 0, then [_syntheticAsset] is used.
    * @dev If [_syntheticAsset] is address(0), then [_syntheticAsset] is used.
    * @dev If [_index] and [_syntheticAsset] are both valid values, then [_index] is used.
    * @param _index Index of the synthetic asset.
    * @param _syntheticAsset Address of the synthetic asset.
    * @return uint256 The synthetic asset's maximum supply of tokens.
    */
    function getMaxSupply(uint256 _index, address _syntheticAsset) external view override returns (uint256) {
        if (_index != 0) {
            return ISyntheticAssetToken(indexToAsset[_index]).maxSupply();
        }

        if (_syntheticAsset != address(0)) {
            return ISyntheticAssetToken(_syntheticAsset).maxSupply();
        }

        return 0;
    }

    /**
    * @notice Returns true if the minting is enabled for the given synthetic asset.
    * @dev Returns false if the synthetic asset is not found.
    * @dev Either [_index] or [_syntheticAsset] is used for getting the data.
    * @dev If [_index] is 0, then [_syntheticAsset] is used.
    * @dev If [_syntheticAsset] is address(0), then [_syntheticAsset] is used.
    * @dev If [_index] and [_syntheticAsset] are both valid values, then [_index] is used.
    * @param _index Index of the synthetic asset.
    * @param _syntheticAsset Address of the synthetic asset.
    * @return bool The synthetic asset's minting status.
    */
    function getMintingStatus(uint256 _index, address _syntheticAsset) external view override returns (bool) {
        if (_index != 0) {
            return ISyntheticAssetToken(indexToAsset[_index]).mintingIsEnabled();
        }

        if (_syntheticAsset != address(0)) {
            return ISyntheticAssetToken(_syntheticAsset).mintingIsEnabled();
        }

        return false;
    }

    /**
    * @notice Returns the synthetic asset's circulating supply of tokens.
    * @dev Returns 0 if the synthetic asset is not found.
    * @dev Either [_index] or [_syntheticAsset] is used for getting the data.
    * @dev If [_index] is 0, then [_syntheticAsset] is used.
    * @dev If [_syntheticAsset] is address(0), then [_syntheticAsset] is used.
    * @dev If [_index] and [_syntheticAsset] are both valid values, then [_index] is used.
    * @param _index Index of the synthetic asset.
    * @param _syntheticAsset Address of the synthetic asset.
    * @return uint256 The synthetic asset's circulating supply of tokens.
    */
    function getTotalSupply(uint256 _index, address _syntheticAsset) external view override returns (uint256) {
        if (_index != 0) {
            return IERC20(indexToAsset[_index]).totalSupply();
        }

        if (_syntheticAsset != address(0)) {
            return IERC20(_syntheticAsset).totalSupply();
        }

        return 0;
    }

    /**
    * @notice Returns the user's balance of tokens for the given synthetic asset.
    * @dev Returns 0 if the synthetic asset is not found.
    * @dev Either [_index] or [_syntheticAsset] is used for getting the data.
    * @dev If [_index] is 0, then [_syntheticAsset] is used.
    * @dev If [_syntheticAsset] is address(0), then [_syntheticAsset] is used.
    * @dev If [_index] and [_syntheticAsset] are both valid values, then [_index] is used.
    * @param _user Address of the user.
    * @param _index Index of the synthetic asset.
    * @param _syntheticAsset Address of the synthetic asset.
    * @return uint256 The user's balance of tokens for the asset.
    */
    function getBalance(address _user, uint256 _index, address _syntheticAsset) external view override returns (uint256) {
        if (_index != 0) {
            return IERC20(indexToAsset[_index]).balanceOf(_user);
        }

        if (_syntheticAsset != address(0)) {
            return IERC20(_syntheticAsset).balanceOf(_user);
        }

        return 0;
    }

    /* ========== RESTRICTED FUNCTIONS ========== */

    /**
    * @notice Creates a new synthetic asset token and registers it in the system.
    * @dev This function can only be called by the registrar of the SyntheticAssetTokenRegistry contract.
    * @param _asset Address of the synthetic asset's data feed.
    * @param _maxSupply The maximum number of tokens that can be minted.
    * @param _name A custom name for this asset.
    * @param _symbol A custom symbol for this asset.
    */
    function createSyntheticAssetToken(address _asset, uint256 _maxSupply, string memory _name, string memory _symbol) external override onlyOperator {
        // Gas savings.
        uint256 index = numberOfSyntheticAssets.add(1);

        // Create the contract and get address.
        address syntheticAssetAddress = factory.createSyntheticAssetToken(_asset, _maxSupply, _name, _symbol);

        numberOfSyntheticAssets = index;
        indexToAsset[index] = syntheticAssetAddress;
        assetToIndex[syntheticAssetAddress] = index;

        emit CreatedSyntheticAssetToken(index, syntheticAssetAddress, _asset, _maxSupply, _name, _symbol);
    }

    /**
    * @notice Increases the maximum supply of tokens for this asset.
    * @dev Only the operator of the SyntheticAssetTokenRegistry contract can call this function.
    * @dev The new max supply must be higher than the current max supply.
    * @param _syntheticAsset Address of the synthetic asset.
    * @param _newMaxSupply The new maximum number of tokens that can exist for this asset.
    */
    function increaseMaxSupply(address _syntheticAsset, uint256 _newMaxSupply) external override onlyOperator {
        // The SyntheticAssetToken contract checks that the new max supply is higher than the current max supply.
        ISyntheticAssetToken(_syntheticAsset).increaseMaxSupply(_newMaxSupply);

        emit IncreasedMaxSupply(_newMaxSupply);
    }

    /**
    * @notice Enables, or disables, the ability to mint new tokens.
    * @dev Only the operator of the SyntheticAssetTokenRegistry contract can call this function.
    * @dev This function is meant to be used to protect the protocol from Black Swan events.
    * @param _syntheticAsset Address of the synthetic asset.
    * @param _enableMinting Whether to allow new tokens to be minted.
    */
    function toggleMintingStatus(address _syntheticAsset, bool _enableMinting) external override onlyOperator {
        ISyntheticAssetToken(_syntheticAsset).toggleMintingStatus(_enableMinting);

        emit ToggledMintingStatus(_enableMinting);
    }

    /**
     * @notice Updates the address of the operator.
     * @dev This function can only be called by the SyntheticAssetTokenRegistry contract owner.
     * @param _newOperator Address of the new operator.
     */
    function setOperator(address _newOperator) external onlyOwner {
        operator = _newOperator;

        emit SetOperator(_newOperator);
    }

    /**
     * @notice Updates the address of the registrar.
     * @dev This function can only be called by the SyntheticAssetTokenRegistry contract owner.
     * @param _newRegistrar Address of the new registrar.
     */
    function setRegistrar(address _newRegistrar) external onlyOwner {
        registrar = _newRegistrar;

        emit SetRegistrar(_newRegistrar);
    }

    /* ========== MODIFIERS ========== */

    modifier onlyRegistrar() {
        require(msg.sender == registrar, "SyntheticAssetTokenRegistry: Only the registrar can call this function.");
        _;
    }

    modifier onlyOperator() {
        require(msg.sender == operator, "SyntheticAssetTokenRegistry: Only the operator can call this function.");
        _;
    }

    /* ========== EVENTS ========== */

    event SetOperator(address newOperator);
    event SetRegistrar(address newRegistrar);
    event CreatedSyntheticAssetToken(uint256 index, address syntheticAssetAddress, address dataFeedAddress, uint256 maxSupply, string name, string symbol);
    event IncreasedMaxSupply(uint256 newMaxSupply);
    event ToggledMintingStatus(bool mintingStatus);
}