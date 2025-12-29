///|
/// EIP-1559 Dynamic Fee 交易实现
/// 交易类型标识: 0x02
/// 参考: https://eips.ethereum.org/EIP-1559

///|
/// EIP-1559 Dynamic Fee 交易结构
/// 
/// RLP 编码格式：
/// 0x02 || RLP([chainId, nonce, maxPriorityFeePerGas, maxFeePerGas, gasLimit, to, value, data, accessList, signatureYParity, signatureR, signatureS])
/// 
/// Gas 费用说明：
/// - maxPriorityFeePerGas (tip): 支付给矿工的小费
/// - maxFeePerGas: baseFeePerGas + maxPriorityFeePerGas（用户愿意支付的最大费用）
/// - baseFeePerGas: 由协议计算，不包含在交易中
pub struct EIP1559Transaction {
  chain_id : UInt64
  nonce : UInt64
  max_priority_fee_per_gas : UInt64  // tip
  max_fee_per_gas : UInt64  // baseFee + maxPriorityFee
  gas_limit : UInt64
  to : Option[Address]  // None 表示合约创建
  value : UInt64
  data : FixedArray[Byte]
  access_list : Array[AccessTuple]  // 复用 EIP-2930 的 AccessTuple
  v : UInt64  // 恢复 ID: 0 或 1
  r : FixedArray[Byte]  // 32 bytes
  s : FixedArray[Byte]  // 32 bytes
} derive(Eq, Show)

///|
/// 创建未签名的 EIP-1559 交易
pub fn EIP1559Transaction::new(
  chain_id : UInt64,
  nonce : UInt64,
  max_priority_fee_per_gas : UInt64,
  max_fee_per_gas : UInt64,
  gas_limit : UInt64,
  to : Option[Address],
  value : UInt64,
  data : FixedArray[Byte],
  access_list : Array[AccessTuple],
) -> EIP1559Transaction {
  {
    chain_id,
    nonce,
    max_priority_fee_per_gas,
    max_fee_per_gas,
    gas_limit,
    to,
    value,
    data,
    access_list,
    v: 0UL,
    r: FixedArray::make(32, b'\x00'),
    s: FixedArray::make(32, b'\x00'),
  }
}

///|
/// 检查交易是否已签名
pub fn EIP1559Transaction::is_signed(self : EIP1559Transaction) -> Bool {
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
  r_non_zero && s_non_zero && self.v <= 1UL
}

///|
/// 计算实际支付的 gas 价格
/// effectiveGasPrice = min(maxFeePerGas, baseFeePerGas + maxPriorityFeePerGas)
pub fn EIP1559Transaction::calculate_effective_gas_price(
  self : EIP1559Transaction,
  base_fee_per_gas : UInt64,
) -> UInt64 {
  let gas_price = base_fee_per_gas + self.max_priority_fee_per_gas
  if gas_price > self.max_fee_per_gas {
    self.max_fee_per_gas
  } else {
    gas_price
  }
}

///|
/// 计算最大总费用
/// maxTotalFee = maxFeePerGas * gasLimit
pub fn EIP1559Transaction::max_total_fee(self : EIP1559Transaction) -> UInt64 {
  self.max_fee_per_gas * self.gas_limit
}

///|
/// 计算实际总费用（需要 baseFee）
/// actualTotalFee = effectiveGasPrice * gasLimit
pub fn EIP1559Transaction::actual_total_fee(
  self : EIP1559Transaction,
  base_fee_per_gas : UInt64,
) -> UInt64 {
  let effective_price = self.calculate_effective_gas_price(base_fee_per_gas)
  effective_price * self.gas_limit
}

