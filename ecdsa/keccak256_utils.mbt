///|
/// Keccak256 工具函数
/// 提供与 ECDSA 模块集成的 Keccak256 哈希功能

///|
/// 将 FixedArray[Byte] 转换为 Array[Byte]
/// 使用更安全的方法
fn fixed_to_array(fixed : FixedArray[Byte]) -> Array[Byte] {
  let len = fixed.length()
  let arr : Array[Byte] = []
  for i = 0; i < len; i = i + 1 {
    arr.push(fixed[i])
  }
  arr
}

///|
/// 将 Array[Byte] 转换为 FixedArray[Byte]
/// 使用更安全的方法
fn array_to_fixed(arr : Array[Byte]) -> FixedArray[Byte] {
  let len = arr.length()
  let fixed = FixedArray::make(len, b'\x00')
  for i = 0; i < len; i = i + 1 {
    fixed[i] = arr[i]
  }
  fixed
}

///|
/// 计算字节数组的 Keccak256 哈希
/// 输入: FixedArray[Byte]
/// 输出: FixedArray[Byte] (32 字节)
pub fn keccak256(data : FixedArray[Byte]) -> FixedArray[Byte] {
  let arr = fixed_to_array(data)
  let hash_arr = @lib.keccak256(arr)
  array_to_fixed(hash_arr)
}

///|
/// 计算字节数组的 Keccak256 哈希（返回十六进制字符串）
pub fn keccak256_hex(data : FixedArray[Byte]) -> String {
  let arr = fixed_to_array(data)
  @lib.keccak256_hex(arr)
}

///|
/// 计算字符串的 Keccak256 哈希
pub fn keccak256_string(message : String) -> FixedArray[Byte] {
  let hash_arr = @lib.keccak256_string(message)
  array_to_fixed(hash_arr)
}

///|
/// 计算字符串的 Keccak256 哈希（返回十六进制字符串）
pub fn keccak256_string_hex(message : String) -> String {
  @lib.keccak256_string_hex(message)
}

///|
test "keccak256 - string only" {
  // 只测试字符串版本，不涉及数组转换
  let hash_hex = keccak256_string_hex("abc")
  // "abc" 的 Keccak256 哈希
  inspect(
    hash_hex,
    content="4e03657aea45a94fc7d47ba826c8d667c0d1e6e33a64a036ec44f58fa12d6c45",
  )
}
