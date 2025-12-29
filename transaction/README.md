# Transaction 模块

以太坊交易类型实现模块。

## 状态

🚧 **开发中** - 基础结构已创建

## 当前进度

### ✅ 已完成

- [x] 创建 `transaction/` 目录
- [x] 基础类型定义 (`types.mbt`)
  - `TransactionError` - 交易错误类型
  - `Address` - 以太坊地址类型（20 字节）
  - `TransactionType` - 交易类型枚举
- [x] Legacy 交易类型定义 (`legacy.mbt`)
  - `LegacyTransaction` 结构体
  - EIP-155 v 值计算函数
- [x] RLP 编码框架 (`encode.mbt`)
  - `encode_legacy_transaction()` - 编码已签名交易
  - `encode_unsigned_legacy_transaction()` - 编码未签名交易（EIP-155）
- [x] 交易哈希框架 (`hash.mbt`)
  - `legacy_transaction_hash()` - 计算交易哈希
- [x] 交易签名框架 (`sign.mbt`)
  - `sign_legacy_transaction()` - 签名交易

### ⏳ 待完成

- [ ] 修复模块导入（需要添加 RLP 和 ECDSA 依赖）
- [ ] 集成 Keccak256 哈希函数
- [ ] 集成 ECDSA 签名函数
- [ ] 实现完整的签名流程
- [ ] 编写单元测试
- [ ] 与 go-ethereum 兼容性测试

## 模块结构

```
transaction/
├── types.mbt          ✅ 基础类型定义
├── legacy.mbt         ✅ Legacy 交易类型
├── encode.mbt         ✅ RLP 编码（待修复导入）
├── hash.mbt           ✅ 交易哈希（待集成 Keccak256）
├── sign.mbt           ✅ 交易签名（待集成 ECDSA）
├── moon.pkg.json      ✅ 包配置
└── README.md          ✅ 本文档
```

## 下一步

1. **修复导入问题**
   - 在 `moon.pkg.json` 中添加 RLP 和 ECDSA 模块依赖
   - 或者使用相对路径导入

2. **集成依赖**
   - 集成 `LunarKeccak256` 用于交易哈希
   - 集成 `ecdsa` 模块用于交易签名

3. **完善实现**
   - 完成签名流程
   - 添加错误处理
   - 编写测试

## 使用示例（计划中）

```moonbit
// 创建未签名交易
let tx = LegacyTransaction::new(
  nonce: 0UL,
  gas_price: 20000000000UL,
  gas_limit: 21000UL,
  to: Some(recipient_address),
  value: 1000000000000000000UL,  // 1 ETH
  data: FixedArray::make(0, b'\x00')
)

// 签名交易
let signed_tx = sign_legacy_transaction(tx, private_key, 1UL)?  // chain_id = 1

// 编码交易
let raw_tx = encode_legacy_transaction(signed_tx)
```

