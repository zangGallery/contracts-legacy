// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// [MIT License]
library StringUtils {
    function extendBytes(bytes memory _bytes) private pure returns (bytes memory) {
        bytes memory copy = new bytes(_bytes.length);
        uint256 max = _bytes.length + 31;
        for (uint256 i=32; i<=max; i+=32)
        {
            assembly { mstore(add(copy, i), mload(add(_bytes, i))) }
        }
        return copy;
    }

    function copyBytes(bytes memory _bytes) private pure returns (bytes memory) {
        bytes memory copy = new bytes(_bytes.length);
        for (uint256 i = 0; i < _bytes.length; i++) {
            copy[i] = _bytes[i];
        }

        return copy;
    }

    function shiftRight(bytes memory _bytes, uint256 index) private pure returns (bytes memory) {
        bytes memory copy = new bytes(_bytes.length + 1);
        for (uint256 i = 0; i < index; i++) {
            copy[i] = _bytes[i];
        }
        for (uint256 i = index; index < _bytes.length; i++) {
            copy[i + 1] = _bytes[i];
        }

        return copy;
    }

    function utfLength(bytes1 b) private pure returns (uint8) {
        if (b < 0x80) {
            return 1;
        } else if(b < 0xE0) {
            return 2;
        } else if(b < 0xF0) {
            return 3;
        } else if(b < 0xF8) {
            return 4;
        } else if(b < 0xFC) {
            return 5;
        } else {
            return 6;
        }
    }

    function insertAsciiBefore(bytes memory str, bytes1 target, bytes1 insert) internal pure returns (bytes memory) {
        require(utfLength(target) == 1, "StringUtils: target must be ASCII");
        require(utfLength(insert) == 1, "StringUtils: insert must be ASCII");

        bytes memory copy = copyBytes(str);
        uint256 i = 0;
        while (i < copy.length) {
            bytes1 b = copy[i];
            uint8 bLength = utfLength(b);

            if (bLength == 1 && b == target) {
                // ASCII character that matches our target
                copy = shiftRight(copy, i);
                copy[i] = insert;
            }

            i += bLength;

        }

        return copy;
    }
}