# 🌉 WASM 桥接实现计划

> **推荐方案**: 使用 Rust k256 库编译为 WASM，通过 MoonBit WASM FFI 调用

---

## 📋 实现步骤

### Step 1: 创建 Rust WASM 项目 (30分钟)

```bash
cd /home/pingguomiaomiao/Desktop/Lunarcrypto
mkdir secp256k1-wasm
cd secp256k1-wasm

# 初始化项目
cargo init --lib

# 配置 Cargo.toml
cat > Cargo.toml << 'EOF'
[package]
name = "secp256k1-wasm"
version = "0.1.0"
edition = "2021"

[lib]
crate-type = ["cdylib"]

[dependencies]
k256 = { version = "0.13", features = ["ecdsa", "sha256"] }
wasm-bindgen = "0.2"

[profile.release]
opt-level = 3
lto = true
EOF
```

### Step 2: 实现核心函数 (2-3小时)

```rust
// src/lib.rs
use k256::ecdsa::{SigningKey, VerifyingKey, Signature, signature::Signer, signature::Verifier};
use k256::elliptic_curve::sec1::ToEncodedPoint;
use wasm_bindgen::prelude::*;

///| 从私钥派生公钥（未压缩格式，65字节）
#[wasm_bindgen]
pub fn derive_public_key(private_key: &[u8]) -> Result<Vec<u8>, JsValue> {
    if private_key.len() != 32 {
        return Err(JsValue::from_str("Private key must be 32 bytes"));
    }
    
    let signing_key = SigningKey::from_bytes(private_key.into())
        .map_err(|e| JsValue::from_str(&format!("Invalid private key: {}", e)))?;
    
    let verifying_key = signing_key.verifying_key();
    let encoded = verifying_key.to_encoded_point(false); // 未压缩
    
    Ok(encoded.as_bytes().to_vec())
}

///| 签名消息哈希（返回 r + s + v，65字节）
#[wasm_bindgen]
pub fn sign_hash(message_hash: &[u8], private_key: &[u8]) -> Result<Vec<u8>, JsValue> {
    if message_hash.len() != 32 {
        return Err(JsValue::from_str("Message hash must be 32 bytes"));
    }
    if private_key.len() != 32 {
        return Err(JsValue::from_str("Private key must be 32 bytes"));
    }
    
    let signing_key = SigningKey::from_bytes(private_key.into())
        .map_err(|e| JsValue::from_str(&format!("Invalid private key: {}", e)))?;
    
    // k256 使用 RFC 6979 确定性签名
    let signature: Signature = signing_key.sign(message_hash);
    
    // 获取 r, s 值
    let sig_bytes = signature.to_bytes();
    
    // 计算恢复 ID
    let recovery_id = calculate_recovery_id(&signing_key, message_hash, &signature)?;
    
    // 返回 r + s + v (65 字节)
    let mut result = Vec::with_capacity(65);
    result.extend_from_slice(&sig_bytes);
    result.push(recovery_id);
    
    Ok(result)
}

///| 验证签名
#[wasm_bindgen]
pub fn verify_signature(
    message_hash: &[u8],
    signature: &[u8],
    public_key: &[u8]
) -> Result<bool, JsValue> {
    if message_hash.len() != 32 {
        return Err(JsValue::from_str("Message hash must be 32 bytes"));
    }
    if signature.len() < 64 {
        return Err(JsValue::from_str("Signature must be at least 64 bytes"));
    }
    
    // 解析公钥
    let verifying_key = VerifyingKey::from_sec1_bytes(public_key)
        .map_err(|e| JsValue::from_str(&format!("Invalid public key: {}", e)))?;
    
    // 解析签名（只取前 64 字节的 r + s）
    let sig = Signature::try_from(&signature[..64])
        .map_err(|e| JsValue::from_str(&format!("Invalid signature: {}", e)))?;
    
    // 验证
    Ok(verifying_key.verify(message_hash, &sig).is_ok())
}

///| 从签名恢复公钥（未压缩格式，65字节）
#[wasm_bindgen]
pub fn recover_public_key(
    message_hash: &[u8],
    signature: &[u8]
) -> Result<Vec<u8>, JsValue> {
    if message_hash.len() != 32 {
        return Err(JsValue::from_str("Message hash must be 32 bytes"));
    }
    if signature.len() != 65 {
        return Err(JsValue::from_str("Signature must be 65 bytes (r+s+v)"));
    }
    
    // 解析 r, s, v
    let sig = Signature::try_from(&signature[..64])
        .map_err(|e| JsValue::from_str(&format!("Invalid signature: {}", e)))?;
    let recovery_id = signature[64];
    
    // 使用 k256 的恢复功能
    use k256::ecdsa::RecoveryId;
    let rid = RecoveryId::try_from(recovery_id % 4)
        .map_err(|e| JsValue::from_str(&format!("Invalid recovery ID: {}", e)))?;
    
    let verifying_key = VerifyingKey::recover_from_prehash(message_hash, &sig, rid)
        .map_err(|e| JsValue::from_str(&format!("Recovery failed: {}", e)))?;
    
    let encoded = verifying_key.to_encoded_point(false); // 未压缩
    Ok(encoded.as_bytes().to_vec())
}

// 辅助函数：计算恢复 ID
fn calculate_recovery_id(
    signing_key: &SigningKey,
    message: &[u8],
    signature: &Signature
) -> Result<u8, JsValue> {
    let verifying_key = signing_key.verifying_key();
    let expected_pubkey = verifying_key.to_encoded_point(false);
    
    // 尝试 4 个可能的恢复 ID
    for recovery_id in 0..4 {
        use k256::ecdsa::RecoveryId;
        let rid = RecoveryId::try_from(recovery_id).unwrap();
        
        if let Ok(recovered_key) = VerifyingKey::recover_from_prehash(message, signature, rid) {
            let recovered_pubkey = recovered_key.to_encoded_point(false);
            if recovered_pubkey == expected_pubkey {
                return Ok(recovery_id);
            }
        }
    }
    
    Err(JsValue::from_str("Failed to determine recovery ID"))
}
```

