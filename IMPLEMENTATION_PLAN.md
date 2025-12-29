# 🚀 中期目标实现方案

## 📋 目标概述

实现 STATUS.md 第 371-381 行提到的功能：
1. **支持所有以太坊交易类型**
2. **完整的钱包功能**

---

## 🎯 第一部分：以太坊交易类型支持

### 1.1 Legacy 交易 (EIP-155)

**优先级**: ⭐⭐⭐ 最高  
**预计时间**: 1 周  
**依赖**: RLP ✅, ECDSA 🚧

#### 实现内容

```moonbit
// transaction/legacy.mbt
pub struct LegacyTransaction {
  nonce: UInt64
  gas_price: UInt64
  gas_limit: UInt64
  to: Option[FixedArray[Byte]]  // 20 bytes address or None for contract creation
  value: UInt64
  data: FixedArray[Byte]
  v: UInt64  // chain_id * 2 + 35/36
  r: FixedArray[Byte]  // 32 bytes
  s: FixedArray[Byte]  // 32 bytes
}

// RLP 编码
pub fn encode_legacy_transaction(tx: LegacyTransaction) -> FixedArray[Byte]

// 签名
pub fn sign_legacy_transaction(
  tx: LegacyTransaction,
  private_key: PrivateKey,
  chain_id: UInt64
) -> LegacyTransaction

// 交易哈希
pub fn legacy_transaction_hash(tx: LegacyTransaction, chain_id: UInt64) -> FixedArray[Byte]
```

#### 任务清单

- [ ] 创建 `transaction/` 目录
- [ ] 实现 `LegacyTransaction` 类型定义
- [ ] 实现 RLP 编码（使用现有 RLP 模块）
- [ ] 实现交易哈希计算（Keccak256）
- [ ] 实现 EIP-155 签名逻辑（v = chain_id * 2 + 35/36）
- [ ] 实现交易验证
- [ ] 编写单元测试
- [ ] 与 go-ethereum 兼容性测试

#### 参考资料

