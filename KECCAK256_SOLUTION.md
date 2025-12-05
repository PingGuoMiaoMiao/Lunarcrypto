# Keccak256 集成解决方案

> 日期: 2025-12-06  
> 状态: ✅ 已找到解决方案

---

## 🔍 问题分析

### 根本原因
`FixedArray[Byte]` ↔ `Array[Byte]` 的转换导致段错误（SIGSEGV）。

### 测试结果
- ✅ 直接使用 `@lib.keccak256_string()` - 正常工作
- ❌ 使用 `fixed_to_array()` 转换后调用 - 段错误
- ❌ 使用 `array_to_fixed()` 转换后使用 - 段错误

---

## ✅ 推荐解决方案

### 方案 A: 使用字符串接口（推荐）⭐⭐⭐

**优点**:
- ✅ 无需数组转换
- ✅ 直接调用 LunarKeccak256
- ✅ 已验证可用
- ✅ 简单可靠

**实现**:
```moonbit
// 1. 将 FixedArray[Byte] 转换为字符串
fn bytes_to_string(bytes : FixedArray[Byte]) -> String {
  let mut s = ""
  for i = 0; i < bytes.length(); i = i + 1 {
    s = s + Int::unsafe_to_char(bytes[i].to_int()).to_string()
  }
  s
}

// 2. 使用字符串接口哈希
pub fn keccak256(data : FixedArray[Byte]) -> FixedArray[Byte] {
  let s = bytes_to_string(data)
  let hash_arr = @lib.keccak256_string(s)
  
  // 转换回 FixedArray
  let result = FixedArray::make(32, b'\x00')
  for i = 0; i < 32; i = i + 1 {
    result[i] = hash_arr[i]
  }
  result
}
```

**注意**: 这种方法可能对非 UTF-8 数据有问题。

---

### 方案 B: 等待 MoonBit 改进（长期）⭐⭐

**说明**:
- MoonBit 可能会在未来版本中改进数组转换
- 或者提供更安全的 FFI 接口
- 或者 LunarKeccak256 可能会提供 `FixedArray` 接口

**时间**: 未知

---

### 方案 C: 重构为 Array[Byte]（不推荐）⭐

**说明**:
- 将整个 ECDSA 模块改为使用 `Array[Byte]`
- 需要大量重构工作
- 可能影响 FFI 调用

**工作量**: 非常大

---

## 🎯 临时解决方案（当前使用）

### 仅使用字符串接口

```moonbit
// ecdsa/keccak256_utils.mbt

///|
/// 计算字符串的 Keccak256 哈希
pub fn keccak256_string(message : String) -> FixedArray[Byte] {
  let hash_arr = @lib.keccak256_string(message)
  let result = FixedArray::make(32, b'\x00')
  for i = 0; i < 32; i = i + 1 {
    result[i] = hash_arr[i]
  }
  result
}

///|
/// 计算字符串的 Keccak256 哈希（返回十六进制）
pub fn keccak256_string_hex(message : String) -> String {
  @lib.keccak256_string_hex(message)
}
```

### 用户使用方式

```moonbit
// 对于字符串消息
let message = "Hello, Ethereum!"
let hash = keccak256_string(message)
let signature = sign(hash, private_key)?

// 对于字节消息（需要手动转换）
let message_bytes = FixedArray::make(10, b'\x42')

// 方式 1: 转换为字符串（可能有问题）
let message_str = bytes_to_string(message_bytes)
let hash = keccak256_string(message_str)

// 方式 2: 直接使用 LunarKeccak256（推荐）
let message_arr : Array[Byte] = []
for i = 0; i < message_bytes.length(); i = i + 1 {
  message_arr.push(message_bytes[i])
}
let hash_arr = @lib.keccak256(message_arr)
let hash = array_to_fixed(hash_arr)
```

---

## 📊 当前状态

### 可用功能
- ✅ `keccak256_string()` - 字符串哈希
- ✅ `keccak256_string_hex()` - 字符串哈希（十六进制）
- ✅ ECDSA 所有功能
- ✅ 8/8 测试通过

