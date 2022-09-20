//===----------------------------------------------------------------------===//
//
// This source file is part of the Swift Collections open source project
//
// Copyright (c) 2022 Apple Inc. and the Swift project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See https://swift.org/LICENSE.txt for license information
//
//===----------------------------------------------------------------------===//

/// The storage header in a hash tree node. This includes data about the
/// current size and capacity of the node's storage region, as well as
/// information about the currently occupied hash table buckets.
@usableFromInline
@frozen
internal struct _StorageHeader {
  @usableFromInline
  internal var itemMap: _Bitmap

  @usableFromInline
  internal var childMap: _Bitmap

  @usableFromInline
  internal var _byteCapacity: UInt32

  @usableFromInline
  internal var _bytesFree: UInt32

  @inlinable
  internal init(byteCapacity: Int) {
    assert(byteCapacity >= 0 && byteCapacity <= UInt32.max)
    self.itemMap = .empty
    self.childMap = .empty
    self._byteCapacity = UInt32(truncatingIfNeeded: byteCapacity)
    self._bytesFree = self._byteCapacity
  }
}

extension _StorageHeader {
  @inlinable @inline(__always)
  internal var byteCapacity: Int {
    get { Int(truncatingIfNeeded: _byteCapacity) }
  }

  @inlinable
  internal var bytesFree: Int {
    @inline(__always)
    get { Int(truncatingIfNeeded: _bytesFree) }
    set {
      assert(newValue >= 0 && newValue <= UInt32.max)
      _bytesFree = UInt32(truncatingIfNeeded: newValue)
    }
  }
}

extension _StorageHeader {
  @inlinable @inline(__always)
  internal var isEmpty: Bool {
    return itemMap.isEmpty && childMap.isEmpty
  }

  @inlinable @inline(__always)
  internal var isCollisionNode: Bool {
    !itemMap.intersection(childMap).isEmpty
  }

  @inlinable @inline(__always)
  internal var hasChildren: Bool {
    itemMap != childMap && !childMap.isEmpty
  }

  @inlinable @inline(__always)
  internal var hasItems: Bool {
    !itemMap.isEmpty
  }

  @inlinable
  internal var childCount: Int {
    itemMap == childMap ? 0 : childMap.count
  }

  @inlinable
  internal var itemCount: Int {
    (itemMap == childMap
     ? Int(truncatingIfNeeded: itemMap._value)
     : itemMap.count)
  }

  @inlinable @inline(__always)
  internal var childEnd: _Slot {
    _Slot(childCount)
  }

  @inlinable @inline(__always)
  internal var itemEnd: _Slot {
    _Slot(itemCount)
  }

  @inlinable
  internal var collisionCount: Int {
    get {
      assert(isCollisionNode)
      return Int(truncatingIfNeeded: itemMap._value)
    }
    set {
      assert(isCollisionNode || childMap.isEmpty)
      assert(newValue > 0 && newValue < UInt32.max)
      itemMap._value = UInt32(truncatingIfNeeded: newValue)
      childMap = itemMap
    }
  }
}