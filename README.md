# 🌙 Lunarcrypto

> 用 MoonBit 写的以太坊加密工具库，还在努力建设中 🚧

## 这是什么？

一个想用 MoonBit 实现以太坊生态基础功能的项目。说白了就是：**我想在 MoonBit 里也能签名交易、生成地址、编码数据**。

目前的状态？**一半完成，一半在挖坑** 😅

## 现在能干什么？

### ✅ RLP 模块 - 这个真的做完了！

RLP（Recursive Length Prefix）编码/解码，以太坊用来序列化数据的格式。这个模块：

- ✅ 编码/解码都实现了
- ✅ 通过了各种测试
- ✅ 和 go-ethereum 兼容
- ✅ 代码量：~956 行

**能用吗？** 能！这个真的可以放心用。

```moonbit
// 编码
let data = rlp_list([
  rlp_string("cat"),
  rlp_list([rlp_string("dog"), rlp_string("fox")])
])
let encoded = encode(data)

// 解码
let decoded = decode(encoded)?
```

### 🚧 ECDSA 模块 - 框架搭好了，核心算法还没写

想实现 secp256k1 椭圆曲线签名，就是以太坊和比特币用的那个。

**现状：**
- ✅ 类型定义好了（PrivateKey, PublicKey, Signature）
- ✅ 曲线参数有了
- ✅ 框架代码写好了
- ❌ **但是！核心算法还没实现**（点运算、签名、验证）

**为什么没写完？** 因为实现椭圆曲线需要：
1. 大整数运算（256位以上）
2. 模运算优化
3. 椭圆曲线点运算
4. 防侧信道攻击

**选项：**
- 方案 A：FFI 调用 libsecp256k1（推荐，但需要验证 MoonBit FFI 支持）
- 方案 B：纯 MoonBit 实现（工作量巨大，6-8周）
- 方案 C：WASM 绑定（需要研究）

**完成度：** 大概 30% 吧，框架有了，核心算法还在纠结怎么实现。

### 🚧 Transaction 模块 - 刚起步

想实现以太坊交易签名。

**现状：**
- ✅ 类型定义有了
- ✅ Legacy 交易结构有了
- ✅ 编码框架有了
- ❌ 但是依赖 ECDSA 模块，所以...你懂的

**完成度：** 20%？可能更少。

### 🚧 Wallet 模块 - 有 BIP39 相关代码

BIP39 助记词相关的，但还没完整测试。

## 项目结构

```
Lunarcrypto/
├── rlp/          ✅ 完成（可以放心用）
├── ecdsa/        🚧 30% 完成（核心算法待实现）
├── transaction/  🚧 20% 完成（等 ECDSA）
├── wallet/       🚧 基础代码有了
└── cmd/main/     📝 空的，还没写示例
```

## 为什么做这个？

1. **想学 MoonBit** - 新语言，想试试
2. **想理解以太坊底层** - 从零实现一遍，理解更深
3. **可能有用** - 万一 MoonBit 生态需要呢？

## 实话实说

### 优点
- RLP 模块真的做完了，质量还可以
- 代码结构清晰，文档还算完整
- 有测试，不是玩具代码

### 缺点
- **核心功能（ECDSA）还没实现**，所以现在还不能签名交易
- 依赖关系没理清楚（transaction 依赖 ecdsa，但 ecdsa 还没做完）
- 没有实际使用案例（因为功能不完整）

### 下一步要做什么？

1. **决定 ECDSA 实现方案** - FFI 还是纯实现？这是个关键决策
2. **完成 ECDSA 核心算法** - 签名、验证、公钥恢复
3. **完善 Transaction 模块** - 能真正签名交易
4. **写个完整的示例** - 从生成密钥到签名交易

## 怎么用？

### 安装

```bash
# 需要 MoonBit 环境
moon --version  # 确保已安装

# 克隆项目
git clone https://github.com/PingGuoMiaoMiao/Lunarcrypto.git
cd Lunarcrypto

# 编译
moon build

# 运行测试
moon test
```

### 使用 RLP 模块（这个真的能用）

```moonbit
import rlp::{encode, decode, rlp_string, rlp_list}

fn main {
  let item = rlp_list([
    rlp_string("hello"),
    rlp_string("world")
  ])
  
  let encoded = encode(item)
  let decoded = decode(encoded)?
  
  inspect(decoded)
}
```

### 使用 ECDSA 模块（等做完再说）

```moonbit
// 现在还不能用，等我把核心算法写完 😅
// let keypair = generate_keypair()?
// let signature = sign(message_hash, private_key)?
```

## 开发状态

- **总代码量：** ~1,465 行
- **编译状态：** ✅ 通过（5 个警告，0 个错误）
- **测试覆盖：** RLP 模块完整，其他模块待补充
- **文档：** 有，但可能不够详细

## 贡献

欢迎贡献！但说实话，这个项目还在早期阶段，可能：

- 代码结构会变
- API 会改
- 实现方案会调整

如果你：
- 想帮忙实现 ECDSA（欢迎！）
- 发现 bug（欢迎提 issue！）
- 有更好的实现方案（欢迎讨论！）

都可以来！

## 参考资源

- [以太坊黄皮书](https://ethereum.github.io/yellowpaper/paper.pdf)
- [RLP 规范](https://ethereum.org/developers/docs/data-structures-and-encoding/rlp/)
- [libsecp256k1](https://github.com/bitcoin-core/secp256k1)
- [go-ethereum crypto](https://github.com/ethereum/go-ethereum/tree/master/crypto)

## 许可证

Apache-2.0

## 最后

这个项目还在建设中，**不要在生产环境用**（至少等 ECDSA 做完再说）。

如果你也在学 MoonBit 或者对以太坊底层感兴趣，欢迎一起玩！🎉

---

**项目状态：** 🚧 活跃开发中  
**最后更新：** 2025-12-05  
**维护者：** PingGuoMiaoMiao