### Step 3: 编译为 WASM (5分钟)

```bash
# 安装 wasm-pack（如果还没有）
curl https://rustwasm.github.io/wasm-pack/installer/init.sh -sSf | sh

# 编译
wasm-pack build --target web --release

# 输出位于 pkg/ 目录
```

### Step 4: MoonBit WASM FFI 绑定 (1-2小时)

```moonbit
// ecdsa/wasm_bridge.mbt

///| WASM 外部函数声明
extern "wasm" fn derive_public_key(
  private_key: FixedArray[Byte]
) -> FixedArray[Byte]

extern "wasm" fn sign_hash(
  message_hash: FixedArray[Byte],
  private_key: FixedArray[Byte]
) -> FixedArray[Byte]

extern "wasm" fn verify_signature(
  message_hash: FixedArray[Byte],
  signature: FixedArray[Byte],
  public_key: FixedArray[Byte]
) -> Bool

extern "wasm" fn recover_public_key(
  message_hash: FixedArray[Byte],
  signature: FixedArray[Byte]
) -> FixedArray[Byte]

///| 实现公钥派生
pub fn derive_public_key_impl(private_key: PrivateKey) -> ECDSAResult[PublicKey] {
  let pubkey_bytes = derive_public_key(private_key.to_bytes())
  PublicKey::from_bytes(pubkey_bytes)
}

///| 实现签名
pub fn sign_impl(
  message_hash: FixedArray[Byte],
  private_key: PrivateKey
) -> ECDSAResult[Signature] {
  if message_hash.length() != 32 {
    return Err(InvalidSignature("Message hash must be 32 bytes"))
  }
  
  let sig_bytes = sign_hash(message_hash, private_key.to_bytes())
  Signature::from_bytes(sig_bytes)
}

///| 实现验证
pub fn verify_impl(
  message_hash: FixedArray[Byte],
  signature: Signature,
  public_key: PublicKey
) -> Bool {
  verify_signature(
    message_hash,
    signature.to_bytes(),
    public_key.to_bytes()
  )
}

///| 实现公钥恢复
pub fn recover_public_key_impl(
  message_hash: FixedArray[Byte],
  signature: Signature
) -> ECDSAResult[PublicKey] {
  let pubkey_bytes = recover_public_key(message_hash, signature.to_bytes())
  PublicKey::from_bytes(pubkey_bytes)
}
```

### Step 5: 更新现有实现 (30分钟)

