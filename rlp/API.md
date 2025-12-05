# RLP API 文档

## 类型定义

### RLPItem

RLP 项，表示可以被编码的数据：

```moonbit
pub enum RLPItem {
  Bytes(FixedArray[Byte])  // 字节串
  List(Array[RLPItem])     // 列表（可递归）
}
```

**辅助方法：**

- `RLPItem::from_bytes(b: FixedArray[Byte]) -> RLPItem`
- `RLPItem::from_list(items: Array[RLPItem]) -> RLPItem`
- `RLPItem::empty_bytes() -> RLPItem`
- `RLPItem::empty_list() -> RLPItem`
- `is_bytes(self: RLPItem) -> Bool`
- `is_list(self: RLPItem) -> Bool`
- `as_bytes(self: RLPItem) -> RLPResult[FixedArray[Byte]]`
- `as_list(self: RLPItem) -> RLPResult[Array[RLPItem]]`

### RLPError

RLP 错误类型：

```moonbit
pub enum RLPError {
  InvalidInput(String)      // 无效输入
  UnexpectedEnd            // 数据意外结束
  InvalidLength            // 无效长度
  NonCanonicalEncoding     // 非规范编码
}
```

### RLPResult[T]

Result 类型别名：

```moonbit
pub type RLPResult[T] = Result[T, RLPError]
```

### DecodeResult

解码结果结构体（包含剩余字节）：

```moonbit
pub struct DecodeResult {
  item: RLPItem
  remaining: FixedArray[Byte]
}
```

## 编码函数

### encode

主编码函数，将 RLPItem 编码为字节数组：

```moonbit
pub fn encode(item: RLPItem) -> FixedArray[Byte]
```

**示例：**

```moonbit
let data = FixedArray::make(3, b'\x00')
data[0] = b'd'
data[1] = b'o'
data[2] = b'g'
let encoded = encode(RLPItem::Bytes(data))
// 结果: [0x83, 'd', 'o', 'g']
```

### encode_int

编码整数（作为最小大端字节数组）：

```moonbit
pub fn encode_int(value: Int) -> FixedArray[Byte]
```

**示例：**

```moonbit
let encoded = encode_int(0)      // [0x80]
let encoded = encode_int(15)     // [0x0f]
let encoded = encode_int(1024)   // [0x82, 0x04, 0x00]
```

### encode_bytes_list

编码字节数组列表：

```moonbit
pub fn encode_bytes_list(bytes_list: Array[FixedArray[Byte]]) -> FixedArray[Byte]
```

**示例：**

```moonbit
let list = [bytes1, bytes2, bytes3]
let encoded = encode_bytes_list(list)
```

## 解码函数

### decode

主解码函数，将字节数组解码为 RLPItem：

```moonbit
pub fn decode(data: FixedArray[Byte]) -> RLPResult[RLPItem]
```

**示例：**

```moonbit
match decode(encoded_data) {
  Ok(RLPItem::Bytes(b)) => {
    println("解码得到字节串，长度: \{b.length()}")
  }
  Ok(RLPItem::List(items)) => {
    println("解码得到列表，项数: \{items.length()}")
  }
  Err(InvalidInput(msg)) => {
    println("解码失败: \{msg}")
  }
  Err(UnexpectedEnd) => {
    println("数据不完整")
  }
  Err(NonCanonicalEncoding) => {
    println("非规范编码")
  }
  Err(InvalidLength) => {
    println("无效长度")
  }
}
```

### decode_with_remaining

解码并返回剩余字节：

```moonbit
pub fn decode_with_remaining(data: FixedArray[Byte]) -> RLPResult[DecodeResult]
```

**用途：** 当数据中包含多个 RLP 项时使用。

### decode_int

解码整数：

```moonbit
pub fn decode_int(data: FixedArray[Byte]) -> RLPResult[Int]
```

**示例：**

```moonbit
match decode_int(encoded) {
  Ok(value) => println("整数值: \{value}")
  Err(e) => println("解码失败")
}
```

### decode_bytes_list

解码字节数组列表：

