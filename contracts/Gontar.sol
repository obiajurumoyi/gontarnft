// contracts/Gontar.sol
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/utils/Base64.sol";
import "@chainlink/contracts/src/v0.8/interfaces/VRFCoordinatorV2Interface.sol";
import "@chainlink/contracts/src/v0.8/vrf/VRFConsumerBaseV2.sol";
import "@chainlink/contracts/src/v0.8/shared/access/ConfirmedOwner.sol";

/**
 * Request testnet LINK and ETH here: https://faucets.chain.link/
 * Find information on LINK Token Contracts and get the latest ETH and LINK faucets here: https://docs.chain.link/docs/link-token-contracts/
 */

/**
 * THIS IS AN EXAMPLE CONTRACT THAT USES HARDCODED VALUES FOR CLARITY.
 * THIS IS AN EXAMPLE CONTRACT THAT USES UN-AUDITED CODE.
 * DO NOT USE THIS CODE IN PRODUCTION.
 */

contract GontarV9 is VRFConsumerBaseV2, ConfirmedOwner,ERC721URIStorage {
    event RequestSent(uint256 requestId, uint32 numWords);
    event RequestFulfilled(uint256 requestId, uint256[] randomWords);

    using Strings for uint256;
    using Counters for Counters.Counter;

    Counters.Counter private _tokenIds;

    string[4] private _randomURIs = ["ipfs://bafybeiftyqrafajaxxhicwbe5njg3fmrzw4evx4i5qwoxlr3filyzp27eu",
    "ipfs://bafybeig6ke7g3wtgdmwzimli63kyy6c7buvbn7etkgecknqd46se7o2fvy",
    "ipfs://bafybeidlzofg7caxfrnj2em4uzxxgprych3oqfxypi2b6aaf7d7cqhblfy",
    "ipfs://bafybeia57f2gr35snw3wmxnmenn6u6o7nwdm6ufzg6o5nct3eauxkdbusq"];

    struct GontarPack {
        uint256 energy;
        uint256 speed;
        uint256 jump;
        uint256 stamina;
        uint256 physique;
        uint256 focus;
    }
    uint256 constant MAX_VALUE = 100;

    mapping(uint => GontarPack) public gontarPacks;

    struct RequestStatus {
        bool fulfilled; // whether the request has been successfully fulfilled
        bool exists; // whether a requestId exists
        uint256[] randomWords;
    }
    mapping(uint256 => RequestStatus)
        public s_requests; /* requestId --> requestStatus */
    VRFCoordinatorV2Interface COORDINATOR;

    // Your subscription ID.
    uint64 s_subscriptionId;

    // past requests Id.
    uint256[] public requestIds;
    uint256 public lastRequestId;

    // The gas lane to use, which specifies the maximum gas price to bump to.
    // For a list of available gas lanes on each network,
    // see https://docs.chain.link/docs/vrf/v2/subscription/supported-networks/#configurations
    bytes32 keyHash = 0x4b09e658ed251bcafeebbc69400383d49f344ace09b9576fe248bb02c003fe9f;


    // Depends on the number of requested values that you want sent to the
    // fulfillRandomWords() function. Storing each word costs about 20,000 gas,
    // so 100,000 is a safe default for this example contract. Test and adjust
    // this limit based on the network that you select, the size of the request,
    // and the processing of the callback request in the fulfillRandomWords()
    // function.
    uint32 callbackGasLimit = 1000000;

    // The default is 3, but you can set this higher.
    uint16 requestConfirmations = 3;

    // For this example, retrieve 2 random values in one request.
    // Cannot exceed VRFCoordinatorV2.MAX_NUM_WORDS.
    uint32 numWords = 7;

    /**
     * HARDCODED FOR SEPOLIA
     * COORDINATOR: 0x8103B0A8A00be2DDC778e6e7eaa21791Cd364625
     */
     constructor(uint64 subscriptionId) ERC721("Gontar Warriors","GTWRS") VRFConsumerBaseV2(0x7a1BaC17Ccc5b313516C5E16fb24f7659aA5ebed) ConfirmedOwner(msg.sender)
    {
        COORDINATOR = VRFCoordinatorV2Interface(
            0x7a1BaC17Ccc5b313516C5E16fb24f7659aA5ebed
        );
        s_subscriptionId = subscriptionId;
    }

    function setImageUri(uint256 randNum) internal view returns(string memory){
        return _randomURIs[randNum];
    }

    function setNFTTraits(uint256 randNum1,uint256 randNum2,uint256 randNum3,
    uint256 randNum4,uint256 randNum5,uint256 randNum6) internal pure returns(string memory){
        return string(abi.encodePacked(
            '{','"trait_type": "energy",', 
      '"value": ', randNum1.toString(),',',
      '"max_value": ',MAX_VALUE.toString(),'}',',', 
    '{','"trait_type": "speed",', 
      '"value": ', randNum2.toString(),',',
      '"max_value": ',MAX_VALUE.toString(),'}',',', 
    '{','"trait_type": "jump",', 
      '"value": ', randNum3.toString(),',',
      '"max_value": ',MAX_VALUE.toString(),'}',',',
    '{','"trait_type": "stamina",', 
      '"value": ', randNum4.toString(),',',
      '"max_value": ',MAX_VALUE.toString(),'}',',',
    '{','"trait_type": "physique",', 
      '"value": ', randNum5.toString(),',',
      '"max_value": ',MAX_VALUE.toString(),'}',',',
    '{','"trait_type": "focus",', 
      '"value": ', randNum6.toString(),',',
      '"max_value": ',MAX_VALUE.toString(),'}'
        ));}
    function getTokenURI(uint256 tokenId,uint256 randNum1, uint256 randNum2, uint256 randNum3, uint256 randNum4, uint256 randNum5, uint256 randNum6,uint256 randNum7) public view returns (string memory){

        string memory dataURI = Base64.encode(bytes(string(abi.encodePacked(
            '{',
                '"name": "Gontar #', tokenId.toString(), '",',
                '"description": "Battles on chain",',
                '"image": "', setImageUri(randNum1), '",',
                '"attributes": [', setNFTTraits(randNum2, randNum3, randNum4, randNum5, randNum6, randNum7),']','}'
        ))));
    return string(abi.encodePacked("data:application/json;base64,",dataURI));
    }

    function mint(uint256 _requestId) public {
    (bool fufilled, uint256[] memory randomWords) = getRequestStatus(_requestId);
    require(fufilled,"Request not fufilled");
    _tokenIds.increment();
    uint256 newItemId = _tokenIds.current();
    _safeMint(msg.sender, newItemId);
    uint256 randNum1 = randomWords[0] % 4;
    uint256 randNum2 = randomWords[1] % 100;
    gontarPacks[newItemId].energy = randNum2;
    uint256 randNum3 = randomWords[2] % 100;
    gontarPacks[newItemId].speed = randNum3;
    uint256 randNum4 = randomWords[3] % 100;
    gontarPacks[newItemId].jump = randNum4;
    uint256 randNum5 = randomWords[4] % 100;
    gontarPacks[newItemId].stamina = randNum5;
    uint256 randNum6 = randomWords[5] % 100;
    gontarPacks[newItemId].physique = randNum6;
    uint256 randNum7 = randomWords[6] % 100;
    gontarPacks[newItemId].focus = randNum7;
    _setTokenURI(newItemId, getTokenURI(newItemId,randNum1,randNum2,randNum3,randNum4,randNum5,randNum6,randNum7));
}

    // Assumes the subscription is funded sufficiently.
    function requestRandomWords()
        external
        onlyOwner
        returns (uint256 requestId)
    {
        // Will revert if subscription is not set and funded.
        requestId = COORDINATOR.requestRandomWords(
            keyHash,
            s_subscriptionId,
            requestConfirmations,
            callbackGasLimit,
            numWords
        );
        s_requests[requestId] = RequestStatus({
            randomWords: new uint256[](0),
            exists: true,
            fulfilled: false
        });
        requestIds.push(requestId);
        lastRequestId = requestId;
        emit RequestSent(requestId, numWords);
        return requestId;
    }

    function fulfillRandomWords(
        uint256 _requestId,
        uint256[] memory _randomWords
    ) internal override {
        require(s_requests[_requestId].exists, "request not found");
        s_requests[_requestId].fulfilled = true;
        s_requests[_requestId].randomWords = _randomWords;
        emit RequestFulfilled(_requestId, _randomWords);
    }

    function getRequestStatus(
        uint256 _requestId
    ) public view returns (bool fulfilled, uint256[] memory randomWords) {
        require(s_requests[_requestId].exists, "request not found");
        RequestStatus memory request = s_requests[_requestId];
        return (request.fulfilled, request.randomWords);
    }

    function getGontarPacks(
        uint256 _requestId
    ) public view returns (GontarPack memory) {
        return gontarPacks[_requestId];
    }
}
