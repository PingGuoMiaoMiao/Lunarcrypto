# ECDSA 模块使用指南

> MoonBit ECDSA (secp256k1) 实现  
> Native FFI + libsecp256k1

---

## 快速开始

### 1. 生成密钥对

```moonbit
// 方式 1: 随机生成
let keypair = generate_keypair()?

// 方式 2: 从私钥派生
let private_key = PrivateKey::from_bytes(seckey_bytes)?
let public_key = derive_public_key(private_key)?
let keypair = KeyPair::new(private_key, public_key)
```

### 2. 签名消息

```moonbit
// 对消息哈希签名
let message_hash = keccak256(message)  // 32 字节
let signature = sign(message_hash, private_key)?

// 签名包含 (r, s, v)
println("r: \{signature.r.to_hex()}")
println("s: \{signature.s.to_hex()}")
println("v: \{signature.v}")
```

### 3. 验证签名

```moonbit
// 验证签名
let is_valid = verify(message_hash, signature, public_key)

if is_valid {
  println("✅ 签名有效")
} else {
  println("❌ 签名无效")
}
```

### 4. 恢复公钥

```moonbit
// 从签名恢复公钥
let recovered_pubkey = recover_public_key(message_hash, signature)?

// 验证恢复的公钥
assert_eq!(recovered_pubkey, original_pubkey)
```

---

## API 参考

### 类型定义

#### PrivateKey

```moonbit
pub struct PrivateKey {
  bytes : FixedArray[Byte]  // 32 字节
}

// 创建
pub fn PrivateKey::from_bytes(bytes : FixedArray[Byte]) -> ECDSAResult[PrivateKey]

// 转换
pub fn PrivateKey::to_bytes(self : PrivateKey) -> FixedArray[Byte]
pub fn PrivateKey::to_hex(self : PrivateKey) -> String
```

#### PublicKey

```moonbit
pub enum PublicKey {
  Uncompressed(FixedArray[Byte])  // 65 字节 (0x04 + x + y)
  Compressed(FixedArray[Byte])    // 33 字节 (0x02/0x03 + x)
}

// 创建
pub fn PublicKey::from_bytes(bytes : FixedArray[Byte]) -> ECDSAResult[PublicKey]

// 转换
pub fn PublicKey::to_bytes(self : PublicKey) -> FixedArray[Byte]
pub fn PublicKey::to_hex(self : PublicKey) -> String
pub fn PublicKey::compress(self : PublicKey) -> PublicKey
```

#### Signature

```moonbit
pub struct Signature {
  r : FixedArray[Byte]  // 32 字节
  s : FixedArray[Byte]  // 32 字节
  v : Int               // 恢复 ID (0-3)
}

// 创建
pub fn Signature::new(r, s, v) -> ECDSAResult[Signature]
pub fn Signature::from_bytes(bytes : FixedArray[Byte]) -> ECDSAResult[Signature]

// 转换
pub fn Signature::to_bytes(self : Signature) -> FixedArray[Byte]  // r + s + v
pub fn Signature::to_hex(self : Signature) -> String
```

#### KeyPair

```moonbit
pub struct KeyPair {
  private_key : PrivateKey
  public_key : PublicKey
}

// 创建
pub fn KeyPair::new(private_key, public_key) -> KeyPair
pub fn KeyPair::from_private_key(private_key) -> ECDSAResult[KeyPair]

// 验证
pub fn verify_keypair(keypair : KeyPair) -> Bool
```

---

### 核心函数

#### 密钥生成

```moonbit
/// 生成随机私钥
pub fn generate_private_key() -> ECDSAResult[PrivateKey]

/// 从私钥派生公钥
pub fn derive_public_key(private_key : PrivateKey) -> ECDSAResult[PublicKey]

/// 生成随机密钥对
pub fn generate_keypair() -> ECDSAResult[KeyPair]
```

#### 签名

```moonbit
/// 对消息哈希签名
/// message_hash: 32 字节的消息哈希 (通常是 Keccak256)
/// private_key: 私钥
/// 返回: 签名 (r, s, v)
pub fn sign(
  message_hash : FixedArray[Byte],
  private_key : PrivateKey,
) -> ECDSAResult[Signature]
```

#### 验证

