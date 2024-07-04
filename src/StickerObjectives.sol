pragma solidity ^0.8.24;

import {IStickerObjective} from "./IStickerObjective.sol";
import {Ownable} from "openzeppelin-contracts/contracts/access/Ownable.sol";


contract StickerObjectives is Ownable {
    mapping (uint => IStickerObjective) public objectives;
    mapping (address => uint) public objectivesLookup;
    mapping (address => bool) public bannedObjectives;
    mapping (address => bool) public bannedAddresses;
    uint public objectiveCount;
    uint public addNewObjectiveFee;
    address public adminFeeRecipient;

    event AdminTransferFailure(address indexed recipient, uint amount);
    event NewObjective(address indexed objective, uint indexed objectiveId, address indexed dev);
    event ObjectiveBanned(address indexed objective, uint indexed objectiveId);
    event ObjectiveUnbanned(address indexed objective, uint indexed objectiveId);

    error ObjectiveNotAllowed();
    error AddressNotAllowed();
    error IncorrectFeePayment();
    error ObjectiveAlreadyExists();

    constructor(address _initialAdmin, uint _addNewObjectiveFee) Ownable(_initialAdmin) {
        adminFeeRecipient = _initialAdmin;
        addNewObjectiveFee = _addNewObjectiveFee;
    }

    function getObjective(uint _objectiveId) public view returns (IStickerObjective objective) {
        IStickerObjective loadedObjective = objectives[_objectiveId];
        if (bannedObjectives[address(loadedObjective)]) {
            return objective;
        }
        objective = loadedObjective;
    }

    function getObjectives(uint _offset, uint _count) external view returns (IStickerObjective[] memory) {
        if (_offset >= objectiveCount) {
            return new IStickerObjective[](0);
        }
        uint max = _offset + _count;
        if (max > objectiveCount) {
            max = objectiveCount;
        }
        IStickerObjective[] memory _objectives = new IStickerObjective[](max - _offset);
        for (uint i = _offset; i < max; i++) {
            _objectives[i - _offset] = getObjective(i);
        }
        return _objectives;
    }

    function getIdOfObjective(address _objectiveAddress) public view returns (uint) {
        if (bannedObjectives[_objectiveAddress]) {
            return 0;
        }
        return objectivesLookup[_objectiveAddress];
    }

    function addNewObjective(IStickerObjective _objective)
        external payable
        returns (uint) {

        if (msg.value != addNewObjectiveFee) {
            revert IncorrectFeePayment();
        }
        if (bannedAddresses[msg.sender] || address(_objective) == address(0)) {
            revert AddressNotAllowed();
        }
        if (objectivesLookup[address(_objective)] != 0) {
            revert ObjectiveAlreadyExists();
        }
        address _dev = _objective.dev();
        if (bannedAddresses[_dev] || _dev == address(0)) {
            revert AddressNotAllowed();
        }
        uint _objectiveId = objectiveCount;
        objectives[_objectiveId] = _objective;
        objectivesLookup[address(_objective)] = _objectiveId;
        objectiveCount++;
        emit NewObjective(address(_objective), _objectiveId, _dev);
        return _objectiveId;
    }

    // admin function to change fee
    function setAddNewObjectiveFee(uint _fee) public onlyOwner() {
        addNewObjectiveFee = _fee;
    }

    // admin function to set admin fee recipient. cannot be zero address
    function setAdminFeeRecipient(address _recipient) public onlyOwner() {
        if (_recipient == address(0)) {
            revert AddressNotAllowed();
        }
        adminFeeRecipient = _recipient;
    }

    // admin function to set banned objectives
    function banObjectives(address[] memory _objectives, bool _undoBan) public onlyOwner() {
        for (uint i = 0; i < _objectives.length; i++) {
            bannedObjectives[_objectives[i]] = !_undoBan;
            if (_undoBan) {
                emit ObjectiveUnbanned(_objectives[i], objectivesLookup[_objectives[i]]);
            } else {
                emit ObjectiveBanned(_objectives[i], objectivesLookup[_objectives[i]]);
            }
        }
    }

    // admin function set and unset banned addresses
    function banAddresses(address[] memory _addresses, bool _undoBan) public onlyOwner() {
        for (uint i = 0; i < _addresses.length; i++) {
            bannedAddresses[_addresses[i]] = !_undoBan;
        }
    }

}