```moonbit
pub fn decode_bytes_list(data: FixedArray[Byte]) -> RLPResult[Array[FixedArray[Byte]]]
```

## 辅助工具函数

### int_to_big_endian_minimal

将整数转换为最小的大端字节表示（无前导零）：

```moonbit
pub fn int_to_big_endian_minimal(value: Int) -> FixedArray[Byte]
```

### big_endian_to_int

将大端字节数组转换为整数：

```moonbit
pub fn big_endian_to_int(bytes: FixedArray[Byte]) -> Int
```

### is_canonical_big_endian

检查字节数组是否为规范的大端表示：

```moonbit
pub fn is_canonical_big_endian(bytes: FixedArray[Byte]) -> Bool
```

### concat_bytes

拼接两个字节数组：

```moonbit
pub fn concat_bytes(a: FixedArray[Byte], b: FixedArray[Byte]) -> FixedArray[Byte]
```

### concat_bytes_array

拼接多个字节数组：

```moonbit
pub fn concat_bytes_array(arr: Array[FixedArray[Byte]]) -> FixedArray[Byte]
```

### slice_bytes

字节数组切片：

```moonbit
pub fn slice_bytes(bytes: FixedArray[Byte], start: Int, end: Int) -> FixedArray[Byte]
```

## 编码规则

| 数据类型 | 长度范围 | 编码格式 |
|---------|---------|---------|
| 单字节 | 值 ≤ 0x7f | 直接返回该字节 |
| 字节串 | 0-55 bytes | `0x80 + len` + 数据 |
| 字节串 | > 55 bytes | `0xb7 + len(len_bytes)` + `len_bytes` + 数据 |
| 列表 | payload 0-55 bytes | `0xc0 + payload_len` + payload |
| 列表 | payload > 55 bytes | `0xf7 + len(len_bytes)` + `len_bytes` + payload |

## 使用场景

### 1. 以太坊交易编码

```moonbit
let nonce = encode_int(0)
let gas_price = encode_int(20000000000)
let gas_limit = encode_int(21000)
// ... 其他字段

let tx = RLPItem::List([
  RLPItem::Bytes(nonce),
  RLPItem::Bytes(gas_price),
  RLPItem::Bytes(gas_limit),
  // ... 其他字段
])

let encoded_tx = encode(tx)
```

### 2. 地址生成

```moonbit
// 结合 Keccak256 生成以太坊地址
let public_key = // ... 公钥
let address_bytes = keccak256(public_key)
let address = slice_bytes(address_bytes, 12, 32)
```

### 3. 数据序列化

```moonbit
// 序列化复杂数据结构
let data = RLPItem::List([
  RLPItem::Bytes(field1),
  RLPItem::List([
    RLPItem::Bytes(nested1),
    RLPItem::Bytes(nested2)
  ]),
  RLPItem::Bytes(field3)
])

let serialized = encode(data)
```

## 注意事项

1. **整数编码**：整数必须使用最小的大端字节表示，不能有前导零
2. **规范性**：解码时会严格检查规范性，拒绝非标准编码
3. **单字节优化**：单字节值 ≤ 0x7f 必须直接编码，不能使用短字符串编码
4. **空值处理**：
   - 空字节串编码为 `0x80`
   - 空列表编码为 `0xc0`
   - 整数 0 编码为 `0x80`（空字节串）

## 性能考虑

- 使用 `FixedArray[Byte]` 而非 `Bytes` 以提高性能
- 避免不必要的内存分配
- 递归编码/解码支持任意深度的嵌套

## 错误处理

所有可能失败的操作都返回 `RLPResult[T]`，建议使用 `match` 表达式处理：

```moonbit
match decode(data) {
  Ok(item) => {
    // 处理成功情况
  }
  Err(InvalidInput(msg)) => {
    // 处理输入错误
  }
  Err(UnexpectedEnd) => {
    // 处理数据不完整
  }
  Err(NonCanonicalEncoding) => {
    // 处理非规范编码
  }
  Err(InvalidLength) => {
    // 处理长度错误
  }
}
```

