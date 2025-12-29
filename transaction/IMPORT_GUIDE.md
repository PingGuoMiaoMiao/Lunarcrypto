# Transaction 模块导入指南

## 📚 基于 MoonBit 官方文档的导入方式

根据 [MoonBit 包管理文档](https://docs.moonbitlang.cn/language/packages.html)，以下是正确的包导入和使用方式：

## ✅ 已完成的配置

### 1. 包依赖声明 (`moon.pkg.json`)

```json
{
  "is_main": false,
  "import": [
    "PingGuoMiaoMiao/Lunarcrypto/rlp",
    "PingGuoMiaoMiao/Lunarcrypto/ecdsa"
  ]
}
```

✅ **已正确配置** - 在 `moon.pkg.json` 中声明了依赖

## 🔍 导入机制说明

根据 MoonBit 文档：
1. **包依赖声明**: 在 `moon.pkg.json` 的 `import` 字段中声明
2. **自动导入**: 声明后，包中所有 `pub` 类型和函数自动可用
3. **无需显式导入语句**: MoonBit 没有 `import` 或 `using` 关键字

## 🎯 使用方式

### 方式 1: 直接使用（推荐）

如果包中导出的类型/函数名称唯一，可以直接使用：

```moonbit
// 直接使用 RLPItem 类型
let item : RLPItem = RLPItem::Bytes(data)

// 直接使用 encode 函数
let encoded = encode(item)
```

### 方式 2: 使用完整包路径（如果存在命名冲突）

如果存在命名冲突，可能需要使用完整包路径：

```moonbit
// 使用完整包路径（需要确认语法）
let item : PingGuoMiaoMiao.Lunarcrypto.rlp.RLPItem = ...
```

## ⚠️ 当前问题

### 问题 1: 类型无法识别

**现象**: 
- 编译器报告 "The type RLPItem is undefined"
- 但 `moon.pkg.json` 中已正确声明依赖

**可能原因**:
1. MoonBit 对同一工作空间内的包可能有特殊处理
2. 可能需要重新构建项目
3. 包路径格式可能不正确

### 问题 2: 包路径格式

当前使用的是：
```
PingGuoMiaoMiao/Lunarcrypto/rlp
```

可能需要：
- 点号分隔：`PingGuoMiaoMiao.Lunarcrypto.rlp`
- 或者：`rlp`（如果在同一模块内）

## 🔧 解决方案尝试

### 尝试 1: 验证包是否存在

```bash
# 检查包是否能被找到
moon info rlp
moon info ecdsa
```

### 尝试 2: 重新构建

```bash
# 清理并重新构建
moon clean
moon build
moon info transaction
```

### 尝试 3: 检查包名格式

根据生成的 `.mbti` 文件，包名是：
```
package "PingGuoMiaoMiao/Lunarcrypto/rlp"
```

所以 `moon.pkg.json` 中的格式应该是正确的。

### 尝试 4: 查看其他包的用法

检查项目中是否有其他文件成功使用了跨包引用。

## 📝 下一步行动

1. **研究 MoonBit 包导入文档**
   - 仔细阅读 [包管理文档](https://docs.moonbitlang.cn/language/packages.html)
   - 查找工作空间内包的使用示例

2. **测试不同的导入方式**
   - 尝试直接使用类型
   - 尝试使用完整包路径
   - 检查是否需要特殊配置

3. **查看示例项目**
   - 查找 MoonBit 官方示例
   - 查看是否有类似的多包项目

## 🔗 参考链接

- [MoonBit 包管理文档](https://docs.moonbitlang.cn/language/packages.html)
- [MoonBit 语言基础](https://docs.moonbitlang.cn/language/fundamentals.html)
- [MoonBit 模块配置](https://docs.moonbitlang.cn/language/packages.html)

## 💡 临时方案

在导入问题解决之前，可以考虑：

1. **使用类型别名**（临时）
   ```moonbit
   // 在 transaction 模块中定义类型别名
   type RLPItem = ...  // 临时定义
   ```

2. **保持占位符实现**
   - 当前使用占位符，功能框架完整
   - 等导入问题解决后替换

3. **逐步验证**
   - 先测试简单的类型引用
   - 再测试函数调用
   - 最后实现完整功能

