// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

// --- Libreria espansa: ReentrancyGuard ---
abstract contract ReentrancyGuard {
    uint256 private constant NOT_ENTERED = 1;
    uint256 private constant ENTERED = 2;

    uint256 private _status;

    error ReentrancyGuardReentrantCall();

    constructor() {
        _status = NOT_ENTERED;
    }

    modifier nonReentrant() {
        if (_status == ENTERED) revert ReentrancyGuardReentrantCall();
        _status = ENTERED;
        _;
        _status = NOT_ENTERED;
    }
}

// --- Libreria espansa: Pausable ---
abstract contract Pausable is Ownable {
    event Paused(address account);
    event Unpaused(address account);

    bool private _paused;

    constructor() {
        _paused = false;
    }

    function paused() public view returns (bool) {
        return _paused;
    }

    modifier whenNotPaused() {
        require(!_paused, "Pausable: paused");
        _;
    }

    modifier whenPaused() {
        require(_paused, "Pausable: not paused");
        _;
    }

    function _pause() internal whenNotPaused {
        _paused = true;
        emit Paused(msg.sender);
    }

    function _unpause() internal whenPaused {
        _paused = false;
        emit Unpaused(msg.sender);
    }
}

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC1155/extensions/ERC1155URIStorage.sol";
import "@openzeppelin/contracts/token/common/ERC2981.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

