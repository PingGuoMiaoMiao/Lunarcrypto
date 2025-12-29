///|
/// RLP 完整测试套件
/// 根据 Ethereum RLP 规范实现的全面测试
/// 使用 snapshot testing 风格，主要通过 inspect 验证输出

// ===== 单字节编码测试 =====

///|
/// 测试：单字节值 <= 0x7f 直接编码
test "encode single byte <= 0x7f" {
  let data = FixedArray::make(1, b'\x00')
  data[0] = b'\x00'
  let encoded = encode(RLPItem::from_bytes(data))
  inspect(encoded, content="Single byte 0x00 encoded")
  data[0] = b'\x7f'
  let encoded2 = encode(RLPItem::from_bytes(data))
  inspect(encoded2, content="Single byte 0x7f encoded")
  data[0] = b'\x42'
  let encoded3 = encode(RLPItem::from_bytes(data))
  inspect(encoded3, content="Single byte 0x42 encoded")
}

// ===== 空字符串测试 =====

///|
/// 测试：空字符串编码为 0x80
test "encode empty string" {
  let empty = FixedArray::make(0, b'\x00')
  let encoded = encode(RLPItem::from_bytes(empty))
  inspect(encoded, content="Empty string encoded (should be [0x80])")
  inspect(encoded.length() == 1, content="Empty string encoding length is 1")
  inspect(encoded[0].to_int() == 0x80, content="Empty string encodes to 0x80")
}

///|
/// 测试：解码空字符串
test "decode empty string" {
  let data = FixedArray::make(1, b'\x00')
  data[0] = b'\x80'
  match decode(data) {
    Ok(Bytes(b)) => {
      inspect(b, content="Decoded empty bytes")
      inspect(b.length() == 0, content="Decoded empty string has length 0")
    }
    Ok(List(_)) => inspect(false, content="Should be bytes, not list")
    Err(e) => inspect(e, content="Unexpected error")
  }
}

// ===== 短字符串测试 (0-55 bytes) =====

///|
/// 测试：短字符串编码
test "encode short string" {
  // 测试 "dog" -> [0x83, 'd', 'o', 'g']
  let data = FixedArray::make(3, b'\x00')
  data[0] = b'd'
  data[1] = b'o'
  data[2] = b'g'
  let encoded = encode(RLPItem::from_bytes(data))
  inspect(encoded, content="Encoded 'dog' string")
  inspect(
    encoded.length() == 4,
    content="Encoded length is 4 (prefix + 3 chars)",
  )
  inspect(encoded[0].to_int() == 0x83, content="Prefix is 0x80 + 3 = 0x83")
}

///|
/// 测试：短字符串解码
test "decode short string" {
  let data = FixedArray::make(4, b'\x00')
  data[0] = b'\x83'
  data[1] = b'd'
  data[2] = b'o'
  data[3] = b'g'
  match decode(data) {
    Ok(Bytes(b)) => {
      inspect(b, content="Decoded short string")
      inspect(b.length() == 3, content="Decoded length is 3")
      inspect(
        b[0] == b'd' && b[1] == b'o' && b[2] == b'g',
        content="Bytes match 'dog'",
      )
    }
    _ => inspect(false, content="Should decode to bytes")
  }
}

// ===== 长字符串测试 (>55 bytes) =====

///|
/// 测试：长字符串编码
test "encode long string" {
  // 创建一个 56 字节的字符串（刚好超过55字节边界）
  let data = FixedArray::make(56, b'\x00')
  for i = 0; i < 56; i = i + 1 {
    data[i] = (i % 256).to_byte()
  }
  let encoded = encode(RLPItem::from_bytes(data))
  inspect(
    encoded.length(),
    content="Long string encoding length (should be 58)",
  )
  inspect(encoded.length() == 58, content="Long string should be 58 bytes")
  inspect(
    encoded[0].to_int() == 0xb8 + 1,
    content="Prefix should be 0xb8 + len_of_len",
  )
  inspect(encoded[1].to_int() == 56, content="Length byte should be 56")
}

// ===== 整数编码测试 =====

///|
/// 测试：整数0编码为空字符串
test "encode integer zero" {
  let encoded = encode_int(0)
  inspect(encoded, content="Encoded integer 0")
  inspect(encoded.length() == 1, content="Integer 0 should encode to 1 byte")
  inspect(
    encoded[0].to_int() == 0x80,
    content="Integer 0 should encode to 0x80",
  )
}

