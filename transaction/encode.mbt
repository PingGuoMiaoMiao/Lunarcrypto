///|
/// Legacy 交易 RLP 编码
/// 根据以太坊规范：RLP([nonce, gasPrice, gasLimit, to, value, data, v, r, s])

///|
/// 将 UInt64 转换为最小大端字节数组
fn u64_to_bytes(value : UInt64) -> FixedArray[Byte] {
  if value == 0UL {
    return FixedArray::make(0, b'\x00')
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
  bytes
}

///|
/// 编码 Legacy 交易为 RLP
/// 格式：RLP([nonce, gasPrice, gasLimit, to, value, data, v, r, s])
/// 
/// 使用 @ 语法访问导入的包，根据编译命令中的别名使用 @rlp
/// 注意：RLPItem::Bytes 是只读类型，需要使用 RLPItem::from_bytes() 创建
pub fn encode_legacy_transaction(tx : LegacyTransaction) -> FixedArray[Byte] {
  let items : Array[@rlp.RLPItem] = []
  
  // nonce
  items.push(@rlp.RLPItem::from_bytes(u64_to_bytes(tx.nonce)))
  
  // gasPrice
  items.push(@rlp.RLPItem::from_bytes(u64_to_bytes(tx.gas_price)))
  
  // gasLimit
  items.push(@rlp.RLPItem::from_bytes(u64_to_bytes(tx.gas_limit)))
  
  // to (地址或空)
  match tx.to {
    Some(addr) => items.push(@rlp.RLPItem::from_bytes(addr))
    None => items.push(@rlp.RLPItem::from_bytes(FixedArray::make(0, b'\x00')))  // 空地址表示合约创建
  }
  
  // value
  items.push(@rlp.RLPItem::from_bytes(u64_to_bytes(tx.value)))
  
  // data
  items.push(@rlp.RLPItem::from_bytes(tx.data))
  
  // v, r, s (签名部分)
  items.push(@rlp.RLPItem::from_bytes(u64_to_bytes(tx.v)))
  items.push(@rlp.RLPItem::from_bytes(tx.r))
  items.push(@rlp.RLPItem::from_bytes(tx.s))
  
  // 使用 RLP 编码
  @rlp.encode(@rlp.RLPItem::from_list(items))
}

///|
/// 编码未签名的 Legacy 交易（用于签名）
/// EIP-155: RLP([nonce, gasPrice, gasLimit, to, value, data, chainId, 0, 0])
pub fn encode_unsigned_legacy_transaction(
  tx : LegacyTransaction,
  chain_id : UInt64,
) -> FixedArray[Byte] {
  let items : Array[@rlp.RLPItem] = []
  
  // nonce
  items.push(@rlp.RLPItem::from_bytes(u64_to_bytes(tx.nonce)))
  
  // gasPrice
  items.push(@rlp.RLPItem::from_bytes(u64_to_bytes(tx.gas_price)))
  
  // gasLimit
  items.push(@rlp.RLPItem::from_bytes(u64_to_bytes(tx.gas_limit)))
  
  // to
  match tx.to {
    Some(addr) => items.push(@rlp.RLPItem::from_bytes(addr))
    None => items.push(@rlp.RLPItem::from_bytes(FixedArray::make(0, b'\x00')))
  }
  
  // value
  items.push(@rlp.RLPItem::from_bytes(u64_to_bytes(tx.value)))
  
  // data
  items.push(@rlp.RLPItem::from_bytes(tx.data))
  
  // EIP-155: chainId, 0, 0
  items.push(@rlp.RLPItem::from_bytes(u64_to_bytes(chain_id)))
  items.push(@rlp.RLPItem::from_bytes(FixedArray::make(0, b'\x00')))  // r = 0
  items.push(@rlp.RLPItem::from_bytes(FixedArray::make(0, b'\x00')))  // s = 0
  
  @rlp.encode(@rlp.RLPItem::from_list(items))
}
