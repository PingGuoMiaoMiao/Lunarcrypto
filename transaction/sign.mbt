///|
/// Legacy 交易签名
/// 实现 EIP-155 交易签名逻辑

///|
/// 签名 Legacy 交易
/// 步骤：
/// 1. 编码未签名交易（包含 chain_id）
/// 2. 计算交易哈希（Keccak256）
/// 3. 使用 ECDSA 签名哈希
/// 4. 计算 v 值（chain_id * 2 + 35/36）
/// 5. 构建已签名交易
/// 
/// 使用 @ 语法访问导入的包：@ecdsa
pub fn sign_legacy_transaction(
  tx : LegacyTransaction,
  private_key_bytes : FixedArray[Byte],  // 32 字节私钥
  chain_id : UInt64,
) -> TransactionResult[LegacyTransaction] {
  // 1. 从字节创建 PrivateKey
  match @ecdsa.PrivateKey::from_bytes(private_key_bytes) {
    Err(_) => Err(SigningError("Invalid private key"))
    Ok(private_key) => {
      // 2. 计算交易哈希
      let tx_hash = legacy_transaction_hash(tx, chain_id)
      
      // 3. 使用 ECDSA 签名
      match @ecdsa.sign(tx_hash, private_key) {
        Err(_) => Err(SigningError("ECDSA signing failed"))
        Ok(signature) => {
          // 4. 计算 v 值（EIP-155: chain_id * 2 + 35 + recovery_id）
          // signature.v 是恢复 ID (0 或 1)
          let recovery_id = signature.v
          let v = calculate_v_from_chain_id(chain_id, recovery_id)
          
          // 5. 构建已签名交易
          Ok(LegacyTransaction::{
            nonce: tx.nonce,
            gas_price: tx.gas_price,
            gas_limit: tx.gas_limit,
            to: tx.to,
            value: tx.value,
            data: tx.data,
            v: v,
            r: signature.r,
            s: signature.s,
          })
        }
      }
    }
  }
}
