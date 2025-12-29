///|
/// EIP-1559 Dynamic Fee 交易 RLP 编码
/// 格式: 0x02 || RLP([chainId, nonce, maxPriorityFeePerGas, maxFeePerGas, gasLimit, to, value, data, accessList, v, r, s])
/// 
/// 注意：复用 access_list_encode.mbt 中的 encode_access_list 函数

///|
/// 编码已签名的 EIP-1559 交易
/// 格式: 0x02 || RLP([chainId, nonce, maxPriorityFeePerGas, maxFeePerGas, gasLimit, to, value, data, accessList, v, r, s])
pub fn encode_eip1559_transaction(tx : EIP1559Transaction) -> FixedArray[Byte] {
  let items : Array[@rlp.RLPItem] = []
  
  // chainId
  items.push(@rlp.RLPItem::from_bytes(u64_to_bytes(tx.chain_id)))
  
  // nonce
  items.push(@rlp.RLPItem::from_bytes(u64_to_bytes(tx.nonce)))
  
  // maxPriorityFeePerGas
  items.push(@rlp.RLPItem::from_bytes(u64_to_bytes(tx.max_priority_fee_per_gas)))
  
  // maxFeePerGas
  items.push(@rlp.RLPItem::from_bytes(u64_to_bytes(tx.max_fee_per_gas)))
  
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
  
  // accessList（复用 encode_access_list 函数）
  items.push(encode_access_list(tx.access_list))
  
  // v, r, s (签名部分)
  items.push(@rlp.RLPItem::from_bytes(u64_to_bytes(tx.v)))
  items.push(@rlp.RLPItem::from_bytes(tx.r))
  items.push(@rlp.RLPItem::from_bytes(tx.s))
  
  // RLP 编码
  let rlp_encoded = @rlp.encode(@rlp.RLPItem::from_list(items))
  
  // 添加交易类型前缀 0x02
  let result = FixedArray::make(1 + rlp_encoded.length(), b'\x00')
  result[0] = b'\x02'  // EIP-1559 交易类型标识
  for i = 0; i < rlp_encoded.length(); i = i + 1 {
    result[i + 1] = rlp_encoded[i]
  }
  result
}

///|
/// 编码未签名的 EIP-1559 交易（用于签名）
/// 格式: 0x02 || RLP([chainId, nonce, maxPriorityFeePerGas, maxFeePerGas, gasLimit, to, value, data, accessList])
pub fn encode_unsigned_eip1559_transaction(
  tx : EIP1559Transaction,
) -> FixedArray[Byte] {
  let items : Array[@rlp.RLPItem] = []
  
  // chainId
  items.push(@rlp.RLPItem::from_bytes(u64_to_bytes(tx.chain_id)))
  
  // nonce
  items.push(@rlp.RLPItem::from_bytes(u64_to_bytes(tx.nonce)))
  
  // maxPriorityFeePerGas
  items.push(@rlp.RLPItem::from_bytes(u64_to_bytes(tx.max_priority_fee_per_gas)))
  
  // maxFeePerGas
  items.push(@rlp.RLPItem::from_bytes(u64_to_bytes(tx.max_fee_per_gas)))
  
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
  
  // accessList
  items.push(encode_access_list(tx.access_list))
  
  // RLP 编码
  let rlp_encoded = @rlp.encode(@rlp.RLPItem::from_list(items))
  
  // 添加交易类型前缀 0x02
  let result = FixedArray::make(1 + rlp_encoded.length(), b'\x00')
  result[0] = b'\x02'  // EIP-1559 交易类型标识
  for i = 0; i < rlp_encoded.length(); i = i + 1 {
    result[i + 1] = rlp_encoded[i]
  }
  result
}

