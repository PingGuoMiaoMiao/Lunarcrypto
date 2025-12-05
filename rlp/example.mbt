///|
/// RLP 使用示例

// 示例 1: 编码单个字节串
pub fn example_encode_bytes() -> FixedArray[Byte] {
  let data = FixedArray::make(3, b'\x00')
  data[0] = b'd'
  data[1] = b'o'
  data[2] = b'g'
  encode(RLPItem::Bytes(data))
}

// 示例 2: 编码列表

///|
pub fn example_encode_list() -> FixedArray[Byte] {
  let cat = FixedArray::make(3, b'\x00')
  cat[0] = b'c'
  cat[1] = b'a'
  cat[2] = b't'
  let dog = FixedArray::make(3, b'\x00')
  dog[0] = b'd'
  dog[1] = b'o'
  dog[2] = b'g'
  encode(RLPItem::List([RLPItem::Bytes(cat), RLPItem::Bytes(dog)]))
}

// 示例 3: 编码整数

///|
pub fn example_encode_integer() -> FixedArray[Byte] {
  encode_int(1024)
}

// 示例 4: 解码数据

///|
pub fn example_decode() -> String {
  let data = FixedArray::make(4, b'\x00')
  data[0] = b'\x83'
  data[1] = b'd'
  data[2] = b'o'
  data[3] = b'g'
  match decode(data) {
    Ok(RLPItem::Bytes(b)) => "解码成功: 字节长度 = \{b.length()}"
    Ok(RLPItem::List(_)) => "解码成功: 列表"
    Err(InvalidInput(msg)) => "解码失败: \{msg}"
    Err(UnexpectedEnd) => "解码失败: 数据意外结束"
    Err(NonCanonicalEncoding) => "解码失败: 非规范编码"
    Err(InvalidLength) => "解码失败: 无效长度"
  }
}

// 示例 5: 编码-解码往返

///|
pub fn example_round_trip() -> Bool {
  let original = FixedArray::make(5, b'\x00')
  for i = 0; i < 5; i = i + 1 {
    original[i] = (i + 65).to_byte()
  }
  let encoded = encode(RLPItem::Bytes(original))
  match decode(encoded) {
    Ok(RLPItem::Bytes(decoded)) => {
      if decoded.length() != original.length() {
        return false
      }
      for i = 0; i < original.length(); i = i + 1 {
        if decoded[i] != original[i] {
          return false
        }
      }
      true
    }
    _ => false
  }
}

// 示例 6: 嵌套列表

///|
pub fn example_nested_list() -> FixedArray[Byte] {
  let empty_list = RLPItem::List([])
  let nested = RLPItem::List([RLPItem::List([])])
  encode(RLPItem::List([empty_list, nested]))
}