- [EIP-155](https://eips.ethereum.org/EIP-155)
- [go-ethereum types.Transaction](https://github.com/ethereum/go-ethereum/blob/master/core/types/transaction.go)

---

### 1.2 EIP-2930 (Access List) 交易

**优先级**: ⭐⭐ 中  
**预计时间**: 1 周  
**依赖**: Legacy 交易 ✅

#### 实现内容

```moonbit
// transaction/access_list.mbt
pub struct AccessTuple {
  address: FixedArray[Byte]  // 20 bytes
  storage_keys: Array[FixedArray[Byte]]  // 32 bytes each
}

pub struct AccessListTransaction {
  chain_id: UInt64
  nonce: UInt64
  gas_price: UInt64
  gas_limit: UInt64
  to: Option[FixedArray[Byte]]
  value: UInt64
  data: FixedArray[Byte]
  access_list: Array[AccessTuple]
  v: UInt64  // 0 or 1
  r: FixedArray[Byte]
  s: FixedArray[Byte]
}

// 交易类型标识: 0x01
pub fn encode_access_list_transaction(tx: AccessListTransaction) -> FixedArray[Byte]
pub fn sign_access_list_transaction(...) -> AccessListTransaction
```

#### 任务清单

- [ ] 实现 `AccessTuple` 和 `AccessListTransaction` 类型
- [ ] 实现 RLP 编码（交易类型前缀 0x01）
- [ ] 实现交易哈希（使用 EIP-2930 定义的哈希方式）
- [ ] 实现签名逻辑
- [ ] 编写单元测试

#### 参考资料

- [EIP-2930](https://eips.ethereum.org/EIP-2930)

---

### 1.3 EIP-1559 (Dynamic Fee) 交易

**优先级**: ⭐⭐⭐ 高  
**预计时间**: 1.5 周  
**依赖**: EIP-2930 ✅

#### 实现内容

```moonbit
// transaction/eip1559.mbt
pub struct EIP1559Transaction {
  chain_id: UInt64
  nonce: UInt64
  max_priority_fee_per_gas: UInt64  // tip
  max_fee_per_gas: UInt64  // base + tip
  gas_limit: UInt64
  to: Option[FixedArray[Byte]]
  value: UInt64
  data: FixedArray[Byte]
  access_list: Array[AccessTuple]
  v: UInt64  // 0 or 1
  r: FixedArray[Byte]
  s: FixedArray[Byte]
}

// 交易类型标识: 0x02
pub fn encode_eip1559_transaction(tx: EIP1559Transaction) -> FixedArray[Byte]
pub fn sign_eip1559_transaction(...) -> EIP1559Transaction
```

#### 任务清单

- [ ] 实现 `EIP1559Transaction` 类型
- [ ] 实现 RLP 编码（交易类型前缀 0x02）
- [ ] 实现交易哈希计算
- [ ] 实现签名逻辑
- [ ] Gas 费用计算辅助函数
- [ ] 编写单元测试

#### 参考资料

- [EIP-1559](https://eips.ethereum.org/EIP-1559)

---

### 1.4 EIP-4844 (Blob) 交易

**优先级**: ⭐ 低（最新功能）  
**预计时间**: 2 周  
**依赖**: EIP-1559 ✅

#### 实现内容

```moonbit
// transaction/eip4844.mbt
pub struct Blob {
  data: FixedArray[Byte]  // 131072 bytes (4096 * 32)
}

pub struct EIP4844Transaction {
  chain_id: UInt64
  nonce: UInt64
  max_priority_fee_per_gas: UInt64
  max_fee_per_gas: UInt64
  gas_limit: UInt64
  to: Option[FixedArray[Byte]]
  value: UInt64
  data: FixedArray[Byte]
  access_list: Array[AccessTuple]
  max_fee_per_blob_gas: UInt64
  blob_versioned_hashes: Array[FixedArray[Byte]]  // 32 bytes each
  v: UInt64
  r: FixedArray[Byte]
  s: FixedArray[Byte]
  // Sidecar: blobs, commitments, proofs
}

// 交易类型标识: 0x03
pub fn encode_eip4844_transaction(tx: EIP4844Transaction) -> FixedArray[Byte]
```

#### 任务清单

- [ ] 研究 EIP-4844 KZG 承诺机制
- [ ] 实现 `EIP4844Transaction` 类型
- [ ] 实现 Blob 数据处理
- [ ] 实现 KZG 承诺和证明（可能需要 FFI）
- [ ] 实现 RLP 编码
- [ ] 实现交易哈希计算
- [ ] 编写单元测试

#### 参考资料

- [EIP-4844](https://eips.ethereum.org/EIP-4844)

---

## 🎯 第二部分：钱包功能

### 2.1 BIP39 助记词

**优先级**: ⭐⭐⭐ 最高  
**预计时间**: 1 周  
**依赖**: 随机数生成 ✅

#### 实现内容

```moonbit
// wallet/bip39.mbt
pub enum WordList {
  English
  ChineseSimplified
  ChineseTraditional
  // ... 其他语言
}

// 生成助记词
pub fn generate_mnemonic(
  entropy_bits: Int,  // 128, 160, 192, 224, 256
  word_list: WordList
) -> Array[String]

// 助记词到种子
pub fn mnemonic_to_seed(
  mnemonic: Array[String],
  passphrase: String
) -> FixedArray[Byte]  // 64 bytes

// 验证助记词
pub fn validate_mnemonic(
  mnemonic: Array[String],
  word_list: WordList
) -> Bool

// 助记词到熵
pub fn mnemonic_to_entropy(
  mnemonic: Array[String],
  word_list: WordList
) -> Result[FixedArray[Byte], BIP39Error]
```

#### 任务清单

- [ ] 创建 `wallet/` 目录
- [ ] 集成 BIP39 单词列表（至少英文 2048 词）
- [ ] 实现熵生成（使用 CSPRNG）
- [ ] 实现校验和计算（SHA256）
- [ ] 实现助记词生成
- [ ] 实现 PBKDF2（用于助记词到种子）
- [ ] 实现助记词验证
- [ ] 支持多语言单词列表
- [ ] 编写单元测试

#### 参考资料

- [BIP39](https://github.com/bitcoin/bips/blob/master/bip-0039.mediawiki)
- [BIP39 单词列表](https://github.com/bitcoin/bips/blob/master/bip-0039/bip-0039-wordlists.md)

---

### 2.2 BIP32 HD 钱包

**优先级**: ⭐⭐⭐ 高  
**预计时间**: 1.5 周  
**依赖**: BIP39 ✅, HMAC-SHA512 ✅

#### 实现内容

```moonbit
// wallet/bip32.mbt
pub struct ExtendedKey {
  depth: Byte
  parent_fingerprint: FixedArray[Byte]  // 4 bytes
  child_number: UInt32
  chain_code: FixedArray[Byte]  // 32 bytes
  key: FixedArray[Byte]  // 33 bytes (public) or 32 bytes (private)
  is_private: Bool
}

// 从种子派生主密钥
pub fn master_key_from_seed(seed: FixedArray[Byte]) -> Result[ExtendedKey, BIP32Error]

// 派生子密钥
pub fn derive_child_key(
  parent: ExtendedKey,
  index: UInt32,
  hardened: Bool
) -> Result[ExtendedKey, BIP32Error]

// 路径派生
pub fn derive_path(
  master: ExtendedKey,
  path: String  // e.g., "m/44'/60'/0'/0/0"
) -> Result[ExtendedKey, BIP32Error]

// 扩展私钥/公钥序列化
pub fn extended_key_to_base58(key: ExtendedKey) -> String
pub fn base58_to_extended_key(encoded: String) -> Result[ExtendedKey, BIP32Error]
```

#### 任务清单

- [ ] 实现 HMAC-SHA512
- [ ] 实现 `ExtendedKey` 类型
- [ ] 实现主密钥派生（HMAC-SHA512）
- [ ] 实现子密钥派生（正常和硬化）
- [ ] 实现路径解析和派生
- [ ] 实现 Base58 编码/解码
- [ ] 实现扩展密钥序列化（BIP32 格式）
- [ ] 编写单元测试

#### 参考资料

- [BIP32](https://github.com/bitcoin/bips/blob/master/bip-0032.mediawiki)

---

### 2.3 BIP44 路径派生

**优先级**: ⭐⭐ 中（基于 BIP32）  
**预计时间**: 3-5 天  
**依赖**: BIP32 ✅

#### 实现内容

```moonbit
// wallet/bip44.mbt
pub struct BIP44Path {
  purpose: UInt32    // 44'
  coin_type: UInt32  // 60' for Ethereum
  account: UInt32    // 0'
  change: UInt32     // 0 (external) or 1 (internal)
  address_index: UInt32  // 0, 1, 2, ...
}

// 构建 BIP44 路径
pub fn build_bip44_path(
  coin_type: UInt32,  // 60 for Ethereum
  account: UInt32,
  change: UInt32,
  address_index: UInt32
) -> BIP44Path

// 从主密钥派生 BIP44 密钥
pub fn derive_bip44_key(
  master_key: ExtendedKey,
  path: BIP44Path
) -> Result[ExtendedKey, BIP32Error]

// 便捷函数：从助记词派生以太坊密钥
pub fn derive_ethereum_key_from_mnemonic(
  mnemonic: Array[String],
  passphrase: String,
  account: UInt32,
  address_index: UInt32
) -> Result[PrivateKey, WalletError]
```

#### 任务清单

- [ ] 实现 `BIP44Path` 类型
- [ ] 实现路径构建函数
- [ ] 实现便捷派生函数
- [ ] 支持常用币种（Ethereum, Bitcoin 等）
- [ ] 编写单元测试

#### 参考资料

- [BIP44](https://github.com/bitcoin/bips/blob/master/bip-0044.mediawiki)

---

## 📦 模块结构

```
Lunarcrypto/
├── transaction/
│   ├── types.mbt           # 通用交易类型
│   ├── legacy.mbt          # Legacy 交易
│   ├── access_list.mbt     # EIP-2930
│   ├── eip1559.mbt         # EIP-1559
│   ├── eip4844.mbt         # EIP-4844
│   ├── encode.mbt          # 交易编码
│   ├── sign.mbt            # 交易签名
│   └── moon.pkg.json
│
├── wallet/
│   ├── types.mbt           # 钱包类型定义
│   ├── bip39.mbt           # BIP39 助记词
│   ├── bip32.mbt           # BIP32 HD 钱包
│   ├── bip44.mbt           # BIP44 路径
│   ├── wordlists/
│   │   ├── english.mbt
│   │   ├── chinese_simplified.mbt
│   │   └── ...
│   └── moon.pkg.json
│
└── crypto/
    ├── pbkdf2.mbt          # PBKDF2 (BIP39 需要)
    ├── hmac.mbt            # HMAC-SHA512 (BIP32 需要)
    └── base58.mbt          # Base58 编码 (BIP32 需要)
```

---

## 📅 时间估算

| 模块 | 预计时间 | 累计时间 |
|------|---------|---------|
| Legacy 交易 | 1 周 | 1 周 |
| EIP-2930 交易 | 1 周 | 2 周 |
| EIP-1559 交易 | 1.5 周 | 3.5 周 |
| EIP-4844 交易 | 2 周 | 5.5 周 |
| BIP39 助记词 | 1 周 | 6.5 周 |
| BIP32 HD 钱包 | 1.5 周 | 8 周 |
| BIP44 路径 | 0.5 周 | 8.5 周 |
| **总计** | **~8.5 周** | **约 2 个月** |

---

## 🔗 依赖关系

### 需要新增的依赖

1. **PBKDF2** - 用于 BIP39 助记词到种子转换
2. **HMAC-SHA512** - 用于 BIP32 密钥派生
3. **Base58** - 用于 BIP32 扩展密钥序列化
4. **KZG 库** - 用于 EIP-4844（可能需要 FFI）

### 现有依赖

- ✅ RLP 模块（交易编码）
- 🚧 ECDSA 模块（交易签名）
- ✅ Keccak256（交易哈希）

---

## ✅ 验收标准

### 交易类型

- [ ] 可以编码所有交易类型为 RLP
- [ ] 可以签名所有交易类型
- [ ] 交易哈希与 go-ethereum 一致
- [ ] 可以与以太坊节点交互

### 钱包功能

- [ ] 可以生成符合 BIP39 标准的助记词
- [ ] 可以从助记词恢复私钥
- [ ] 可以派生 BIP32 子密钥
- [ ] 可以派生 BIP44 路径密钥
- [ ] 与 MetaMask/其他钱包兼容

---

## 🚀 开始实施

建议实施顺序：

1. **Phase 1** (3 周): Legacy 交易 + BIP39 + BIP32 基础
2. **Phase 2** (2 周): EIP-1559 交易 + BIP44
3. **Phase 3** (2 周): EIP-2930 + EIP-4844
4. **Phase 4** (1 周): 集成测试和文档