contract LHISA_LecceNFT is ERC1155URIStorage, Ownable, Pausable, ReentrancyGuard, ERC2981 {
    string public name = "LHISA-LecceNFT";
    string public symbol = "LHISA";

    mapping(uint256 => uint256) public maxSupply;
    mapping(uint256 => uint256) public totalMinted;
    mapping(uint256 => uint256) public pricesInWei;
    mapping(uint256 => bool) public isValidTokenId;
    mapping(uint256 => string) public encryptedURIs;
    /// @notice Valore informativo in euro per ciascun tokenId (NON aggiornato automaticamente in base al cambio ETH/EUR)
    
mapping(uint256 => uint256) public euroValueForTokenId;

    mapping(uint256 => string) public tokenCIDs;

    address public withdrawWallet;
    address public creatorWallet;
    uint256 public creatorSharePercentage;
    uint96 public defaultRoyaltyFeeNumerator;
    string public baseURI;
    
    bool public whitelistActive = false;
    mapping(address => bool) public whitelist;

    bool public limitToken100Active;
    mapping(address => uint256) public lastMintTimeToken100;
    mapping(address => uint256) public mintedToken100Last24h;

    struct Proposal {
        string description;
        uint256 startTime;
        uint256 endTime;
        uint256 yesVotes;
        uint256 noVotes;
        bool active;
        bool allowNewMintsToVote;
        mapping(address => uint256) balancesSnapshot;
    }
    mapping(uint256 => Proposal) public proposals;
    mapping(uint256 => mapping(address => bool)) public hasVoted;
    uint256 public nextProposalId;

    struct BurnRequest {
        address requester;
        uint256 tokenId;
        uint256 quantity;
        bool approved;
    }
    BurnRequest[] public burnRequests;

    uint256 public constant MINIMUM_TOTAL_VALUE = 84000;

    event NFTMinted(address indexed buyer, uint256 tokenId, uint256 quantity, uint256 price, string encryptedURI);
    event FundsWithdrawn(address indexed owner, uint256 amount);
    event BaseURIUpdated(string newBaseURI);
    event TokenCIDUpdated(uint256 indexed tokenId, string newCID);
    event TokenCIDsUpdated(uint256[] tokenIds, string[] newCIDs);
    event EncryptedURIUpdated(uint256 indexed tokenId, string newEncryptedURI);
    event EncryptedURIsUpdated(uint256[] tokenIds, string[] newEncryptedURIs);
    event NFTBurned(address indexed owner, uint256 tokenId, uint256 quantity);
    event BurnRequested(address indexed requester, uint256 tokenId, uint256 quantity, uint256 requestId);
    event BurnApproved(uint256 requestId, address indexed requester, uint256 tokenId, uint256 quantity);
    event BurnDenied(uint256 requestId, address indexed requester, uint256 tokenId, uint256 quantity);
    event CreatorShareTransferred(address indexed receiver, uint256 amount);
    event ProposalCreated(uint256 indexed proposalId, string description, uint256 startTime, uint256 endTime);
    event Voted(uint256 indexed proposalId, address indexed voter, bool vote, uint256 weight);
    event WithdrawWalletChanged(address indexed oldWallet, address indexed newWallet);
    event CreatorWalletChanged(address indexed oldWallet, address indexed newWallet);
    event PriceUpdated(uint256 indexed tokenId, uint256 oldPrice, uint256 newPrice);
    event LimitToken100ActiveChanged(bool newStatus);
    event WhitelistStatusChanged(bool status);

    constructor(
        string memory _baseURI,
        address _ownerAddress,
        address _creatorWalletAddress
    )
        ERC1155(_baseURI)
        Ownable(_ownerAddress)
    {
        require(bytes(_baseURI).length > 0, "Base URI cannot be empty");
        require(_ownerAddress != address(0), "Owner address cannot be zero");
        require(_creatorWalletAddress != address(0), "Creator wallet address cannot be zero");

        withdrawWallet = _ownerAddress;
        creatorWallet = _creatorWalletAddress;
        baseURI = _baseURI;
        creatorSharePercentage = 6;
        nextProposalId = 0;
        limitToken100Active = false;

        for (uint256 i = 5; i <= 100; i += 5) {
            pricesInWei[i] = i * 4 * 10**16;
            maxSupply[i] = 2000;
            isValidTokenId[i] = true;
        }
        tokenCIDs[100] = "bafybeibzvith6ji34mzhb7mgdtascuhvczxvg3yyt73prlzg7n4t56qhhe";
        encryptedURIs[100] = "bafybeibzvith6ji34mzhb7mgdtascuhvczxvg3yyt73prlzg7n4t56qhhe";
        tokenCIDs[95] = "bafybeiarkwmmlxudlutqyw6jhrln3kkq7uzhendqnmhrtvtsu5gyrz62hm";
        encryptedURIs[95] = "bafybeiarkwmmlxudlutqyw6jhrln3kkq7uzhendqnmhrtvtsu5gyrz62hm";
        tokenCIDs[90] = "bafybeides3vx3ibatjjrm3wr22outg6gxclmsnerkydx3njjcm64tik3we";
        encryptedURIs[90] = "bafybeides3vx3ibatjjrm3wr22outg6gxclmsnerkydx3njjcm64tik3we";
        tokenCIDs[85] = "bafybeif4pdz2jhwlgnnonqti7reqyvszwjja45uimijzd47coilmj6jmvm";
        encryptedURIs[85] = "bafybeif4pdz2jhwlgnnonqti7reqyvszwjja45uimijzd47coilmj6jmvm";
        tokenCIDs[80] = "bafybeiboe3heopn3ki57hkbdkb4uep6mvbwlcyh4q6frcl2fqnmucswp3u";
        encryptedURIs[80] = "bafybeiboe3heopn3ki57hkbdkb4uep6mvbwlcyh4q6frcl2fqnmucswp3u";
        tokenCIDs[75] = "bafybeicgqdtiilzd23o2hhvb2kxfshjnyvxnwcic7eyftjfpalkokvm7di";
        encryptedURIs[75] = "bafybeicgqdtiilzd23o2hhvb2kxfshjnyvxnwcic7eyftjfpalkokvm7di";
        tokenCIDs[70] = "bafybeih6gfu4hss72sqjoszdsla6mioo2fbaam2jeqn7y6saihydtvjqam";
        encryptedURIs[70] = "bafybeih6gfu4hss72sqjoszdsla6mioo2fbaam2jeqn7y6saihydtvjqam";
        tokenCIDs[65] = "bafybeidyqyawcirrqbauf3daygvgmoqzq63duhsl6auw7fbfma4xlnj7cy";
        encryptedURIs[65] = "bafybeidyqyawcirrqbauf3daygvgmoqzq63duhsl6auw7fbfma4xlnj7cy";
        tokenCIDs[60] = "bafybeift6clex5dhe6unqqhcstdn4l3votj5uvuoiwpa5rwlsh6jovpeti";
        encryptedURIs[60] = "bafybeift6clex5dhe6unqqhcstdn4l3votj5uvuoiwpa5rwlsh6jovpeti";
        tokenCIDs[55] = "bafybeihhmmci3qjz55j3g5y33yhszt5fpbwmsnx4fbzklgkyofhsxn3bte";
        encryptedURIs[55] = "bafybeihhmmci3qjz55j3g5y33yhszt5fpbwmsnx4fbzklgkyofhsxn3bte";
        tokenCIDs[50] = "bafybeiaexxgiukd46px63gjvggltykt3uoqs74ryvj5x577uvge66ntr2q";
        encryptedURIs[50] = "bafybeiaexxgiukd46px63gjvggltykt3uoqs74ryvj5x577uvge66ntr2q";
        tokenCIDs[45] = "bafybeicspxdws7au6kdms6lfpfhggqxdpfkrzmrvsue7kvii5ncfk7d7tq";
        encryptedURIs[45] = "bafybeicspxdws7au6kdms6lfpfhggqxdpfkrzmrvsue7kvii5ncfk7d7tq";
        tokenCIDs[40] = "bafybeibuga3bq442mvnqrjyazhbhd2k3oek3bgevaja7jxla5to72cqeri";
        encryptedURIs[40] = "bafybeibuga3bq442mvnqrjyazhbhd2k3oek3bgevaja7jxla5to72cqeri";
        tokenCIDs[35] = "bafybeif2titfww7kqsggfocbtmm6smu5qmw7hwthaahaxjc7xzs2yf5yqq";
        encryptedURIs[35] = "bafybeif2titfww7kqsggfocbtmm6smu5qmw7hwthaahaxjc7xzs2yf5yqq";
        tokenCIDs[30] = "bafybeieqbykqxdjskgch5vtgkucvyvrbjtucpid47lwa3r3aejjc3xvbda";
        encryptedURIs[30] = "bafybeieqbykqxdjskgch5vtgkucvyvrbjtucpid47lwa3r3aejjc3xvbda";
        tokenCIDs[25] = "bafybeibo26hejdplqocrgxtg33lgdasqjuzzwkbs6cdrg7hdrkhehskukm";
        encryptedURIs[25] = "bafybeibo26hejdplqocrgxtg33lgdasqjuzzwkbs6cdrg7hdrkhehskukm";
        tokenCIDs[20] = "bafybeibk63t4vnlqpimomeeylnam2b52qdfdcx5bcfdxqtyiod2d6qnomy";
        encryptedURIs[20] = "bafybeibk63t4vnlqpimomeeylnam2b52qdfdcx5bcfdxqtyiod2d6qnomy";
        tokenCIDs[15] = "bafybeiek35bzmmhop35isxwade6ezfgsb466mhwoxr27zfwlly7etvpqo4";
        encryptedURIs[15] = "bafybeiek35bzmmhop35isxwade6ezfgsb466mhwoxr27zfwlly7etvpqo4";
        tokenCIDs[10] = "bafybeigpqqaoft52a7dp2kkzcn5zapig7zgftcfrt2fbiqqnm55mwut6lq";
        encryptedURIs[10] = "bafybeigpqqaoft52a7dp2kkzcn5zapig7zgftcfrt2fbiqqnm55mwut6lq";
        tokenCIDs[5] = "bafybeickzstleqd6hnjcsvp7bjc6tbsu7jqhmwzubws5qu7r64e3h4zhyq";
        encryptedURIs[5] = "bafybeickzstleqd6hnjcsvp7bjc6tbsu7jqhmwzubws5qu7r64e3h4zhyq";
        
        // Valore informativo in euro per ogni tokenId (SOLO a scopo informativo, NON aggiornato con cambio ETH/EUR)
        euroValueForTokenId[100] = 2;    // 100 LHI = 2 euro
        euroValueForTokenId[50]  = 1;    // 50 LHI  = 1 euro
        euroValueForTokenId[10]  = 0;    // 10 LHI  = 0 euro
        
        _setDefaultRoyalty(_creatorWalletAddress, 500);
        defaultRoyaltyFeeNumerator = 500;
    }

    // --- Whitelist controls ---
    function setWhitelist(address[] calldata addresses, bool status) external onlyOwner {
        for (uint256 i = 0; i < addresses.length; ++i) {
            whitelist[addresses[i]] = status;
        }
    }
    function setWhitelistActive(bool status) external onlyOwner {
        whitelistActive = status;
        emit WhitelistStatusChanged(status);
    }

    // --- Pausable controls ---
    function pause() external onlyOwner { _pause(); }
    function unpause() external onlyOwner { _unpause(); }

    // --- Limitazione futura mint 100 ---
    function setLimitToken100Active(bool active) external onlyOwner {
        limitToken100Active = active;
        emit LimitToken100ActiveChanged(active);
    }
    function _checkMintLimitToken100(address user, uint256 quantity) internal view returns (bool) { // Ora restituisce un bool
        if (!limitToken100Active) return true; // Restituisce esplicitamente true
        uint256 nowTime = block.timestamp;
           if (nowTime - lastMintTimeToken100[user] > 1 days) {
           mintedToken100Last24h[user] = 0;
           lastMintTimeToken100[user] = nowTime;
           }
           require(mintedToken100Last24h[user] + quantity <= 100, "Mint limit for token 100 exceeded in 24h");
           return true; // Restituisce true se tutti i controlli passano
    }
    // --- Mint (singolo) ---
    function mintNFT(uint256 tokenId, uint256 quantity) external payable whenNotPaused nonReentrant {
        if (whitelistActive) {
            require(whitelist[msg.sender], "Not whitelisted for mint");
        }
        require(isValidTokenId[tokenId], "The provided tokenId is not supported");
        require(totalMinted[tokenId] + quantity <= maxSupply[tokenId], "Minting exceeds maximum supply");
        require(quantity > 0, "Mint quantity must be greater than zero");
        if (tokenId == 100) {
            _checkMintLimitToken100(msg.sender, quantity);
        }

        uint256 totalCostInWei = pricesInWei[tokenId] * quantity;
        require(msg.value == totalCostInWei, "Incorrect ETH amount sent for minting");

        uint256 creatorShare = (totalCostInWei * creatorSharePercentage) / 100;
        if (creatorShare > 0) {
            (bool successCreator, ) = creatorWallet.call{value: creatorShare}("");
            require(successCreator, "Failed to transfer creator share");
            emit CreatorShareTransferred(creatorWallet, creatorShare);
        }

        totalMinted[tokenId] += quantity;
        _mint(msg.sender, tokenId, quantity, "");
        emit NFTMinted(msg.sender, tokenId, quantity, pricesInWei[tokenId], encryptedURIs[tokenId]);
    }

    // --- Batch Mint ---
    function mintBatchNFT(uint256[] calldata tokenIds, uint256[] calldata quantities) external payable whenNotPaused nonReentrant {
        if (whitelistActive) {
            require(whitelist[msg.sender], "Not whitelisted for mint");
        }
        require(tokenIds.length == quantities.length, "Arrays length mismatch");
        uint256 totalCost = 0;
        for (uint256 i = 0; i < tokenIds.length; ++i) {
            uint256 tokenId = tokenIds[i];
            uint256 quantity = quantities[i];
            require(isValidTokenId[tokenId], "Invalid tokenId");
            require(quantity > 0, "Quantity must be > 0");
            require(totalMinted[tokenId] + quantity <= maxSupply[tokenId], "Exceeds max supply");
            if (tokenId == 100) {
                _checkMintLimitToken100(msg.sender, quantity);
            }
            totalCost += pricesInWei[tokenId] * quantity;
        }
        require(msg.value == totalCost, "Incorrect ETH amount sent for batch minting");

        for (uint256 i = 0; i < tokenIds.length; ++i) {
            totalMinted[tokenIds[i]] += quantities[i];
        }
        _mintBatch(msg.sender, tokenIds, quantities, "");

        uint256 creatorShare = (totalCost * creatorSharePercentage) / 100;
        if (creatorShare > 0) {
            (bool successCreator, ) = creatorWallet.call{value: creatorShare}("");
            require(successCreator, "Failed to transfer creator share");
            emit CreatorShareTransferred(creatorWallet, creatorShare);
        }
        for (uint256 i = 0; i < tokenIds.length; ++i) {
            emit NFTMinted(msg.sender, tokenIds[i], quantities[i], pricesInWei[tokenIds[i]], encryptedURIs[tokenIds[i]]);
        }
    }

    // --- Burn ---
    function burn(address account, uint256 tokenId, uint256 quantity) external whenNotPaused {
        require(
            account == msg.sender || isApprovedForAll(account, msg.sender),
            "Caller is not owner nor approved"
        );
        _burn(account, tokenId, quantity);
        totalMinted[tokenId] -= quantity;
        emit NFTBurned(account, tokenId, quantity);
    }

    // --- Withdraw ---
    function withdraw() external onlyOwner nonReentrant {
        uint256 balance = address(this).balance;
        require(balance > 0, "Nothing to withdraw");
        (bool sent, ) = payable(withdrawWallet).call{value: balance}("");
        require(sent, "Withdraw failed");
        emit FundsWithdrawn(withdrawWallet, balance);
    }
    
        // --- Governance: Proposal & voto quadratico con snapshot ---
    function createProposal(
        string calldata description,
        uint256 startTime,
        uint256 endTime,
        bool allowNewMintsToVote
    ) external onlyOwner {
        require(startTime < endTime, "Start must be before end");
        Proposal storage prop = proposals[nextProposalId];
        prop.description = description;
        prop.startTime = startTime;
        prop.endTime = endTime;
        prop.yesVotes = 0;
        prop.noVotes = 0;
        prop.active = true;
        prop.allowNewMintsToVote = allowNewMintsToVote;
        emit ProposalCreated(nextProposalId, description, startTime, endTime);
        nextProposalId++;
    }

    function voteOnProposal(uint256 proposalId, bool support) external whenNotPaused {
        require(proposalId < nextProposalId, "Invalid proposal");
        Proposal storage prop = proposals[proposalId];
        require(prop.active, "Proposal not active");
        require(block.timestamp >= prop.startTime && block.timestamp <= prop.endTime, "Voting not allowed at this time");
        require(!hasVoted[proposalId][msg.sender], "Already voted");

        if (prop.balancesSnapshot[msg.sender] == 0) {
            uint256 balance = 0;
            for (uint256 i = 5; i <= 100; i += 5) {
                balance += balanceOf(msg.sender, i);
            }
            require(balance > 0, "Must own at least one NFT to vote");
            prop.balancesSnapshot[msg.sender] = balance;
        }
        uint256 voteWeight = sqrt(prop.balancesSnapshot[msg.sender]);

        hasVoted[proposalId][msg.sender] = true;
        if (support) {
            prop.yesVotes += voteWeight;
        } else {
            prop.noVotes += voteWeight;
        }
        emit Voted(proposalId, msg.sender, support, voteWeight);
    }

    function endProposal(uint256 proposalId) external onlyOwner {
        Proposal storage proposal = proposals[proposalId];
        require(proposal.active, "Proposal not active");
        require(block.timestamp > proposal.endTime, "Voting period has not ended yet");
        proposal.active = false;
    }

    function getProposalResults(uint256 proposalId) public view returns (string memory description, uint256 yesVotes, uint256 noVotes, bool active, uint256 startTime, uint256 endTime) {
        Proposal storage proposal = proposals[proposalId];
        return (proposal.description, proposal.yesVotes, proposal.noVotes, proposal.active, proposal.startTime, proposal.endTime);
    }

    // --- Burn Request ---
    function requestBurn(uint256 tokenId, uint256 quantity) external {
        require(isValidTokenId[tokenId], "Invalid tokenId");
        require(balanceOf(msg.sender, tokenId) >= quantity, "Insufficient balance");

        burnRequests.push(BurnRequest({
            requester: msg.sender,
            tokenId: tokenId,
            quantity: quantity,
            approved: false
        }));
        uint256 requestId = burnRequests.length - 1;
        emit BurnRequested(msg.sender, tokenId, quantity, requestId);
    }

    function approveBurn(uint256 requestId, bool approve) external onlyOwner {
        require(requestId < burnRequests.length, "Invalid requestId");
        BurnRequest storage request = burnRequests[requestId];
        require(!request.approved, "Request already processed");

        if (approve) {
            uint256 totalValueAfterBurn = calculateTotalValueAfterBurn(request.tokenId, request.quantity);
            require(totalValueAfterBurn >= MINIMUM_TOTAL_VALUE, "Cannot burn below minimum total value");
            _burn(request.requester, request.tokenId, request.quantity);
            totalMinted[request.tokenId] -= request.quantity;
            request.approved = true;
            emit BurnApproved(requestId, request.requester, request.tokenId, request.quantity);
        } else {
            emit BurnDenied(requestId, request.requester, request.tokenId, request.quantity);
        }
    }

    function calculateTotalValueAfterBurn(uint256 tokenId, uint256 quantity) public view returns (uint256) {
        uint256 totalValue = 0;
        uint256[] memory mintedTokens = new uint256[](20);
        uint256 idx = 0;
        for (uint256 i = 5; i <= 100; i += 5) {
            mintedTokens[idx] = totalMinted[i];
            idx++;
        }
        uint256 tokenArrayIndex = (tokenId / 5) - 1;
        require(tokenArrayIndex < 20, "Token ID not in burn calculation range");
        mintedTokens[tokenArrayIndex] -= quantity;

        idx = 0;
        for (uint256 i = 5; i <= 100; i += 5) {
            totalValue += mintedTokens[idx] * pricesInWei[i];
            idx++;
        }
        return totalValue;
    }

    // --- Utility Functions ---
    function sqrt(uint256 x) internal pure returns (uint256 y) {
        if (x == 0) return 0;
        uint256 z = (x + 1) / 2;
        y = x;
        while (z < y) {
            y = z;
            z = (x / z + z) / 2;
        }
        return y;
    }

    // --- Aggiorna Prezzi e Wallet con eventi ---
    function updatePrice(uint256 tokenId, uint256 newPrice) external onlyOwner {
        require(isValidTokenId[tokenId], "Invalid tokenId");
        uint256 oldPrice = pricesInWei[tokenId];
        pricesInWei[tokenId] = newPrice;
        emit PriceUpdated(tokenId, oldPrice, newPrice);
    }
    function updateWithdrawWallet(address newWallet) external onlyOwner {
        require(newWallet != address(0), "Invalid wallet");
        address old = withdrawWallet;
        withdrawWallet = newWallet;
        emit WithdrawWalletChanged(old, newWallet);
    }

    function updateCreatorWallet(address newWallet) external onlyOwner {
        require(newWallet != address(0), "Invalid wallet");
        address old = creatorWallet;
        creatorWallet = newWallet;
        emit CreatorWalletChanged(old, newWallet);
        _setDefaultRoyalty(newWallet, defaultRoyaltyFeeNumerator);
    }
    
    // --- Royalties ERC2981 ---
    function setDefaultRoyalty(address receiver, uint96 feeNumerator) external onlyOwner {
        _setDefaultRoyalty(receiver, feeNumerator);
        defaultRoyaltyFeeNumerator = feeNumerator;
    }    

    // --- ERC1155 URI ---
    function uri(uint256 tokenId) public view override returns (string memory) {
        require(isValidTokenId[tokenId], "The provided tokenId is not supported");
        return string(abi.encodePacked(baseURI, Strings.toString(tokenId), ".json"));
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override(ERC1155, ERC2981)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }

    // --- Funzioni Owner per aggiornare baseURI, tokenCIDs ed encryptedURIs ---
    function setBaseURI(string memory newBaseURI) external onlyOwner {
        baseURI = newBaseURI;
        emit BaseURIUpdated(newBaseURI);
    }

    function setTokenCID(uint256 tokenId, string memory newCID) external onlyOwner {
        require(isValidTokenId[tokenId], "TokenId non valido");
        tokenCIDs[tokenId] = newCID;
        emit TokenCIDUpdated(tokenId, newCID);
    }

    function setTokenCIDs(uint256[] calldata tokenIds, string[] calldata newCIDs) external onlyOwner {
        require(tokenIds.length == newCIDs.length, "Array length mismatch");
        for (uint256 i = 0; i < tokenIds.length; ++i) {
            require(isValidTokenId[tokenIds[i]], "TokenId non valido");
            tokenCIDs[tokenIds[i]] = newCIDs[i];
        }
        emit TokenCIDsUpdated(tokenIds, newCIDs);
    }

    function setEncryptedURI(uint256 tokenId, string memory newEncryptedURI) external onlyOwner {
        require(isValidTokenId[tokenId], "TokenId non valido");
        encryptedURIs[tokenId] = newEncryptedURI;
        emit EncryptedURIUpdated(tokenId, newEncryptedURI);
    }

    function setEncryptedURIs(uint256[] calldata tokenIds, string[] calldata newEncryptedURIs) external onlyOwner {
        require(tokenIds.length == newEncryptedURIs.length, "Array length mismatch");
        for (uint256 i = 0; i < tokenIds.length; ++i) {
            require(isValidTokenId[tokenIds[i]], "TokenId non valido");
            encryptedURIs[tokenIds[i]] = newEncryptedURIs[i];
        }
        emit EncryptedURIsUpdated(tokenIds, newEncryptedURIs);
    }

    // --- Funzioni di lettura pubblica per trasparenza ---
    function getTokenCID(uint256 tokenId) public view returns (string memory) {
        return tokenCIDs[tokenId];
    }
    function getEncryptedURI(uint256 tokenId) public view returns (string memory) {
        return encryptedURIs[tokenId];
    }
    function getAllTokenCIDs() public view returns (string[] memory) {
        string[] memory cids = new string[](20);
        uint256 idx = 0;
        for (uint256 i = 5; i <= 100; i += 5) {
            cids[idx] = tokenCIDs[i];
            idx++;
        }
        return cids;
    }
    function getAllEncryptedURIs() public view returns (string[] memory) {
        string[] memory uris = new string[](20);
        uint256 idx = 0;
        for (uint256 i = 5; i <= 100; i += 5) {
            uris[idx] = encryptedURIs[i];
            idx++;
        }
        return uris;
    }
    
    receive() external payable {
        revert("Direct ETH transfers not allowed");
    }
    
    fallback() external payable {
        revert("Fallback not allowed");
    }
}
