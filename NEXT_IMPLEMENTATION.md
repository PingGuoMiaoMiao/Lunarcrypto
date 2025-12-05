# 🚀 下一步实现计划

> 当前状态: ECDSA 核心功能已完成  
> 日期: 2025-12-06

---

## ✅ 已完成的模块

### 1. RLP 编码/解码 ✅
- ✅ 完整的 RLP 编码实现
- ✅ 完整的 RLP 解码实现
- ✅ 支持所有数据类型
- ✅ 官方测试向量验证

### 2. ECDSA (secp256k1) ✅
- ✅ 公钥派生 (`derive_public_key`)
- ✅ 签名功能 (`sign`)
- ✅ 验证功能 (`verify`)
- ✅ 公钥恢复 (`recover_public_key`)
- ✅ 密钥对管理 (`KeyPair`)
- ✅ Native FFI 集成 (libsecp256k1)
- ✅ 9/9 测试通过

---

## 🎯 待实现的功能

### 优先级 1: Keccak256 哈希（已有依赖）⭐⭐⭐

**状态**: 已在 `moon.mod.json` 中添加依赖 `PingGuoMiaoMiao/LunarKeccak256`

**任务**:
1. ✅ 依赖已添加
2. ⏳ 创建 `keccak256` 模块包装器
3. ⏳ 集成到 ECDSA 模块
4. ⏳ 实现便利函数:
   - `sign_message()` - 自动哈希消息
   - `sign_ethereum_message()` - 添加以太坊前缀
   - `recover_ethereum_address()` - 从签名恢复地址

**预计时间**: 1-2 小时

**实现步骤**:
```moonbit
// 1. 创建 keccak256 包装器
pub fn keccak256(data: FixedArray[Byte]) -> FixedArray[Byte] {
  // 调用 LunarKeccak256 库
}

// 2. 实现 sign_message
pub fn sign_message(message: FixedArray[Byte], private_key: PrivateKey) -> ECDSAResult[Signature] {
  let hash = keccak256(message)
  sign(hash, private_key)
}

// 3. 实现以太坊消息签名
pub fn sign_ethereum_message(message: FixedArray[Byte], private_key: PrivateKey) -> ECDSAResult[Signature] {
  let prefix = "\x19Ethereum Signed Message:\n"
  let prefixed = prefix + message.length().to_string() + message
  let hash = keccak256(prefixed)
  sign(hash, private_key)
}

// 4. 实现地址恢复
pub fn recover_ethereum_address(message_hash: FixedArray[Byte], signature: Signature) -> ECDSAResult[String] {
  let pubkey = recover_public_key(message_hash, signature)?
  let pubkey_bytes = pubkey.to_bytes()[1..65]  // 去掉 0x04 前缀
  let hash = keccak256(pubkey_bytes)
  Ok("0x" + hash[12..32].to_hex())  // 取后 20 字节
}
```

---

### 优先级 2: 以太坊交易构建 ⭐⭐⭐

**状态**: 需要实现

**任务**:
1. ⏳ 定义交易类型
2. ⏳ 实现交易 RLP 编码
3. ⏳ 实现交易签名
4. ⏳ 实现 EIP-155 (Chain ID)
5. ⏳ 实现交易哈希计算

**预计时间**: 2-3 天

