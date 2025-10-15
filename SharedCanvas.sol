// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/// @title SharedCanvas — collaborative on-chain canvas with no imports, no constructor, and no input fields
/// @notice Users interact with no-arg functions (paint, cycleColor, claimPixel). Admin initializes once (no args).
contract SharedCanvas {
    // --- ADMIN ---
    address public admin = msg.sender; // set at deployment time (no explicit constructor)
    bool public initialized = false;
    bool public finalized = false;

    // --- CANVAS CONFIG ---
    uint public width;    // canvas width (pixels)
    uint public height;   // canvas height
    uint public totalCells; // width * height
    uint public nextIndex = 0; // next pixel index to paint (0..totalCells-1)

    // color palette (strings for human readable; color index used on-chain)
    string[] private palette;

    // Pixel storage (flattened index = y * width + x)
    mapping(uint => address) public pixelOwner; // owner address of pixel index
    mapping(uint => uint8) public pixelColorIndex; // palette index for pixel
    mapping(uint => bool) public pixelClaimed; // if pixel was claimed (reserved) before painting

    // Per-user state
    mapping(address => uint8) public myColorIndex; // selected palette index per user
    mapping(address => uint[]) private myPixels;   // list of pixel indices painted by user
    mapping(address => uint) public lastPaintAt;   // cooldown timestamp for paint

    // Cooldown to prevent spam (demo-level)
    uint public constant COOLDOWN_SECONDS = 30;

    // Events
    event Initialized(address indexed admin, uint width, uint height, uint paletteSize);
    event Paint(address indexed painter, uint indexed pixelIndex, uint8 colorIndex);
    event ColorCycled(address indexed user, uint8 newColorIndex);
    event PixelClaimed(address indexed claimer, uint indexed pixelIndex);
    event CanvasCleared(address indexed admin);
    event Finalized(address indexed admin);

    // --- MODIFIERS ---
    modifier onlyAdmin() {
        require(msg.sender == admin, "only admin");
        _;
    }
    modifier isInitialized() {
        require(initialized, "not initialized");
        _;
    }
    modifier notFinalized() {
        require(!finalized, "canvas finalized");
        _;
    }

    // -----------------------
    // Initialization (no-arg)
    // -----------------------
    /// @notice Admin initializes the canvas and palette. Call once (no args).
    /// Internally hardcodes a sensible default canvas + palette.
    function initialize() external onlyAdmin {
        require(!initialized, "already initialized");

        // Default canvas size (change here if you want different default)
        width = 16;
        height = 16;
        totalCells = width * height;

        // Default palette (human-readable strings). Use these indices on-chain.
        palette.push("transparent"); // index 0 -> empty / transparent
        palette.push("red");         // 1
        palette.push("orange");      // 2
        palette.push("yellow");      // 3
        palette.push("green");       // 4
        palette.push("blue");        // 5
        palette.push("indigo");      // 6
        palette.push("violet");      // 7
        palette.push("black");       // 8
        palette.push("white");       // 9

        initialized = true;
        finalized = false;
        nextIndex = 0;

        emit Initialized(msg.sender, width, height, palette.length);
    }

    // -----------------------
    // User actions (no-arg)
    // -----------------------

    /// @notice Paint the next available pixel using your currently selected color (no args).
    /// Pixel assignment is scanline order (0..totalCells-1). Respects per-user cooldown.
    function paint() external isInitialized notFinalized {
        require(nextIndex < totalCells, "canvas is full");
        require(block.timestamp >= lastPaintAt[msg.sender] + COOLDOWN_SECONDS, "paint cooldown");

        // If next pixel is claimed by someone else, skip until unclaimed or claimed by caller
        uint idx = nextIndex;
        while (idx < totalCells && pixelClaimed[idx] && pixelOwner[idx] != msg.sender) {
            idx++;
        }
        require(idx < totalCells, "no available pixel to paint right now");

        // Paint it
        uint8 color = myColorIndex[msg.sender];
        pixelOwner[idx] = msg.sender;
        pixelColorIndex[idx] = color;
        // if it was claimed by caller, mark claimed false (we painted it)
        if (pixelClaimed[idx] && pixelOwner[idx] == msg.sender) {
            pixelClaimed[idx] = false;
        }
        myPixels[msg.sender].push(idx);
        lastPaintAt[msg.sender] = block.timestamp;

        // Advance nextIndex forward to the next unpainted cell
        uint forward = idx + 1;
        while (forward < totalCells && pixelOwner[forward] != address(0)) {
            forward++;
        }
        nextIndex = forward;

        emit Paint(msg.sender, idx, color);
    }

    /// @notice Cycle the caller's selected color to the next palette index (no args).
    /// Wraps around to 0.
    function cycleColor() external isInitialized notFinalized {
        require(palette.length > 0, "palette empty");
        myColorIndex[msg.sender] = (myColorIndex[msg.sender] + 1) % uint8(palette.length);
        emit ColorCycled(msg.sender, myColorIndex[msg.sender]);
    }

    /// @notice Claim the next available pixel for yourself (no args). Useful to reserve it before painting.
    /// A claim prevents other users from painting that pixel (but not the claimer).
    function claimPixel() external isInitialized notFinalized {
        require(nextIndex < totalCells, "canvas is full");

        uint idx = nextIndex;
        // skip already claimed pixels by others
        while (idx < totalCells && pixelClaimed[idx] && pixelOwner[idx] != msg.sender) {
            idx++;
        }
        require(idx < totalCells, "no pixel available to claim");

        pixelClaimed[idx] = true;
        emit PixelClaimed(msg.sender, idx);
    }

    // -----------------------
    // Views (no-arg)
    // -----------------------

    /// @notice Return the full canvas as two parallel arrays: owners[] and colorIndices[].
    /// owners[i] is address of painter or address(0) if empty. colorIndices[i] is palette index.
    /// The arrays are returned in flattened scanline order: index = y * width + x.
    function getCanvas() external view isInitialized returns (address[] memory owners, uint8[] memory colorIndices, uint w, uint h, string[] memory paletteOut) {
        owners = new address[](totalCells);
        colorIndices = new uint8[](totalCells);
        for (uint i = 0; i < totalCells; i++) {
            owners[i] = pixelOwner[i];
            colorIndices[i] = pixelColorIndex[i];
        }
        // copy palette strings for client display
        paletteOut = new string[](palette.length);
        for (uint p = 0; p < palette.length; p++) {
            paletteOut[p] = palette[p];
        }
        return (owners, colorIndices, width, height, paletteOut);
    }

    /// @notice Return the pixel indices and colors owned by the caller (no args).
    function getMyPixels() external view isInitialized returns (uint[] memory indices, uint8[] memory colors) {
        uint[] storage owned = myPixels[msg.sender];
        indices = new uint[](owned.length);
        colors = new uint8[](owned.length);
        for (uint i = 0; i < owned.length; i++) {
            indices[i] = owned[i];
            colors[i] = pixelColorIndex[owned[i]];
        }
        return (indices, colors);
    }

    /// @notice Return the caller's currently selected palette index and its name (no args).
    function mySelectedColor() external view isInitialized returns (uint8 idx, string memory name) {
        idx = myColorIndex[msg.sender];
        name = palette[idx];
        return (idx, name);
    }

    /// @notice Return metadata about the canvas (no args).
    function canvasInfo() external view isInitialized returns (uint w, uint h, uint filled, uint paletteSize, uint next) {
        uint filledCount = 0;
        for (uint i = 0; i < totalCells; i++) {
            if (pixelOwner[i] != address(0)) {
                filledCount++;
            }
        }
        return (width, height, filledCount, palette.length, nextIndex);
    }

    // -----------------------
    // Admin utilities (no-arg)
    // -----------------------

    /// @notice Admin can clear the canvas (no args). Resets ownership and colors, but keeps palette.
    function adminClearCanvas() external onlyAdmin isInitialized notFinalized {
        for (uint i = 0; i < totalCells; i++) {
            pixelOwner[i] = address(0);
            pixelColorIndex[i] = 0;
            pixelClaimed[i] = false;
        }
        // clear per-user lists (best-effort; expensive for many users — acceptable for prototype)
        // NOTE: Solidity cannot iterate mapping keys; we keep myPixels and it persists per address.
        nextIndex = 0;
        emit CanvasCleared(msg.sender);
    }

    /// @notice Admin finalizes the canvas (no args). After finalization, no more edits.
    function adminFinalize() external onlyAdmin isInitialized {
        finalized = true;
        emit Finalized(msg.sender);
    }

    /// @notice Admin can add a default palette color (no args). Auto-generates a name.
    function adminAddPaletteColor() external onlyAdmin isInitialized notFinalized {
        string memory name = string(abi.encodePacked("color#", _uint2str(palette.length)));
        palette.push(name);
    }

    // -----------------------
    // Utilities
    // -----------------------
    function _uint2str(uint v) internal pure returns (string memory str) {
        if (v == 0) { return "0"; }
        uint maxlength = 100;
        bytes memory reversed = new bytes(maxlength);
        uint i = 0;
        while (v != 0) {
            uint remainder = v % 10;
            v = v / 10;
            reversed[i++] = bytes1(uint8(48 + remainder));
        }
        bytes memory s = new bytes(i);
        for (uint j = 0; j < i; j++) {
            s[j] = reversed[i - 1 - j];
        }
        str = string(s);
    }

    // Accept tips / ETH (optional)
    receive() external payable {}
    fallback() external payable {}
}
