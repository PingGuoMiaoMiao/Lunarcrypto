///|
/// Legacy 交易实现 (EIP-155)
/// 支持传统的以太坊交易格式和 EIP-155 链 ID 保护

///|
/// Legacy 交易结构
/// 根据 EIP-155，v 值计算方式：
/// - 无链 ID: v = 27 或 28
/// - 有链 ID: v = chain_id * 2 + 35 或 chain_id * 2 + 36
pub struct LegacyTransaction {
  nonce : UInt64
  gas_price : UInt64
  gas_limit : UInt64
  to : Option[Address]  // None 表示合约创建
  value : UInt64
  data : FixedArray[Byte]
  v : UInt64  // 恢复 ID + chain_id 编码
  r : FixedArray[Byte]  // 32 bytes
  s : FixedArray[Byte]  // 32 bytes
} derive(Eq, Show)

///|
/// 创建未签名的 Legacy 交易
pub fn LegacyTransaction::new(
  nonce : UInt64,
  gas_price : UInt64,
  gas_limit : UInt64,
  to : Option[Address],
  value : UInt64,
  data : FixedArray[Byte],
) -> LegacyTransaction {
  {
    nonce,
    gas_price,
    gas_limit,
    to,
    value,
    data,
    v: 0UL,
    r: FixedArray::make(32, b'\x00'),
    s: FixedArray::make(32, b'\x00'),
  }
}

///|
/// 检查交易是否已签名
pub fn LegacyTransaction::is_signed(self : LegacyTransaction) -> Bool {
  let mut r_non_zero = false
  let mut s_non_zero = false
  for i = 0; i < 32; i = i + 1 {
    if self.r[i] != b'\x00' {
      r_non_zero = true
    }
    if self.s[i] != b'\x00' {
      s_non_zero = true
    }
  }
  r_non_zero && s_non_zero && self.v > 0UL
}

///|
/// 从链 ID 计算 v 值（EIP-155）
/// v = chain_id * 2 + 35 (recovery_id = 0)
/// v = chain_id * 2 + 36 (recovery_id = 1)
pub fn calculate_v_from_chain_id(chain_id : UInt64, recovery_id : Int) -> UInt64 {
  if recovery_id == 0 {
    chain_id * 2UL + 35UL
  } else {
    chain_id * 2UL + 36UL
  }
}

///|
/// 从 v 值提取链 ID（EIP-155）
/// 如果 v >= 35，则 chain_id = (v - 35) / 2
pub fn extract_chain_id_from_v(v : UInt64) -> Option[UInt64] {
  if v >= 35UL {
    let chain_id = (v - 35UL) / 2UL
    Some(chain_id)
  } else {
    None  // 旧格式，无链 ID
  }
}

///|
/// 从 v 值提取恢复 ID
/// 如果 v >= 35: recovery_id = (v - 35) % 2
/// 否则: recovery_id = v - 27
pub fn extract_recovery_id_from_v(v : UInt64) -> Int {
  if v >= 35UL {
    ((v - 35UL) % 2UL).to_int()
  } else {
    (v - 27UL).to_int()
  }
}