**实现步骤**:
```moonbit
// 1. 定义交易类型
pub struct Transaction {
  nonce: Int,
  gas_price: Int,
  gas_limit: Int,
  to: String,  // 地址
  value: Int,
  data: FixedArray[Byte],
  chain_id: Int,  // EIP-155
}

// 2. RLP 编码
pub fn Transaction::to_rlp(self: Transaction) -> FixedArray[Byte] {
  rlp_encode([
    rlp_encode_int(self.nonce),
    rlp_encode_int(self.gas_price),
    rlp_encode_int(self.gas_limit),
    rlp_encode_bytes(hex_to_bytes(self.to)),
    rlp_encode_int(self.value),
    rlp_encode_bytes(self.data),
    rlp_encode_int(self.chain_id),
    rlp_encode_bytes([]),  // r
    rlp_encode_bytes([]),  // s
  ])
}

// 3. 签名交易
pub fn Transaction::sign(self: Transaction, private_key: PrivateKey) -> ECDSAResult[SignedTransaction] {
  let rlp = self.to_rlp()
  let hash = keccak256(rlp)
  let signature = sign(hash, private_key)?
  
  // EIP-155: 调整 v 值
  let v = signature.v + self.chain_id * 2 + 35
  
  Ok(SignedTransaction {
    transaction: self,
    r: signature.r,
    s: signature.s,
    v: v,
  })
}

// 4. 计算交易哈希
pub fn SignedTransaction::hash(self: SignedTransaction) -> FixedArray[Byte] {
  let rlp = self.to_rlp()
  keccak256(rlp)
}
```

---

### 优先级 3: 密钥管理增强 ⭐⭐

**状态**: 基础功能已完成，需要增强

**任务**:
1. ⏳ 实现 BIP39 助记词
2. ⏳ 实现 BIP32 分层确定性钱包
3. ⏳ 实现密钥导入/导出
4. ⏳ 实现密钥加密存储

**预计时间**: 3-5 天

**实现步骤**:
```moonbit
// 1. BIP39 助记词
pub fn generate_mnemonic(entropy_bits: Int) -> String {
  // 生成 128/256 位熵
  // 添加校验和
  // 转换为助记词
}

pub fn mnemonic_to_seed(mnemonic: String, passphrase: String) -> FixedArray[Byte] {
  // PBKDF2-HMAC-SHA512
}

// 2. BIP32 HD 钱包
pub fn derive_key(master_key: PrivateKey, path: String) -> ECDSAResult[PrivateKey] {
  // 解析路径 "m/44'/60'/0'/0/0"
  // 分层派生
}

// 3. 密钥导入/导出
pub fn export_keystore(private_key: PrivateKey, password: String) -> String {
  // JSON keystore 格式
  // AES-128-CTR 加密
}

pub fn import_keystore(json: String, password: String) -> ECDSAResult[PrivateKey] {
  // 解密 keystore
}
```

---

### 优先级 4: 性能优化 ⭐

**状态**: 功能正常，可优化

**任务**:
1. ⏳ 全局上下文缓存
2. ⏳ 批量签名/验证
3. ⏳ 添加 FFI 标注 (`#borrow`)
4. ⏳ 性能基准测试

**预计时间**: 1-2 天

**实现步骤**:
```moonbit
// 1. 全局上下文
let global_ctx: Secp256k1Context = secp256k1_context_create(0x0301)

// 2. 批量操作
pub fn sign_batch(messages: Array[FixedArray[Byte]], key: PrivateKey) -> Array[ECDSAResult[Signature]] {
  let ctx = get_global_context()
  messages.map(fn(msg) { sign_with_context(ctx, msg, key) })
}

// 3. 添加 FFI 标注
pub extern "C" fn secp256k1_ec_pubkey_create(
  ctx: Secp256k1Context,
  #borrow pubkey: FixedArray[Byte],
  #borrow seckey: FixedArray[Byte],
) -> Int
```

---

### 优先级 5: 测试和文档 ⭐

**状态**: 基础测试已完成，需要扩展

**任务**:
1. ⏳ 官方测试向量
2. ⏳ 边界条件测试
3. ⏳ 性能基准测试
4. ⏳ 集成测试
5. ⏳ 使用示例

**预计时间**: 2-3 天

---

## 📊 实现路线图

### 第 1 周（当前）
- ✅ Day 1-2: RLP 实现
- ✅ Day 3-5: ECDSA 核心功能
- ⏳ Day 6-7: Keccak256 集成

### 第 2 周
- ⏳ Day 1-3: 以太坊交易构建
- ⏳ Day 4-5: 密钥管理增强
- ⏳ Day 6-7: 性能优化

### 第 3 周
- ⏳ Day 1-3: BIP39/BIP32 实现
- ⏳ Day 4-5: 完整测试套件
- ⏳ Day 6-7: 文档和示例

