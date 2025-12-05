# RLP (Recursive Length Prefix) 实现

这是一个用 MoonBit 实现的以太坊 RLP 编码/解码库。

## 功能特性

- ✅ 完整的 RLP 编码支持
- ✅ 完整的 RLP 解码支持
- ✅ 规范性检查（防止非标准编码）
- ✅ 支持字节串和列表
- ✅ 支持整数编码/解码
- ✅ 符合以太坊 Yellow Paper 规范

## 使用示例

```moonbit
// 编码字节串
let data = FixedArray::make(3, b'\x00')
data[0] = b'd'
data[1] = b'o'
data[2] = b'g'
let encoded = encode(Bytes(data))

// 编码列表
let item1 = Bytes(data1)
let item2 = Bytes(data2)
let encoded_list = encode(List([item1, item2]))

// 解码
match decode(encoded) {
  Ok(item) => println("解码成功")
  Err(e) => println("解码失败")
}

// 编码整数
let encoded_int = encode_int(1024)

// 解码整数
match decode_int(encoded_int) {
  Ok(value) => println("整数值: \(value)")
  Err(e) => println("解码失败")
}
```

## API 文档

### 类型定义

- `RLPItem`: RLP 项，可以是字节串或列表
  - `Bytes(FixedArray[Byte])`: 字节串
  - `List(Array[RLPItem])`: 列表

- `RLPError`: RLP 错误类型
  - `InvalidInput(String)`: 无效输入
  - `UnexpectedEnd`: 数据意外结束
  - `NonCanonicalEncoding`: 非规范编码

### 主要函数

- `encode(item: RLPItem) -> FixedArray[Byte]`: 编码 RLP 项
- `decode(data: FixedArray[Byte]) -> RLPResult[RLPItem]`: 解码 RLP 数据
- `encode_int(value: Int) -> FixedArray[Byte]`: 编码整数
- `decode_int(data: FixedArray[Byte]) -> RLPResult[Int]`: 解码整数
- `encode_bytes_list(bytes_list: Array[FixedArray[Byte]]) -> FixedArray[Byte]`: 编码字节数组列表
- `decode_bytes_list(data: FixedArray[Byte]) -> RLPResult[Array[FixedArray[Byte]]]`: 解码字节数组列表

## 规范参考

- [以太坊 RLP 官方文档](https://ethereum.org/developers/docs/data-structures-and-encoding/rlp/)
- [以太坊黄皮书附录 B](https://ethereum.github.io/yellowpaper/paper.pdf)
- [ACL2 形式化验证](https://www.kestrel.edu/research/ethereum/acl2-2020.pdf)

## 注意事项

1. 整数必须使用最小的大端字节表示（无前导零）
2. 解码时会严格检查规范性，拒绝非标准编码
3. 单字节值 <= 0x7f 必须直接编码，不能使用短字符串编码