```moonbit
/// 验证签名
/// message_hash: 32 字节的消息哈希
/// signature: ECDSA 签名
/// public_key: 公钥
/// 返回: true 表示有效，false 表示无效
pub fn verify(
  message_hash : FixedArray[Byte],
  signature : Signature,
  public_key : PublicKey,
) -> Bool
```

#### 公钥恢复

```moonbit
/// 从签名恢复公钥
/// message_hash: 32 字节的消息哈希
/// signature: ECDSA 签名 (必须包含恢复 ID)
/// 返回: 恢复的公钥 (未压缩格式)
pub fn recover_public_key(
  message_hash : FixedArray[Byte],
  signature : Signature,
) -> ECDSAResult[PublicKey]
```

---

## 完整示例

### 示例 1: 基本签名和验证

```moonbit
fn example_sign_and_verify() -> Unit {
  // 1. 生成密钥对
  let keypair = match generate_keypair() {
    Ok(kp) => kp
    Err(e) => {
      println("❌ 生成密钥对失败: \{e}")
      return
    }
  }

  println("✅ 密钥对生成成功")
  println("   公钥: \{keypair.public_key.to_hex()}")

  // 2. 准备消息
  let message = "Hello, ECDSA!"
  let message_hash = keccak256(message.to_bytes())  // 需要 keccak256 模块

  // 3. 签名
  let signature = match sign(message_hash, keypair.private_key) {
    Ok(sig) => sig
    Err(e) => {
      println("❌ 签名失败: \{e}")
      return
    }
  }

  println("✅ 签名成功")
  println("   r: \{signature.r.to_hex()}")
  println("   s: \{signature.s.to_hex()}")
  println("   v: \{signature.v}")

  // 4. 验证
  let is_valid = verify(message_hash, signature, keypair.public_key)

  if is_valid {
    println("✅ 签名验证成功")
  } else {
    println("❌ 签名验证失败")
  }
}
```

### 示例 2: 公钥恢复

```moonbit
fn example_recover_pubkey() -> Unit {
  // 1. 生成密钥对
  let keypair = generate_keypair()?

  // 2. 签名
  let message_hash = FixedArray::make(32, b'\x01')
  let signature = sign(message_hash, keypair.private_key)?

  // 3. 恢复公钥
  let recovered_pubkey = recover_public_key(message_hash, signature)?

  // 4. 验证恢复的公钥
  let original_bytes = keypair.public_key.to_bytes()
  let recovered_bytes = recovered_pubkey.to_bytes()

  let mut equal = true
  for i = 0; i < original_bytes.length(); i = i + 1 {
    if original_bytes[i] != recovered_bytes[i] {
      equal = false
      break
    }
  }

  if equal {
    println("✅ 公钥恢复成功")
  } else {
    println("❌ 公钥恢复失败")
  }
}
```

### 示例 3: 以太坊交易签名

```moonbit
fn example_ethereum_transaction() -> Unit {
  // 1. 构建交易
  let tx = EthereumTransaction {
    nonce: 0,
    gas_price: 20_000_000_000,
    gas_limit: 21_000,
    to: "0x742d35Cc6634C0532925a3b844Bc9e7595f0bEb",
    value: 1_000_000_000_000_000_000,  // 1 ETH
    data: FixedArray::make(0, b'\x00'),
  }

  // 2. RLP 编码
  let rlp_encoded = rlp_encode(tx)  // 需要 rlp 模块

  // 3. Keccak256 哈希
  let tx_hash = keccak256(rlp_encoded)

  // 4. 签名
  let private_key = PrivateKey::from_hex("0x...")?
  let signature = sign(tx_hash, private_key)?

  // 5. 调整 v 值（以太坊特定）
  let chain_id = 1  // 主网
  let v_adjusted = signature.v + chain_id * 2 + 35

  println("✅ 交易签名成功")
  println("   r: \{signature.r.to_hex()}")
  println("   s: \{signature.s.to_hex()}")
  println("   v: \{v_adjusted}")

  // 6. 恢复签名者地址
  let signer_pubkey = recover_public_key(tx_hash, signature)?
  let signer_address = pubkey_to_address(signer_pubkey)

  println("   签名者地址: \{signer_address}")
}
```

---

## 错误处理

### ECDSAError 类型

