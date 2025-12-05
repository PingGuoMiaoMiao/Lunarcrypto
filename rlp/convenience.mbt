///|
/// RLP 便利函数
/// 提供常用类型的快速编码/解码

///|
/// 编码 UInt64
/// 将无符号 64 位整数编码为 RLP 格式
/// 使用最小的大端字节表示
pub fn encode_u64(value : UInt64) -> FixedArray[Byte] {
  if value == 0UL {
    // 0 编码为空字符串 = 0x80
    let result = FixedArray::make(1, b'\x00')
    result[0] = b'\x80'
    return result
  }

  // 计算需要的字节数
  let mut v = value
  let mut byte_count = 0
  while v > 0UL {
    byte_count = byte_count + 1
    v = v >> 8
  }

  // 创建最小字节表示
  let bytes = FixedArray::make(byte_count, b'\x00')
  v = value
  for i = byte_count - 1; i >= 0; i = i - 1 {
    bytes[i] = v.land(0xFFUL).to_byte()
    v = v >> 8
  }

  // 使用 encode_bytes 编码
  encode_bytes(bytes)
}

///|
/// 编码 UInt
/// 将无符号整数编码为 RLP 格式
pub fn encode_uint(value : UInt) -> FixedArray[Byte] {
  if value == 0U {
    let result = FixedArray::make(1, b'\x00')
    result[0] = b'\x80'
    return result
  }
  let mut v = value
  let mut byte_count = 0
  while v > 0U {
    byte_count = byte_count + 1
    v = v >> 8
  }
  let bytes = FixedArray::make(byte_count, b'\x00')
  v = value
  for i = byte_count - 1; i >= 0; i = i - 1 {
    bytes[i] = v.land(0xFFU).to_byte()
    v = v >> 8
  }
  encode_bytes(bytes)
}

///|
/// 编码字节数组
/// 将单个字节数组编码为 RLP Bytes 项
pub fn encode_bytes_item(bytes : FixedArray[Byte]) -> FixedArray[Byte] {
  encode(RLPItem::Bytes(bytes))
}

///|
/// 编码多个字节数组为列表
/// 便利函数：将多个字节数组编码为 RLP 列表
/// 等价于 encode(List([Bytes(arr[0]), Bytes(arr[1]), ...]))
pub fn encode_bytes_array(arr : Array[FixedArray[Byte]]) -> FixedArray[Byte] {
  let items : Array[RLPItem] = []
  for bytes in arr {
    items.push(RLPItem::Bytes(bytes))
  }
  encode(RLPItem::List(items))
}

///|
/// 从字节数组创建 RLPItem::Bytes
pub fn rlp_bytes(bytes : FixedArray[Byte]) -> RLPItem {
  RLPItem::Bytes(bytes)
}

///|
/// 从字符串创建 RLPItem::Bytes
/// 将 UTF-8 字符串转换为字节数组并创建 RLP 字节项
pub fn rlp_string(s : String) -> RLPItem {
  // 简化实现：手动转换字符串为字节（仅支持 ASCII）
  let bytes : Array[Byte] = []
  let len = s.length()
  for i = 0; i < len; i = i + 1 {
    let code = s.code_unit_at(i).to_int()
    // 简单的 ASCII 转换
    if code < 128 {
      bytes.push(code.to_byte())
    }
  }
  let arr = FixedArray::make(bytes.length(), b'\x00')
  for i = 0; i < bytes.length(); i = i + 1 {
    arr[i] = bytes[i]
  }
  RLPItem::Bytes(arr)
}

///|
/// 创建 RLP 列表
pub fn rlp_list(items : Array[RLPItem]) -> RLPItem {
  RLPItem::List(items)
}

///|
/// 从整数创建 RLPItem
pub fn rlp_int(value : Int) -> RLPItem {
  if value == 0 {
    return RLPItem::Bytes(FixedArray::make(0, b'\x00'))
  }
  RLPItem::Bytes(int_to_big_endian_minimal(value))
}