///|
/// 测试：小整数编码
test "encode small integer" {
  let encoded = encode_int(15)
  inspect(encoded, content="Encoded integer 15")
  // 15 = 0x0f，单字节 <= 0x7f，应该直接编码
  inspect(encoded.length() == 1, content="Small integer should be 1 byte")
  inspect(encoded[0].to_int() == 15, content="Should encode directly")
}

///|
/// 测试：整数1024编码（需要2字节）
test "encode integer 1024" {
  let encoded = encode_int(1024)
  inspect(encoded, content="Encoded integer 1024")
  // 1024 = 0x0400，需要2字节，编码为: 0x82, 0x04, 0x00
  inspect(
    encoded.length() == 4,
    content="Should be 4 bytes: prefix + length + 2 data bytes",
  )
  inspect(encoded[0].to_int() == 0x82, content="Prefix should be 0x80 + 2")
  inspect(encoded[1].to_int() == 0x04, content="First data byte should be 0x04")
  inspect(
    encoded[2].to_int() == 0x00,
    content="Second data byte should be 0x00",
  )
}

///|
/// 测试：整数解码
test "decode integer" {
  // 测试解码1024
  let data = FixedArray::make(4, b'\x00')
  data[0] = b'\x82'
  data[1] = b'\x04'
  data[2] = b'\x00'
  data[3] = b'\x00' // 这个会被忽略（只在解码时使用）
  match decode_int(data) {
    Ok(value) => {
      inspect(value, content="Decoded integer 1024")
      inspect(value == 1024, content="Should decode to 1024")
    }
    Err(e) => inspect(e, content="Unexpected error decoding 1024")
  }

  // 测试解码0
  let zero_data = FixedArray::make(1, b'\x00')
  zero_data[0] = b'\x80'
  match decode_int(zero_data) {
    Ok(value) => {
      inspect(value, content="Decoded integer 0")
      inspect(value == 0, content="Should decode to 0")
    }
    Err(e) => inspect(e, content="Unexpected error decoding 0")
  }
}

// ===== 空列表测试 =====

///|
/// 测试：空列表编码
test "encode empty list" {
  let empty_list = RLPItem::from_list([])
  let encoded = encode(empty_list)
  inspect(encoded, content="Encoded empty list")
  inspect(encoded.length() == 1, content="Empty list should be 1 byte")
  inspect(
    encoded[0].to_int() == 0xc0,
    content="Empty list should encode to 0xc0",
  )
}

///|
/// 测试：解码空列表
test "decode empty list" {
  let data = FixedArray::make(1, b'\x00')
  data[0] = b'\xc0'
  match decode(data) {
    Ok(List(items)) => {
      inspect(items, content="Decoded empty list")
      inspect(items.length() == 0, content="Decoded list should be empty")
    }
    Ok(Bytes(_)) => inspect(false, content="Should be list, not bytes")
    Err(e) => inspect(e, content="Unexpected error")
  }
}

// ===== 短列表测试 =====

///|
/// 测试：短列表编码
test "encode short list" {
  let item1 = FixedArray::make(3, b'\x00')
  item1[0] = b'c'
  item1[1] = b'a'
  item1[2] = b't'
  let item2 = FixedArray::make(3, b'\x00')
  item2[0] = b'd'
  item2[1] = b'o'
  item2[2] = b'g'
  let list = RLPItem::from_list([
    RLPItem::from_bytes(item1),
    RLPItem::from_bytes(item2),
  ])
  let encoded = encode(list)
  inspect(encoded.length(), content="Encoded list length")
  // 应该是: prefix + encoded(item1) + encoded(item2)
  // = 1 + 4 + 4 = 9 bytes
  inspect(
    encoded[0].to_int() == 0xc0 + 8,
    content="Prefix should be 0xc0 + payload_len",
  )
}

///|
/// 测试：解码短列表
test "decode short list" {
  // 编码 ["cat", "dog"]
  let item1 = FixedArray::make(3, b'\x00')
  item1[0] = b'c'
  item1[1] = b'a'
  item1[2] = b't'
  let item2 = FixedArray::make(3, b'\x00')
  item2[0] = b'd'
  item2[1] = b'o'
  item2[2] = b'g'
  let list = RLPItem::from_list([
    RLPItem::from_bytes(item1),
    RLPItem::from_bytes(item2),
  ])
  let encoded = encode(list)
  match decode(encoded) {
    Ok(List(items)) => {
      inspect(items.length(), content="Decoded list item count (should be 2)")
      inspect(items.length() == 2, content="Should decode to 2 items")
      match items[0] {
        Bytes(b) => {
          inspect(b.length() == 3, content="First item should be 3 bytes")
          inspect(b[0] == b'c', content="First byte should be 'c'")
        }
        _ => inspect(false, content="First item should be bytes")
      }
      match items[1] {
        Bytes(b) => {
          inspect(b.length() == 3, content="Second item should be 3 bytes")
          inspect(b[0] == b'd', content="First byte should be 'd'")
        }
        _ => inspect(false, content="Second item should be bytes")
      }
    }
    _ => inspect(false, content="Should decode to list")
  }
}

