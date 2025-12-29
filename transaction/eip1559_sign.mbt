///|
/// EIP-1559 Dynamic Fee 交易签名
/// 实现 EIP-1559 交易签名逻辑

///|
/// 签名 EIP-1559 交易
/// 步骤：
/// 1. 编码未签名交易（包含交易类型前缀 0x02）
/// 2. 计算交易哈希（Keccak256）
/// 3. 使用 ECDSA 签名哈希
/// 4. 设置 v 值（0 或 1，即恢复 ID）
/// 5. 构建已签名交易
/// 
/// 使用 @ 语法访问导入的包：@ecdsa
pub fn sign_eip1559_transaction(
  tx : EIP1559Transaction,
  private_key_bytes : FixedArray[Byte],  // 32 字节私钥
) -> TransactionResult[EIP1559Transaction] {
  // 1. 从字节创建 PrivateKey
  match @ecdsa.PrivateKey::from_bytes(private_key_bytes) {
    Err(_) => Err(SigningError("Invalid private key"))
    Ok(private_key) => {
      // 2. 计算交易哈希
      let tx_hash = eip1559_transaction_hash(tx)
      
      // 3. 使用 ECDSA 签名
      match @ecdsa.sign(tx_hash, private_key) {
        Err(_) => Err(SigningError("ECDSA signing failed"))
        Ok(signature) => {
          // 4. EIP-1559 中 v 值直接是恢复 ID (0 或 1)
          // signature.v 是 Int 类型，需要转换为 UInt64
          let v = signature.v.to_uint64()
          
          // 5. 构建已签名交易
          Ok(EIP1559Transaction::{
            chain_id: tx.chain_id,
            nonce: tx.nonce,
            max_priority_fee_per_gas: tx.max_priority_fee_per_gas,
            max_fee_per_gas: tx.max_fee_per_gas,
            gas_limit: tx.gas_limit,
            to: tx.to,
            value: tx.value,
            data: tx.data,
            access_list: tx.access_list,
            v: v,
            r: signature.r,
            s: signature.s,
          })
        }
      }
    }
  }
}

