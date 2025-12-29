///|
/// RLP 编码实现
// 根据 Ethereum RLP 规范实现编码功能

// 主编码函数
pub fn encode(item : RLPItem) -> FixedArray[Byte] {
  match item {
    Bytes(b) => encode_bytes(b)
    List(items) => encode_list(items)
  }
}

///|
/// 编码字节串
// 规则：
// - 单字节且值在 [0x00, 0x7f] 范围内：直接返回该字节
// - 长度 0-55 字节：前缀 0x80 + len，然后是数据
// - 长度 > 55 字节：前缀 0xb7 + len(len_bytes)，然后是 len_bytes，然后是数据
fn encode_bytes(b : FixedArray[Byte]) -> FixedArray[Byte] {
  let len = b.length()

  // 单字节且值 <= 0x7f
  if len == 1 && b[0].to_int() <= 0x7F {
    return b
  }

  // 短字符串 (0-55 bytes)
  if len <= 55 {
    let result = FixedArray::make(1 + len, b'\x00')
    result[0] = (0x80 + len).to_byte()
    for i = 0; i < len; i = i + 1 {
      result[1 + i] = b[i]
    }
    return result
  }

  // 长字符串 (> 55 bytes)
  let len_bytes = int_to_big_endian_minimal(len)
  let len_of_len = len_bytes.length()
  let result = FixedArray::make(1 + len_of_len + len, b'\x00')
  result[0] = (0xB7 + len_of_len).to_byte()
  for i = 0; i < len_of_len; i = i + 1 {
    result[1 + i] = len_bytes[i]
  }
  for i = 0; i < len; i = i + 1 {
    result[1 + len_of_len + i] = b[i]
  }
  result
}

///|
/// 编码列表
// 规则：
// - 先递归编码所有子项，拼接成 payload
// - payload 长度 0-55：前缀 0xc0 + len，然后是 payload
// - payload 长度 > 55：前缀 0xf7 + len(len_bytes)，然后是 len_bytes，然后是 payload
fn encode_list(items : Array[RLPItem]) -> FixedArray[Byte] {
  // 递归编码所有子项
  let encoded_items : Array[FixedArray[Byte]] = []
  for item in items {
    encoded_items.push(encode(item))
  }
  let payload = concat_bytes_array(encoded_items)
  let payload_len = payload.length()

  // 短列表 (payload 0-55 bytes)
  if payload_len <= 55 {
    let result = FixedArray::make(1 + payload_len, b'\x00')
    result[0] = (0xC0 + payload_len).to_byte()
    for i = 0; i < payload_len; i = i + 1 {
      result[1 + i] = payload[i]
    }
    return result
  }

  // 长列表 (payload > 55 bytes)
  let len_bytes = int_to_big_endian_minimal(payload_len)
  let len_of_len = len_bytes.length()
  let result = FixedArray::make(1 + len_of_len + payload_len, b'\x00')
  result[0] = (0xF7 + len_of_len).to_byte()
  for i = 0; i < len_of_len; i = i + 1 {
    result[1 + i] = len_bytes[i]
  }
  for i = 0; i < payload_len; i = i + 1 {
    result[1 + len_of_len + i] = payload[i]
  }
  result
}

///|
/// 便捷编码函数

// 编码整数（作为最小大端字节数组）
pub fn encode_int(value : Int) -> FixedArray[Byte] {
  if value == 0 {
    // 0 编码为 0x80 (空字节串)
    let result = FixedArray::make(1, b'\x00')
    result[0] = b'\x80'
    return result
  }
  encode_bytes(int_to_big_endian_minimal(value))
}

// 编码字节数组列表

///|
pub fn encode_bytes_list(
  bytes_list : Array[FixedArray[Byte]],
) -> FixedArray[Byte] {
  let items : Array[RLPItem] = []
  for b in bytes_list {
    items.push(Bytes(b))
  }
  encode_list(items)
}