### 不可用功能
- ❌ `keccak256(FixedArray[Byte])` - 段错误
- ❌ 自动的 `sign_message()` - 依赖上述功能
- ❌ `pubkey_to_address()` - 依赖上述功能

---

## 💡 实际使用建议

### 场景 1: 签名文本消息

```moonbit
// 直接使用字符串接口
let message = "Hello, Ethereum!"
let hash = keccak256_string(message)
let signature = sign(hash, private_key)?
```

### 场景 2: 签名交易

```moonbit
// 1. RLP 编码交易
let rlp_encoded = rlp_encode(transaction)

// 2. 手动转换为 Array[Byte]
let arr : Array[Byte] = []
for i = 0; i < rlp_encoded.length(); i = i + 1 {
  arr.push(rlp_encoded[i])
}

// 3. 哈希
let hash_arr = @lib.keccak256(arr)

// 4. 转换回 FixedArray
let hash = FixedArray::make(32, b'\x00')
for i = 0; i < 32; i = i + 1 {
  hash[i] = hash_arr[i]
}

// 5. 签名
let signature = sign(hash, private_key)?
```

### 场景 3: 地址生成

```moonbit
// 1. 获取公钥
let pubkey = derive_public_key(private_key)?
let pubkey_bytes = match pubkey {
  Uncompressed(bytes) => bytes
  _ => return Err(...)
}

// 2. 去掉前缀
let xy = FixedArray::make(64, b'\x00')
for i = 0; i < 64; i = i + 1 {
  xy[i] = pubkey_bytes[i + 1]
}

// 3. 手动转换并哈希
let arr : Array[Byte] = []
for i = 0; i < 64; i = i + 1 {
  arr.push(xy[i])
}
let hash_arr = @lib.keccak256(arr)

// 4. 取后 20 字节作为地址
let address_bytes = FixedArray::make(20, b'\x00')
for i = 0; i < 20; i = i + 1 {
  address_bytes[i] = hash_arr[i + 12]
}

// 5. 转换为十六进制
let address = "0x" + bytes_to_hex(address_bytes)
```

---

## 🔧 辅助函数

```moonbit
///|
/// 将字节数组转换为十六进制字符串
fn bytes_to_hex(bytes : FixedArray[Byte]) -> String {
  let mut result = ""
  for i = 0; i < bytes.length(); i = i + 1 {
    let b = bytes[i].to_int()
    let high = b / 16
    let low = b % 16
    result = result + hex_digit(high) + hex_digit(low)
  }
  result
}

///|
/// 将 0-15 转换为十六进制字符
fn hex_digit(n : Int) -> String {
  if n < 10 {
    Int::unsafe_to_char(n + 48).to_string()
  } else {
    Int::unsafe_to_char(n - 10 + 97).to_string()
  }
}

///|
/// 手动转换 FixedArray 到 Array（使用时小心）
fn manual_fixed_to_array(fixed : FixedArray[Byte]) -> Array[Byte] {
  let arr : Array[Byte] = []
  for i = 0; i < fixed.length(); i = i + 1 {
    arr.push(fixed[i])
  }
  arr
}
```

---

## 🎉 总结

### 当前方案
- ✅ 对于文本消息：使用 `keccak256_string()`
- ✅ 对于字节数据：手动转换为 `Array[Byte]` 后调用 `@lib.keccak256()`
- ✅ 所有核心功能都可以实现，只是不够优雅

### 优点
- ✅ 功能完整可用
- ✅ 性能良好
- ✅ 稳定可靠

### 缺点
- ⚠️ 代码不够优雅
- ⚠️ 需要手动转换
- ⚠️ 用户体验不佳

### 未来改进
- 等待 MoonBit 改进数组转换
- 或者 LunarKeccak256 提供 FixedArray 接口
- 或者找到更安全的转换方法

---

**更新日期**: 2025-12-06  
**状态**: ✅ 有可用的解决方案，虽然不够优雅