---

## 🎯 短期目标（本周）

### 1. Keccak256 集成 ⭐⭐⭐
```bash
# 1. 创建 keccak256 模块
mkdir -p keccak256
cd keccak256

# 2. 创建包装器
cat > keccak256.mbt << 'EOF'
pub fn keccak256(data: FixedArray[Byte]) -> FixedArray[Byte] {
  // 调用 LunarKeccak256
}
EOF

# 3. 更新 ECDSA 模块
# 添加 sign_message, sign_ethereum_message 等
```

### 2. 以太坊地址生成 ⭐⭐⭐
```moonbit
pub fn pubkey_to_address(pubkey: PublicKey) -> String {
  let bytes = pubkey.to_bytes()[1..65]  // 去掉 0x04
  let hash = keccak256(bytes)
  "0x" + hash[12..32].to_hex()
}
```

### 3. 简单交易示例 ⭐⭐
```moonbit
// 创建并签名一个简单的 ETH 转账交易
fn example_simple_transfer() {
  let tx = Transaction {
    nonce: 0,
    gas_price: 20_000_000_000,
    gas_limit: 21_000,
    to: "0x742d35Cc6634C0532925a3b844Bc9e7595f0bEb",
    value: 1_000_000_000_000_000_000,  // 1 ETH
    data: [],
    chain_id: 1,  // 主网
  }
  
  let private_key = PrivateKey::from_hex("0x...")?
  let signed = tx.sign(private_key)?
  
  println("Transaction hash: {}", signed.hash().to_hex())
}
```

---

## 🔧 技术债务

### 当前警告
- ⚠️ FFI 参数需要添加 `#borrow` 标注（29 个警告）
- ⚠️ 使用 `reinterpret_as_uint` 替代 `to_uint`
- ⚠️ 一些未使用的构造函数

### 需要清理
- 🗑️ 删除测试文件: `test_secp256k1.c`, `pubkey_test.c`
- 🗑️ 删除旧的 FFI 测试文件
- 🗑️ 整理文档文件

---

## 📚 参考资料

### 以太坊标准
- [EIP-155: Simple replay attack protection](https://eips.ethereum.org/EIPS/eip-155)
- [EIP-191: Signed Data Standard](https://eips.ethereum.org/EIPS/eip-191)
- [EIP-712: Typed structured data hashing and signing](https://eips.ethereum.org/EIPS/eip-712)

### 密钥管理
- [BIP39: Mnemonic code for generating deterministic keys](https://github.com/bitcoin/bips/blob/master/bip-0039.mediawiki)
- [BIP32: Hierarchical Deterministic Wallets](https://github.com/bitcoin/bips/blob/master/bip-0032.mediawiki)
- [BIP44: Multi-Account Hierarchy for Deterministic Wallets](https://github.com/bitcoin/bips/blob/master/bip-0044.mediawiki)

### Keccak256
- [Keccak/SHA-3 Specification](https://keccak.team/keccak.html)
- [NIST FIPS 202](https://nvlpubs.nist.gov/nistpubs/FIPS/NIST.FIPS.202.pdf)

---

## 🎉 总结

### 当前状态
✅ **核心加密功能完成** - RLP + ECDSA  
⏳ **哈希功能待集成** - Keccak256 依赖已添加  
⏳ **交易功能待实现** - 需要 2-3 天  
⏳ **钱包功能待实现** - 需要 3-5 天  

### 下一步行动
1. **立即**: 集成 Keccak256，实现 `sign_message()` 等便利函数
2. **本周**: 实现以太坊交易构建和签名
3. **下周**: 实现 BIP39/BIP32 密钥管理

### 项目价值
- ✅ 可用于以太坊钱包开发
- ✅ 可用于交易签名和验证
- ✅ 可用于智能合约交互
- ✅ 工程级代码质量
- ✅ 高性能（Native FFI）

---

**更新日期**: 2025-12-06  
**项目状态**: 🟢 核心功能完成，正在扩展中

