///|
/// 辅助工具函数

// 将整数转换为最小的大端字节表示（无前导零）
pub fn int_to_big_endian_minimal(value : Int) -> FixedArray[Byte] {
  if value == 0 {
    return FixedArray::make(0, b'\x00')
  }

  // 计算需要的字节数
  let mut v = value
  let mut byte_count = 0
  while v > 0 {
    byte_count = byte_count + 1
    v = v >> 8
  }

  // 创建字节数组
  let result = FixedArray::make(byte_count, b'\x00')
  v = value
  for i = byte_count - 1; i >= 0; i = i - 1 {
    result[i] = v.land(0xFF).to_byte()
    v = v >> 8
  }
  result
}

// 将大端字节数组转换为整数

///|
pub fn big_endian_to_int(bytes : FixedArray[Byte]) -> Int {
  let mut result = 0
  let len = bytes.length()
  for i = 0; i < len; i = i + 1 {
    result = (result << 8) | bytes[i].to_int()
  }
  result
}

// 检查字节数组是否为规范的大端表示（无前导零）

///|
pub fn is_canonical_big_endian(bytes : FixedArray[Byte]) -> Bool {
  let len = bytes.length()
  if len == 0 {
    return true
  }
  // 第一个字节不能为 0（除非是单个零字节）
  if len > 1 && bytes[0].to_int() == 0 {
    return false
  }
  true
}

///|
/// FixedArray[Byte] 拼接辅助函数
pub fn concat_bytes(
  a : FixedArray[Byte],
  b : FixedArray[Byte],
) -> FixedArray[Byte] {
  let len_a = a.length()
  let len_b = b.length()
  let result = FixedArray::make(len_a + len_b, b'\x00')
  for i = 0; i < len_a; i = i + 1 {
    result[i] = a[i]
  }
  for i = 0; i < len_b; i = i + 1 {
    result[len_a + i] = b[i]
  }
  result
}

///|
pub fn concat_bytes_array(arr : Array[FixedArray[Byte]]) -> FixedArray[Byte] {
  let mut total_len = 0
  for b in arr {
    total_len = total_len + b.length()
  }
  let result = FixedArray::make(total_len, b'\x00')
  let mut offset = 0
  for b in arr {
    let len = b.length()
    for i = 0; i < len; i = i + 1 {
      result[offset + i] = b[i]
    }
    offset = offset + len
  }
  result
}

///|
/// FixedArray[Byte] 切片
pub fn slice_bytes(
  bytes : FixedArray[Byte],
  start : Int,
  end : Int,
) -> FixedArray[Byte] {
  let len = end - start
  if len <= 0 {
    return FixedArray::make(0, b'\x00')
  }
  let result = FixedArray::make(len, b'\x00')
  for i = 0; i < len; i = i + 1 {
    result[i] = bytes[start + i]
  }
  result
}