替换占位符实现：

```moonbit
// ecdsa/keypair.mbt
pub fn derive_public_key(private_key: PrivateKey) -> ECDSAResult[PublicKey] {
  derive_public_key_impl(private_key)  // 调用 WASM 桥接
}

// ecdsa/sign.mbt
pub fn sign(
  message_hash: FixedArray[Byte],
  private_key: PrivateKey
) -> ECDSAResult[Signature] {
  sign_impl(message_hash, private_key)  // 调用 WASM 桥接
}

// ecdsa/verify.mbt
pub fn verify(
  message_hash: FixedArray[Byte],
  signature: Signature,
  public_key: PublicKey
) -> Bool {
  verify_impl(message_hash, signature, public_key)  // 调用 WASM 桥接
}

// ecdsa/recovery.mbt
pub fn recover_public_key(
  message_hash: FixedArray[Byte],
  signature: Signature
) -> ECDSAResult[PublicKey] {
  recover_public_key_impl(message_hash, signature)  // 调用 WASM 桥接
}
```

### Step 6: 测试 (1-2小时)

```moonbit
// ecdsa/wasm_test.mbt

test "wasm keypair generation" {
  let private_key = generate_private_key()?
  let public_key = derive_public_key(private_key)?
  
  // 验证公钥格式
  let pubkey_bytes = public_key.to_bytes()
  assert_eq!(pubkey_bytes.length(), 65)
  assert_eq!(pubkey_bytes[0], b'\x04')  // 未压缩格式
}

test "wasm sign and verify" {
  let private_key = generate_private_key()?
  let public_key = derive_public_key(private_key)?
  
  let message_hash = FixedArray::make(32, b'\x01')
  let signature = sign(message_hash, private_key)?
  
  // 验证签名
  assert!(verify(message_hash, signature, public_key))
  
  // 错误的消息应该验证失败
  let wrong_hash = FixedArray::make(32, b'\x02')
  assert_false!(verify(wrong_hash, signature, public_key))
}

test "wasm public key recovery" {
  let private_key = generate_private_key()?
  let public_key = derive_public_key(private_key)?
  
  let message_hash = FixedArray::make(32, b'\x01')
  let signature = sign(message_hash, private_key)?
  
  // 恢复公钥
  let recovered = recover_public_key(message_hash, signature)?
  
  // 应该与原公钥相同
  assert_eq!(recovered, public_key)
}
```

---

## 📊 时间估算

| 步骤 | 时间 | 累计 |
|------|------|------|
| 1. 创建 Rust 项目 | 30分钟 | 30分钟 |
| 2. 实现核心函数 | 2-3小时 | 3.5小时 |
| 3. 编译 WASM | 5分钟 | 3.5小时 |
| 4. MoonBit FFI 绑定 | 1-2小时 | 5.5小时 |
| 5. 更新现有实现 | 30分钟 | 6小时 |
| 6. 测试验证 | 1-2小时 | 8小时 |
| **总计** | **~8小时** | **1天** |

---

## ✅ 优势

1. **立即可行** - 不需要等待 MoonBit FFI Ptr 支持
2. **成熟稳定** - k256 是广泛使用的库
3. **性能良好** - WASM 性能可接受
4. **快速交付** - 1天完成全部功能
5. **易于维护** - Rust 代码易于理解和修改

---

## 🎯 成功标准

完成后应该能够：

```moonbit
// 1. 生成密钥对
let private_key = generate_private_key()?
let public_key = derive_public_key(private_key)?

// 2. 签名
let message = "Hello Ethereum"
let hash = keccak256(message.to_bytes())
let signature = sign(hash, private_key)?

// 3. 验证
assert!(verify(hash, signature, public_key))

// 4. 恢复公钥
let recovered = recover_public_key(hash, signature)?
assert_eq!(recovered, public_key)

// 5. 获取以太坊地址
let address = public_key_to_ethereum_address(public_key)?
println("Address: \{to_checksum_address(address)}")
```

---

## 🚀 立即开始？

运行以下命令开始：

```bash
cd /home/pingguomiaomiao/Desktop/Lunarcrypto
mkdir secp256k1-wasm
cd secp256k1-wasm
cargo init --lib

# 然后告诉我，我会创建完整的实现！
```

准备好了吗？ 🎉

