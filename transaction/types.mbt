///|
/// 以太坊交易类型定义
/// 支持所有以太坊交易类型

///|
/// 交易错误类型
pub enum TransactionError {
  InvalidTransaction(String)
  InvalidChainId
  InvalidAddress(String)
  InvalidGasValue(String)
  EncodingError(String)
  SigningError(String)
} derive(Eq, Show)

///|
/// Result 类型别名
pub type TransactionResult[T] = Result[T, TransactionError]

///|
/// 以太坊地址类型（20 字节）
pub type Address = FixedArray[Byte] // 20 bytes

///|
/// 交易类型枚举
pub enum TransactionType {
  Legacy // 0x00 (无前缀) 或 EIP-155
  AccessList // 0x01 (EIP-2930)
  DynamicFee // 0x02 (EIP-1559)
  Blob // 0x03 (EIP-4844)
} derive(Eq, Show)

///|
/// 验证地址格式
pub fn is_valid_address(addr : Address) -> Bool {
  addr.length() == 20
}

///|
/// 创建地址（从 20 字节）
pub fn address_from_bytes(
  bytes : FixedArray[Byte],
) -> TransactionResult[Address] {
  if bytes.length() != 20 {
    Err(InvalidAddress("Address must be 20 bytes"))
  } else {
    Ok(bytes)
  }
}

///|
/// 空地址（用于合约创建）
pub fn empty_address() -> Address {
  FixedArray::make(20, b'\x00')
}

///|
/// 检查是否为空地址
pub fn is_empty_address(addr : Address) -> Bool {
  let mut all_zero = true
  for i = 0; i < 20; i = i + 1 {
    if addr[i] != b'\x00' {
      all_zero = false
      break
    }
  }
  all_zero
}
