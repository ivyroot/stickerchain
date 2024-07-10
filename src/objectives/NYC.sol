// SPDX-License-Identifier: MIT

pragma solidity ^0.8.24;
import {Ownable} from "openzeppelin-contracts/contracts/access/Ownable.sol";
import {ERC20} from "openzeppelin-contracts/contracts/token/ERC20/ERC20.sol";
import {IERC721} from "openzeppelin-contracts/contracts/token/ERC721/IERC721.sol";
import {IStickerObjective, FreshSlap} from "../IStickerObjective.sol";


//      _    _   ___     _______
//     | |  | \ | \ \   / / ____|
//    / __) |  \| |\ \_/ / |
//    \__ \ |   ` | \   /| |
//    (   / | |\  |  | | | |____
//     |_|  |_| \_|  |_|  \_____|
//
//
//    Slap at places in NYC to play (see list below).
//
//    Earn $NYC based on how many seconds your slap is up.
//    EMISSION RATE X SECONDS LIVE accrues to a slap
//    at the time it is slapped over.
//
//    The emission rate decreases by 20% every week.
//





struct PlaceSlapInfo {
    uint256 slapId;
    uint64 slapTime;
}

contract NYC is ERC20, IStickerObjective, Ownable {

    error InvalidCaller();

    address immutable public stickerChain;
    uint256 immutable public genesisTime;
    string public url;
    address public feeRecipient;
    uint256 public paymentMethodId;
    uint256 public slapFee;
    uint256 public constant placeCount = 65;
    mapping (uint => bool) public placeIncluded;
    mapping (uint => PlaceSlapInfo) public currentSlaps;

    uint private emissionRate;
    uint private lastUpdateOfEmissionRate;

    constructor(address _stickerChain, address _initialAdmin, string memory _name, string memory _ticker, string memory _url)
        Ownable(_initialAdmin)
        ERC20(_name, _ticker)
    {
        stickerChain = _stickerChain;
        feeRecipient = _initialAdmin;

        genesisTime = block.timestamp;
        emissionRate = 1 ether;
        lastUpdateOfEmissionRate = genesisTime;

        url = _url;
        uint[] memory places = placeList();
        for (uint i = 0; i < placeCount; i++) {
            placeIncluded[places[i]] = true;
        }
    }


    uint private constant decayFactor = 8 * (1 ether / 10); // 0.8 represented as a fraction of 1 ether

    function getOrUpdateEmissionRate() private returns (uint) {
        // decrease emission rate every week
        if ((block.timestamp - lastUpdateOfEmissionRate) > 604800) {
            emissionRate = emissionRate * decayFactor / 1 ether;
            lastUpdateOfEmissionRate = block.timestamp;
        }
        return emissionRate;
    }

    function name() public view override(ERC20, IStickerObjective) returns (string memory) {
        return ERC20.name();
    }

    function owner() public view override(Ownable, IStickerObjective) returns (address) {
        return Ownable.owner();
    }

    // owner only method to set url
    function setUrl(string memory _url) external onlyOwner {
        url = _url;
    }

    function setFeeRecipient(address _feeRecipient) external onlyOwner {
        feeRecipient = _feeRecipient;
    }

    // owner only method to set slap fee
    function setSlapFee(uint256 _paymentMethodId, uint256 _slapFee) external onlyOwner {
        paymentMethodId = _paymentMethodId;
        slapFee = _slapFee;
    }


    function placeList() public pure override returns (uint[] memory _places) {
        _places = new uint[](placeCount);
        _places[0] = 7080610075; // Bowling Green
        _places[1] = 7080611099;
        _places[2] = 7080610079;
        _places[3] = 7080611103;
        _places[4] = 7147618591;
        _places[5] = 7147619615;
        _places[6] = 7147620639;
        _places[7] = 7147618595;
        _places[8] = 7080611107;
        _places[9] = 7147619619; // Tompkins Square
        _places[10] = 7147620643;
        _places[11] = 7080611111;
        _places[12] = 7147618599; // Union Square
        _places[13] = 7147619623;
        _places[14] = 7147620647;
        _places[15] = 7080611115;
        _places[16] = 7147618603;
        _places[17] = 7147619627;
        _places[18] = 7147620651;
        _places[19] = 7080611119;
        _places[20] = 7147618607;
        _places[21] = 7147619631; // Times Square
        _places[22] = 7147620655;
        _places[23] = 7147621679;
        _places[24] = 7147618611;
        _places[25] = 7147619635;
        _places[26] = 7147620659;
        _places[27] = 7147621683;
        _places[28] = 7147622707;
        _places[29] = 7147619639;
        _places[30] = 7147620663;
        _places[31] = 7147621687;
        _places[32] = 7147622711;
        _places[33] = 7147623735;
        _places[34] = 7147619643;
        _places[35] = 7147620667;
        _places[36] = 7147621691;
        _places[37] = 7147622715;
        _places[38] = 7147623739;
        _places[39] = 7147620671;
        _places[40] = 7147621695;
        _places[41] = 7147622719;
        _places[42] = 7147623743;
        _places[43] = 7147621703;
        _places[44] = 7147624767;
        _places[45] = 7147621699;
        _places[46] = 7147622723;
        _places[47] = 7147623747;
        _places[48] = 7147624771;
        _places[49] = 7147622727;
        _places[50] = 7147623751;
        _places[51] = 7147624775;
        _places[52] = 7147622731;
        _places[53] = 7147623755;
        _places[54] = 7147624779;
        _places[55] = 7147623759;
        _places[56] = 7147624783;
        _places[57] = 7147623763;
        _places[58] = 7147624787;
        _places[59] = 7147624791;
        _places[60] = 7147624795;
        _places[61] = 7147625815;
        _places[62] = 7147625819;
        _places[63] = 7147626843;
        _places[64] = 7147625823; // Inwood Hill Park
    }

    function costOfSlaps(address, FreshSlap[] calldata slaps)
    public view override
    returns (uint _paymentMethodId, uint _cost, address _recipient)
    {
        uint totalCost;
        for (uint i = 0; i < slaps.length; i++) {
            if (placeIncluded[slaps[i].placeId]) {
                totalCost += slapFee;
            }
        }
        return (paymentMethodId, totalCost, feeRecipient);
    }

    function slapInObjective(address, FreshSlap[] calldata slaps) public payable override returns (uint[] memory includedSlapIds) {
        if (msg.sender != stickerChain) {
            revert InvalidCaller();
        }
        includedSlapIds = new uint[](slaps.length);
        uint _emissionRate = getOrUpdateEmissionRate();
        for (uint i = 0; i < slaps.length; i++) {
            if (placeIncluded[slaps[i].placeId]) {
                // emit tokens to slapped over player
                PlaceSlapInfo memory currentSlap = currentSlaps[slaps[i].placeId];
                if (currentSlap.slapId != 0) {
                    address slapOwner = IERC721(stickerChain).ownerOf(currentSlap.slapId);
                    uint accruedTotal = (block.timestamp - currentSlap.slapTime) * _emissionRate;
                    _mint(slapOwner, accruedTotal);
                }

                // put new slap at place
                 currentSlaps[slaps[i].placeId] = PlaceSlapInfo({
                    slapId: slaps[i].slapId,
                    slapTime: uint64(block.timestamp)
                 });

                // include slap in success list
                includedSlapIds[i] = slaps[i].slapId;
            }
        }
    }
}