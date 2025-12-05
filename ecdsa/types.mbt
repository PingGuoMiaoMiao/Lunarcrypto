///|
/// ECDSA 核心类型定义
/// 实现 secp256k1 椭圆曲线数字签名算法

///|
/// 私钥类型
/// 32 字节的随机数，范围在 [1, n-1]，其中 n 是曲线阶数
pub struct PrivateKey {
  bytes : FixedArray[Byte] // 32 bytes
} derive(Eq)

///|
/// 公钥类型
/// 可以是压缩格式（33 字节）或未压缩格式（65 字节）
pub enum PublicKey {
  Uncompressed(FixedArray[Byte]) // 65 bytes: 0x04 + x + y
  Compressed(FixedArray[Byte]) // 33 bytes: 0x02/0x03 + x
} derive(Eq)

///|
/// ECDSA 签名
/// 包含 r, s 值和恢复 ID（以太坊特有）
pub struct Signature {
  r : FixedArray[Byte] // 32 bytes
  s : FixedArray[Byte] // 32 bytes
  v : Int // 恢复 ID: 0 或 1（以太坊中加上 27）
} derive(Eq, Show)

///|
/// ECDSA 错误类型
pub enum ECDSAError {
  InvalidPrivateKey(String)
  InvalidPublicKey(String)
  InvalidSignature(String)
  SignatureVerificationFailed
  PublicKeyRecoveryFailed
  InvalidRecoveryId
  ArithmeticError(String)
} derive(Eq, Show)

///|
/// Result 类型别名
pub type ECDSAResult[T] = Result[T, ECDSAError]

///|
/// PrivateKey 构造函数
pub fn PrivateKey::from_bytes(
  bytes : FixedArray[Byte],
) -> ECDSAResult[PrivateKey] {
  if bytes.length() != 32 {
    return Err(InvalidPrivateKey("Private key must be 32 bytes"))
  }
  // TODO: 验证私钥在有效范围内 [1, n-1]
  Ok(PrivateKey::{ bytes, })
}

///|
pub fn PrivateKey::to_bytes(self : PrivateKey) -> FixedArray[Byte] {
  self.bytes
}

///|
pub fn PrivateKey::from_hex(_hex : String) -> ECDSAResult[PrivateKey] {
  // TODO: 实现十六进制解析
  Err(InvalidPrivateKey("Not implemented yet"))
}

///|
pub fn PrivateKey::to_hex(self : PrivateKey) -> String {
  bytes_to_hex(self.bytes)
}

///|
/// PublicKey 构造函数
pub fn PublicKey::from_bytes(
  bytes : FixedArray[Byte],
) -> ECDSAResult[PublicKey] {
  let len = bytes.length()
  if len == 65 && bytes[0] == b'\x04' {
    Ok(Uncompressed(bytes))
  } else if len == 33 && (bytes[0] == b'\x02' || bytes[0] == b'\x03') {
    Ok(Compressed(bytes))
  } else {
    Err(InvalidPublicKey("Invalid public key format"))
  }
}

///|
pub fn PublicKey::to_bytes(self : PublicKey) -> FixedArray[Byte] {
  match self {
    Uncompressed(bytes) => bytes
    Compressed(bytes) => bytes
  }
}

///|
pub fn PublicKey::to_uncompressed(self : PublicKey) -> ECDSAResult[PublicKey] {
  match self {
    Uncompressed(_) => Ok(self)
    Compressed(_) =>
      Err(InvalidPublicKey("Compression conversion not implemented yet"))
  }
}

///|
pub fn PublicKey::to_compressed(self : PublicKey) -> ECDSAResult[PublicKey] {
  match self {
    Compressed(_) => Ok(self)
    Uncompressed(_) =>
      Err(InvalidPublicKey("Compression conversion not implemented yet"))
  }
}

///|
pub fn PublicKey::get_coordinates(
  self : PublicKey,
) -> ECDSAResult[FixedArray[Byte]] {
  match self {
    Uncompressed(bytes) => {
      let result = FixedArray::make(64, b'\x00')
      for i = 0; i < 64; i = i + 1 {
        result[i] = bytes[i + 1] // 跳过 0x04 前缀
      }
      Ok(result)
    }
    Compressed(_) => Err(InvalidPublicKey("Need to decompress first"))
  }
}

///|
/// Signature 构造函数
pub fn Signature::new(
  r : FixedArray[Byte],
  s : FixedArray[Byte],
  v : Int,
) -> ECDSAResult[Signature] {
  if r.length() != 32 {
    return Err(InvalidSignature("r must be 32 bytes"))
  }
  if s.length() != 32 {
    return Err(InvalidSignature("s must be 32 bytes"))
  }
  if v != 0 && v != 1 && v != 27 && v != 28 {
    return Err(InvalidSignature("v must be 0, 1, 27, or 28"))
  }
  Ok(Signature::{ r, s, v })
}

///|
pub fn Signature::to_bytes(self : Signature) -> FixedArray[Byte] {
  let result = FixedArray::make(65, b'\x00')

  // r (32 bytes)
  for i = 0; i < 32; i = i + 1 {
    result[i] = self.r[i]
  }

  // s (32 bytes)
  for i = 0; i < 32; i = i + 1 {
    result[32 + i] = self.s[i]
  }

  // v (1 byte)
  result[64] = self.v.to_byte()
  result
}

///|
pub fn Signature::from_bytes(
  bytes : FixedArray[Byte],
) -> ECDSAResult[Signature] {
  if bytes.length() != 65 {
    return Err(InvalidSignature("Signature must be 65 bytes"))
  }
  let r = FixedArray::make(32, b'\x00')
  let s = FixedArray::make(32, b'\x00')
  for i = 0; i < 32; i = i + 1 {
    r[i] = bytes[i]
    s[i] = bytes[32 + i]
  }
  let v = bytes[64].to_int()
  Signature::new(r, s, v)
}

///|
pub fn Signature::ethereum_v(self : Signature) -> Int {
  if self.v == 0 || self.v == 1 {
    self.v + 27
  } else {
    self.v
  }
}

///|
pub fn Signature::standard_v(self : Signature) -> Int {
  if self.v == 27 || self.v == 28 {
    self.v - 27
  } else {
    self.v
  }
}

///|
/// 辅助函数：字节数组转十六进制字符串
fn bytes_to_hex(bytes : FixedArray[Byte]) -> String {
  let mut result = "0x"
  let hex_chars = "0123456789abcdef"
  for i = 0; i < bytes.length(); i = i + 1 {
    let byte = bytes[i].to_int()
    let high = (byte >> 4) & 0x0F
    let low = byte & 0x0F
    result = result +
      hex_chars.code_unit_at(high).to_string() +
      hex_chars.code_unit_at(low).to_string()
  }
  result
}