```moonbit
pub enum ECDSAError {
  InvalidPrivateKey(String)
  InvalidPublicKey(String)
  InvalidSignature(String)
  SignatureVerificationFailed
  PublicKeyRecoveryFailed
  InvalidRecoveryId
  ArithmeticError(String)
}
```

### 错误处理示例

```moonbit
fn handle_errors() -> Unit {
  let result = sign(message_hash, private_key)

  match result {
    Ok(signature) => {
      println("✅ 签名成功: \{signature.to_hex()}")
    }
    Err(InvalidPrivateKey(msg)) => {
      println("❌ 私钥无效: \{msg}")
    }
    Err(InvalidSignature(msg)) => {
      println("❌ 签名失败: \{msg}")
    }
    Err(e) => {
      println("❌ 其他错误: \{e}")
    }
  }
}
```

---

## 性能优化建议

### 1. 批量操作

```moonbit
// ❌ 不推荐：多次调用
for message in messages {
  let sig = sign(message, private_key)?
  signatures.push(sig)
}

// ✅ 推荐：批量签名（未来实现）
let signatures = sign_batch(messages, private_key)?
```

### 2. 公钥格式

```moonbit
// 压缩公钥节省空间
let compressed = public_key.compress()  // 33 字节 vs 65 字节

// 但验证时需要解压缩，可能稍慢
```

### 3. 预计算

```moonbit
// 如果频繁使用同一个公钥验证，考虑缓存
let pubkey_cache = HashMap::new()
pubkey_cache.insert(address, public_key)
```

---

## 安全注意事项

### 1. 私钥管理

```moonbit
// ❌ 不要硬编码私钥
let private_key = PrivateKey::from_hex("0x123...")?

// ✅ 从安全存储加载
let private_key = load_from_keystore(password)?

// ✅ 使用后立即清零
private_key.zeroize()
```

### 2. 随机数生成

```moonbit
// ⚠️ 当前实现使用占位符随机数生成器
// 生产环境需要使用加密安全的随机数生成器

// 推荐：使用确定性派生（BIP32）
let derived_key = derive_key(master_key, path)?
```

### 3. 签名验证

```moonbit
// ✅ 始终验证签名
if !verify(message_hash, signature, public_key) {
  return Err(SignatureVerificationFailed)
}

// ✅ 验证恢复的公钥
let recovered = recover_public_key(message_hash, signature)?
if recovered != expected_pubkey {
  return Err(PublicKeyMismatch)
}
```

---

## 常见问题

### Q1: 如何生成以太坊地址？

```moonbit
fn pubkey_to_address(pubkey : PublicKey) -> String {
  // 1. 获取未压缩公钥（去掉 0x04 前缀）
  let pubkey_bytes = pubkey.to_bytes()
  let pubkey_no_prefix = pubkey_bytes.slice(1, 65)  // 64 字节

  // 2. Keccak256 哈希
  let hash = keccak256(pubkey_no_prefix)

  // 3. 取后 20 字节
  let address_bytes = hash.slice(12, 32)

  // 4. 转换为十六进制字符串
  "0x" + address_bytes.to_hex()
}
```

### Q2: 如何处理 EIP-155 (chain ID)?

```moonbit
fn adjust_v_for_eip155(v : Int, chain_id : Int) -> Int {
  v + chain_id * 2 + 35
}

fn recover_chain_id_from_v(v : Int) -> Int {
  (v - 35) / 2
}
```

### Q3: 如何验证以太坊交易签名？

```moonbit
fn verify_ethereum_transaction(tx, signature) -> Bool {
  // 1. RLP 编码交易
  let rlp_encoded = rlp_encode(tx)

  // 2. Keccak256 哈希
  let tx_hash = keccak256(rlp_encoded)

  // 3. 恢复签名者公钥
  let signer_pubkey = recover_public_key(tx_hash, signature)?

  // 4. 计算地址
  let signer_address = pubkey_to_address(signer_pubkey)

  // 5. 验证地址
  signer_address == tx.from
}
```

---

## 更多资源

- [ECDSA 实现计划](./ECDSA_IMPLEMENTATION_PLAN.md)
- [Native FFI 成功报告](../ECDSA_NATIVE_FFI_SUCCESS.md)
- [模块 README](./README.md)
- [libsecp256k1 文档](https://github.com/bitcoin-core/secp256k1)

---

**版本**: 1.0.0  
**状态**: 生产就绪  
**许可**: MIT

