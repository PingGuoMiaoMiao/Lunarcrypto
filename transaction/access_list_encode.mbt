///|
/// EIP-2930 Access List 交易 RLP 编码
/// 格式: 0x01 || RLP([chainId, nonce, gasPrice, gasLimit, to, value, data, accessList, v, r, s])
/// 
/// 注意：u64_to_bytes 函数已在 encode.mbt 中定义，直接使用

///|
/// 编码 Access Tuple 为 RLP
/// 格式: RLP([address, [storage_keys...]])
fn encode_access_tuple(tuple : AccessTuple) -> @rlp.RLPItem {
  let storage_items : Array[@rlp.RLPItem] = []
  for i = 0; i < tuple.storage_keys.length(); i = i + 1 {
    storage_items.push(@rlp.RLPItem::from_bytes(tuple.storage_keys[i]))
  }
  
  let items : Array[@rlp.RLPItem] = []
  items.push(@rlp.RLPItem::from_bytes(tuple.address))
  items.push(@rlp.RLPItem::from_list(storage_items))
  
  @rlp.RLPItem::from_list(items)
}

///|
/// 编码 Access List 为 RLP
/// 格式: RLP([access_tuple1, access_tuple2, ...])
fn encode_access_list(access_list : Array[AccessTuple]) -> @rlp.RLPItem {
  let items : Array[@rlp.RLPItem] = []
  for i = 0; i < access_list.length(); i = i + 1 {
    items.push(encode_access_tuple(access_list[i]))
  }
  @rlp.RLPItem::from_list(items)
}

///|
/// 编码已签名的 Access List 交易
/// 格式: 0x01 || RLP([chainId, nonce, gasPrice, gasLimit, to, value, data, accessList, v, r, s])
pub fn encode_access_list_transaction(tx : AccessListTransaction) -> FixedArray[Byte] {
  let items : Array[@rlp.RLPItem] = []
  
  // chainId
  items.push(@rlp.RLPItem::from_bytes(u64_to_bytes(tx.chain_id)))
  
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
  
  // accessList
  items.push(encode_access_list(tx.access_list))
  
  // v, r, s (签名部分)
  items.push(@rlp.RLPItem::from_bytes(u64_to_bytes(tx.v)))
  items.push(@rlp.RLPItem::from_bytes(tx.r))
  items.push(@rlp.RLPItem::from_bytes(tx.s))
  
  // RLP 编码
  let rlp_encoded = @rlp.encode(@rlp.RLPItem::from_list(items))
  
  // 添加交易类型前缀 0x01
  let result = FixedArray::make(1 + rlp_encoded.length(), b'\x00')
  result[0] = b'\x01'  // EIP-2930 交易类型标识
  for i = 0; i < rlp_encoded.length(); i = i + 1 {
    result[i + 1] = rlp_encoded[i]
  }
  result
}

///|
/// 编码未签名的 Access List 交易（用于签名）
/// 格式: 0x01 || RLP([chainId, nonce, gasPrice, gasLimit, to, value, data, accessList])
pub fn encode_unsigned_access_list_transaction(
  tx : AccessListTransaction,
) -> FixedArray[Byte] {
  let items : Array[@rlp.RLPItem] = []
  
  // chainId
  items.push(@rlp.RLPItem::from_bytes(u64_to_bytes(tx.chain_id)))
  
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
  
  // accessList
  items.push(encode_access_list(tx.access_list))
  
  // RLP 编码
  let rlp_encoded = @rlp.encode(@rlp.RLPItem::from_list(items))
  
  // 添加交易类型前缀 0x01
  let result = FixedArray::make(1 + rlp_encoded.length(), b'\x00')
  result[0] = b'\x01'  // EIP-2930 交易类型标识
  for i = 0; i < rlp_encoded.length(); i = i + 1 {
    result[i + 1] = rlp_encoded[i]
  }
  result
}