///|
/// 从 UInt64 创建 RLPItem
pub fn rlp_u64(value : UInt64) -> RLPItem {
  if value == 0UL {
    return RLPItem::Bytes(FixedArray::make(0, b'\x00'))
  }
  let mut v = value
  let mut byte_count = 0
  while v > 0UL {
    byte_count = byte_count + 1
    v = v >> 8
  }
  let bytes = FixedArray::make(byte_count, b'\x00')
  v = value
  for i = byte_count - 1; i >= 0; i = i - 1 {
    bytes[i] = v.land(0xFFUL).to_byte()
    v = v >> 8
  }
  RLPItem::Bytes(bytes)
}

///|
/// 解码为 UInt64
/// 从 RLP 编码的数据中解码出 UInt64
pub fn decode_u64(data : FixedArray[Byte]) -> RLPResult[UInt64] {
  match decode(data) {
    Ok(item) =>
      match item {
        RLPItem::Bytes(b) => {
          if b.length() == 0 {
            return Ok(0UL)
          }
          if !is_canonical_big_endian(b) {
            return Err(NonCanonicalEncoding)
          }
          let mut result = 0UL
          for i = 0; i < b.length(); i = i + 1 {
            result = (result << 8) | b[i].to_uint64()
          }
          Ok(result)
        }
        RLPItem::List(_) =>
          Err(InvalidInput("Expected bytes for u64, got list"))
      }
    Err(e) => Err(e)
  }
}

///|
/// 解码为 UInt
pub fn decode_uint(data : FixedArray[Byte]) -> RLPResult[UInt] {
  match decode(data) {
    Ok(item) =>
      match item {
        RLPItem::Bytes(b) => {
          if b.length() == 0 {
            return Ok(0U)
          }
          if !is_canonical_big_endian(b) {
            return Err(NonCanonicalEncoding)
          }
          let mut result = 0U
          for i = 0; i < b.length(); i = i + 1 {
            result = (result << 8) | b[i].to_uint()
          }
          Ok(result)
        }
        RLPItem::List(_) =>
          Err(InvalidInput("Expected bytes for uint, got list"))
      }
    Err(e) => Err(e)
  }
}

///|
/// 从 RLPItem 中提取字节数组
pub fn get_bytes(item : RLPItem) -> RLPResult[FixedArray[Byte]] {
  match item {
    RLPItem::Bytes(b) => Ok(b)
    RLPItem::List(_) => Err(InvalidInput("Expected bytes, got list"))
  }
}

///|
/// 从 RLPItem 中提取列表
pub fn get_list(item : RLPItem) -> RLPResult[Array[RLPItem]] {
  match item {
    RLPItem::Bytes(_) => Err(InvalidInput("Expected list, got bytes"))
    RLPItem::List(items) => Ok(items)
  }
}

///|
/// 从 RLPItem 中提取整数
pub fn get_int(item : RLPItem) -> RLPResult[Int] {
  match item {
    RLPItem::Bytes(b) => {
      if b.length() == 0 {
        return Ok(0)
      }
      if !is_canonical_big_endian(b) {
        return Err(NonCanonicalEncoding)
      }
      Ok(big_endian_to_int(b))
    }
    RLPItem::List(_) => Err(InvalidInput("Expected bytes for int, got list"))
  }
}

///|
/// 从 RLPItem 中提取 UInt64
pub fn get_u64(item : RLPItem) -> RLPResult[UInt64] {
  match item {
    RLPItem::Bytes(b) => {
      if b.length() == 0 {
        return Ok(0UL)
      }
      if !is_canonical_big_endian(b) {
        return Err(NonCanonicalEncoding)
      }
      let mut result = 0UL
      for i = 0; i < b.length(); i = i + 1 {
        result = (result << 8) | b[i].to_uint64()
      }
      Ok(result)
    }
    RLPItem::List(_) => Err(InvalidInput("Expected bytes for u64, got list"))
  }
}