// ===== 嵌套列表测试 =====

///|
/// 测试：嵌套列表编码/解码
test "encode decode nested list" {
  let empty_list = RLPItem::from_list([])
  let nested = RLPItem::from_list([RLPItem::from_list([])])
  let outer = RLPItem::from_list([empty_list, nested])
  let encoded = encode(outer)
  inspect(encoded.length(), content="Encoded nested list length")
  match decode(encoded) {
    Ok(List(items)) => {
      inspect(items.length() == 2, content="Should have 2 items")
      match items[0] {
        List(inner) =>
          inspect(
            inner.length() == 0,
            content="First item should be empty list",
          )
        _ => inspect(false, content="First item should be list")
      }
      match items[1] {
        List(inner) =>
          inspect(
            inner.length() == 1,
            content="Second item should have 1 nested item",
          )
        _ => inspect(false, content="Second item should be list")
      }
    }
    _ => inspect(false, content="Should decode to list")
  }
}

// ===== 往返测试 (Round-trip) =====

///|
/// 测试：字节串往返编码/解码
test "round trip bytes" {
  let original = FixedArray::make(10, b'\x00')
  for i = 0; i < 10; i = i + 1 {
    original[i] = (i + 65).to_byte() // 'A' to 'J'
  }
  let encoded = encode(RLPItem::from_bytes(original))
  match decode(encoded) {
    Ok(Bytes(decoded)) => {
      inspect(
        decoded.length() == original.length(),
        content="Length should match",
      )
      let mut match_count = 0
      for i = 0; i < original.length(); i = i + 1 {
        if decoded[i] == original[i] {
          match_count = match_count + 1
        }
      }
      inspect(
        match_count == original.length(),
        content="All bytes should match",
      )
      inspect(decoded, content="Round-trip decoded bytes")
    }
    _ => inspect(false, content="Should decode to bytes")
  }
}

///|
/// 测试：列表往返编码/解码
test "round trip list" {
  let item1 = FixedArray::make(3, b'\x00')
  item1[0] = b'x'
  item1[1] = b'y'
  item1[2] = b'z'
  let item2 = FixedArray::make(2, b'\x00')
  item2[0] = b'a'
  item2[1] = b'b'
  let original = RLPItem::from_list([
    RLPItem::from_bytes(item1),
    RLPItem::from_bytes(item2),
  ])
  let encoded = encode(original)
  match decode(encoded) {
    Ok(List(decoded)) => {
      inspect(decoded.length() == 2, content="Should have 2 items")
      inspect(decoded.length(), content="Round-trip decoded list item count")
    }
    _ => inspect(false, content="Should decode to list")
  }
}

// ===== 规范性检查测试 =====

///|
/// 测试：拒绝非规范的单字节编码
test "reject non-canonical single byte" {
  // 单字节值 0x42 应该直接编码，不应该使用 0x8142
  let data = FixedArray::make(2, b'\x00')
  data[0] = b'\x81' // 0x80 + 1
  data[1] = b'\x42' // 单字节值 <= 0x7f
  match decode(data) {
    Ok(_) => inspect(false, content="Should reject non-canonical encoding")
    Err(NonCanonicalEncoding) =>
      inspect(true, content="Correctly rejected non-canonical encoding")
    Err(e) => inspect(e, content="Unexpected error type")
  }
}

///|
/// 测试：拒绝带前导零的整数编码
test "reject leading zeros in integer" {
  // 整数 15 (0x0f) 不应该编码为 [0x82, 0x00, 0x0f]
  let data = FixedArray::make(3, b'\x00')
  data[0] = b'\x82' // 0x80 + 2
  data[1] = b'\x00' // 前导零（非规范）
  data[2] = b'\x0f' // 实际值
  match decode_int(data) {
    Ok(_) => inspect(false, content="Should reject leading zeros")
    Err(NonCanonicalEncoding) =>
      inspect(true, content="Correctly rejected leading zeros")
    Err(e) => inspect(e, content="Unexpected error type")
  }
}

