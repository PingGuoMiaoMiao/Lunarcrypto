///|
/// RLP 解码实现
// 根据 Ethereum RLP 规范实现解码功能

// 解码结果类型：包含解码的项和剩余字节
pub struct DecodeResult {
  item : RLPItem
  remaining : FixedArray[Byte]
} derive(Show)

///|
/// 主解码函数
pub fn decode(data : FixedArray[Byte]) -> RLPResult[RLPItem] {
  match decode_with_remaining(data) {
    Ok(result) =>
      // 确保所有字节都被消费
      if result.remaining.length() > 0 {
        Err(InvalidInput("Trailing bytes after RLP data"))
      } else {
        Ok(result.item)
      }
    Err(e) => Err(e)
  }
}

///|
/// 解码并返回剩余字节
pub fn decode_with_remaining(
  data : FixedArray[Byte],
) -> RLPResult[DecodeResult] {
  if data.length() == 0 {
    return Err(UnexpectedEnd)
  }
  let prefix = data[0].to_int()

  // 单字节 [0x00, 0x7f]
  if prefix <= 0x7F {
    let result_bytes = FixedArray::make(1, b'\x00')
    result_bytes[0] = data[0]
    return Ok({
      item: Bytes(result_bytes),
      remaining: slice_bytes(data, 1, data.length()),
    })
  }

  // 短字符串 [0x80, 0xb7]
  if prefix <= 0xB7 {
    let str_len = prefix - 0x80
    if str_len == 0 {
      // 空字符串
      return Ok({
        item: Bytes(FixedArray::make(0, b'\x00')),
        remaining: slice_bytes(data, 1, data.length()),
      })
    }
    if data.length() < 1 + str_len {
      return Err(UnexpectedEnd)
    }
    let str_data = slice_bytes(data, 1, 1 + str_len)

    // 检查规范性：单字节应该直接编码
    if str_len == 1 && str_data[0].to_int() <= 0x7F {
      return Err(NonCanonicalEncoding)
    }
    return Ok({
      item: Bytes(str_data),
      remaining: slice_bytes(data, 1 + str_len, data.length()),
    })
  }

  // 长字符串 [0xb8, 0xbf]
  if prefix <= 0xBF {
    let len_of_len = prefix - 0xB7
    if data.length() < 1 + len_of_len {
      return Err(UnexpectedEnd)
    }
    let len_bytes = slice_bytes(data, 1, 1 + len_of_len)

    // 检查长度字节的规范性（无前导零）
    if !is_canonical_big_endian(len_bytes) {
      return Err(NonCanonicalEncoding)
    }
    let str_len = big_endian_to_int(len_bytes)

    // 长字符串的长度必须 > 55
    if str_len <= 55 {
      return Err(NonCanonicalEncoding)
    }
    if data.length() < 1 + len_of_len + str_len {
      return Err(UnexpectedEnd)
    }
    let str_data = slice_bytes(data, 1 + len_of_len, 1 + len_of_len + str_len)
    return Ok({
      item: Bytes(str_data),
      remaining: slice_bytes(data, 1 + len_of_len + str_len, data.length()),
    })
  }

  // 短列表 [0xc0, 0xf7]
  if prefix <= 0xF7 {
    let payload_len = prefix - 0xC0
    if data.length() < 1 + payload_len {
      return Err(UnexpectedEnd)
    }
    let payload = slice_bytes(data, 1, 1 + payload_len)
    match decode_list_items(payload) {
      Ok(items) =>
        return Ok({
          item: List(items),
          remaining: slice_bytes(data, 1 + payload_len, data.length()),
        })
      Err(e) => return Err(e)
    }
  }

  // 长列表 [0xf8, 0xff]
  let len_of_len = prefix - 0xF7
  if data.length() < 1 + len_of_len {
    return Err(UnexpectedEnd)
  }
  let len_bytes = slice_bytes(data, 1, 1 + len_of_len)

  // 检查长度字节的规范性
  if !is_canonical_big_endian(len_bytes) {
    return Err(NonCanonicalEncoding)
  }
  let payload_len = big_endian_to_int(len_bytes)

  // 长列表的 payload 长度必须 > 55
  if payload_len <= 55 {
    return Err(NonCanonicalEncoding)
  }
  if data.length() < 1 + len_of_len + payload_len {
    return Err(UnexpectedEnd)
  }
  let payload = slice_bytes(data, 1 + len_of_len, 1 + len_of_len + payload_len)
  match decode_list_items(payload) {
    Ok(items) =>
      Ok({
        item: List(items),
        remaining: slice_bytes(
          data,
          1 + len_of_len + payload_len,
          data.length(),
        ),
      })
    Err(e) => Err(e)
  }
}

///|
/// 解码列表中的所有项
fn decode_list_items(payload : FixedArray[Byte]) -> RLPResult[Array[RLPItem]] {
  let items : Array[RLPItem] = []
  let mut remaining = payload
  while remaining.length() > 0 {
    match decode_with_remaining(remaining) {
      Ok(result) => {
        items.push(result.item)
        remaining = result.remaining
      }
      Err(e) => return Err(e)
    }
  }
  Ok(items)
}

///|
/// 便捷解码函数

// 解码为整数
pub fn decode_int(data : FixedArray[Byte]) -> RLPResult[Int] {
  match decode(data) {
    Ok(item) =>
      match item {
        Bytes(b) => {
          if b.length() == 0 {
            return Ok(0)
          }
          // 检查规范性：不能有前导零
          if !is_canonical_big_endian(b) {
            return Err(NonCanonicalEncoding)
          }
          Ok(big_endian_to_int(b))
        }
        List(_) => Err(InvalidInput("Expected bytes for integer, got list"))
      }
    Err(e) => Err(e)
  }
}

// 解码为字节数组列表

///|
pub fn decode_bytes_list(
  data : FixedArray[Byte],
) -> RLPResult[Array[FixedArray[Byte]]] {
  match decode(data) {
    Ok(item) =>
      match item {
        Bytes(_) => Err(InvalidInput("Expected list, got bytes"))
        List(items) => {
          let result : Array[FixedArray[Byte]] = []
          for i in items {
            match i {
              Bytes(b) => result.push(b)
              List(_) =>
                return Err(
                  InvalidInput("Expected bytes in list, got nested list"),
                )
            }
          }
          Ok(result)
        }
      }
    Err(e) => Err(e)
  }
}
