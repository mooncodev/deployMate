// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity ^0.8.4;

library IterableMapping {
    // Iterable mapping from address to uint;
    struct IterableMap {
        address[] keys;
        mapping(address => uint256) values;
        mapping(address => uint256) indexOf;
        mapping(address => bool) inserted;
    }
    function imap_get(IterableMap storage map, address key) public view returns (uint256) {
        return map.values[key];
    }
    function imap_getIndexOfKey(IterableMap storage map, address key) public view returns (int256){
        if (!map.inserted[key]) {return -1;}
        return int256(map.indexOf[key]);
    }
    function imap_getKeyAtIndex(IterableMap storage map, uint256 index) public view returns (address){
        return map.keys[index];
    }
    function imap_size(IterableMap storage map) public view returns (uint256) {
        return map.keys.length;
    }
    function imap_set(IterableMap storage map, address key, uint256 val) public {
        if (map.inserted[key]) {
            map.values[key] = val;
        } else {
            map.inserted[key] = true;
            map.values[key] = val;
            map.indexOf[key] = map.keys.length;
            map.keys.push(key);
        }
    }
    function imap_remove(IterableMap storage map, address key) public {
        if (!map.inserted[key]) {return;}
        delete map.inserted[key];
        delete map.values[key];
        uint256 index = map.indexOf[key];
        uint256 lastIndex = map.keys.length - 1;
        address lastKey = map.keys[lastIndex];
        map.indexOf[lastKey] = index;
        delete map.indexOf[key];
        map.keys[index] = lastKey;
        map.keys.pop();
    }
}