///|
/// 测试：拒绝短字符串长度误用为长字符串
test "reject misused length encoding" {
  // 长度 <= 55 应该用短编码，不应该用长编码
  let data = FixedArray::make(3, b'\x00')
  data[0] = b'\xb8' // 0xb7 + 1 (长字符串)
  data[1] = b'\x03' // 长度 3（应该用短编码 0x83）
  data[2] = b'\x00'
  match decode(data) {
    Ok(_) => inspect(false, content="Should reject misused encoding")
    Err(NonCanonicalEncoding) =>
      inspect(true, content="Correctly rejected misused length encoding")
    Err(e) => inspect(e, content="Unexpected error type")
  }
}

// ===== 边界值测试 =====

///|
/// 测试：边界值 - 55字节字符串
test "encode 55 byte string" {
  let data = FixedArray::make(55, b'\x00')
  for i = 0; i < 55; i = i + 1 {
    data[i] = (i % 256).to_byte()
  }
  let encoded = encode(RLPItem::from_bytes(data))
  // 应该是短字符串编码: 0x80 + 55 = 0xb7
  inspect(
    encoded[0].to_int() == 0xb7,
    content="Should use short string encoding (0xb7)",
  )
}

///|
/// 测试：边界值 - 56字节字符串（长编码）
test "encode 56 byte string" {
  let data = FixedArray::make(56, b'\x00')
  for i = 0; i < 56; i = i + 1 {
    data[i] = (i % 256).to_byte()
  }
  let encoded = encode(RLPItem::from_bytes(data))
  // 应该使用长字符串编码
  inspect(
    encoded[0].to_int() == 0xb8 + 1,
    content="Should use long string encoding",
  )
  inspect(encoded[1].to_int() == 56, content="Length byte should be 56")
}

///|
/// 测试：边界值 - 列表 payload 55字节
test "encode list with 55 byte payload" {
  // 创建一个payload刚好55字节的列表
  let item = FixedArray::make(55, b'\x00')
  for i = 0; i < 55; i = i + 1 {
    item[i] = (i % 256).to_byte()
  }
  let list = RLPItem::from_list([RLPItem::from_bytes(item)])
  let encoded = encode(list)
  // 应该是短列表编码
  inspect(
    encoded[0].to_int() == 0xc0 + 56,
    content="Should use short list encoding",
  ) // 55字节payload + 1字节前缀 = 56
}

// ===== 错误处理测试 =====

///|
/// 测试：数据意外结束错误
test "decode unexpected end error" {
  // 声明长度为3，但只有1字节数据
  let data = FixedArray::make(2, b'\x00')
  data[0] = b'\x83' // 0x80 + 3，声明3字节
  data[1] = b'd' // 只有1字节数据
  match decode(data) {
    Ok(_) => inspect(false, content="Should error on unexpected end")
    Err(UnexpectedEnd) =>
      inspect(true, content="Correctly caught UnexpectedEnd error")
    Err(e) => inspect(e, content="Unexpected error type")
  }
}

///|
/// 测试：空数据错误
test "decode empty data error" {
  let empty = FixedArray::make(0, b'\x00')
  match decode(empty) {
    Ok(_) => inspect(false, content="Should error on empty data")
    Err(e) => inspect(e, content="Error on empty data")
  }
}

// ===== 便利函数测试 =====

///|
/// 测试：encode_bytes_list 函数
test "encode bytes list convenience" {
  let item1 = FixedArray::make(2, b'\x00')
  item1[0] = b'a'
  item1[1] = b'b'
  let item2 = FixedArray::make(2, b'\x00')
  item2[0] = b'c'
  item2[1] = b'd'
  let list = [item1, item2]
  let encoded = encode_bytes_list(list)
  inspect(encoded.length(), content="Encoded bytes list length")
  match decode_bytes_list(encoded) {
    Ok(decoded) => {
      inspect(decoded.length() == 2, content="Should decode to 2 items")
      inspect(decoded[0].length() == 2, content="First item should be 2 bytes")
      inspect(decoded[1].length() == 2, content="Second item should be 2 bytes")
    }
    Err(e) => inspect(e, content="Unexpected error")
  }
}

// ===== 大整数测试 =====

///|
/// 测试：大整数编码
test "encode large integer" {
  // 测试一个需要多字节的大整数
  let large = 0x12345678
  let encoded = encode_int(large)
  inspect(encoded.length(), content="Large integer encoding length")
  match decode_int(encoded) {
    Ok(decoded) => {
      inspect(decoded == large, content="Should decode to original value")
      inspect(decoded, content="Decoded large integer")
    }
    Err(e) => inspect(e, content="Unexpected error")
  }
}
