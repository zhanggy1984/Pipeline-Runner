---
name: test-master
description: 代码变更驱动的单元测试生成和执行。读取方案测试场景和 git diff 确定变更范围，生成测试代码并运行。全自动执行，反模式预检不阻塞，全部中文输出。触发条件："写测试"、"添加单元测试"、编码完成后自动触发。
---

# 测试大师

全自动单元测试工作流——从设计测试场景中生成测试代码，运行并回填结果。
**不暂停等待用户确认。全部中文输出。**

流程:
```
提取场景 → 生成测试清单草稿 → 反模式预检(子代理，不阻塞) → 生成代码 → 运行 → 回填结果
```

## 核心原则

**测试代码做什么，不测试 mock 做了什么。** 每个测试必须断言实际输出——不能只断言 mock 是否被调用。

## 硬性约束

- 每个新增/修改的公开方法至少覆盖: 1 个正常路径 + 1 个边界情况 + 1 个异常路径
- 测试方法命名: `should_预期行为_when_条件` (Java) / `it('should 预期行为 when 条件')` (TypeScript)
- Mock 所有外部依赖 (数据库、消息队列、HTTP、文件系统)
- 测试必须编译通过且全部绿色
- **铁律: 当测试失败时，修生产代码——永远不要为适应有问题的代码而修改正确的测试。** 唯一例外: 测试本身的断言或 mock 设置有问题。
- 只测公开方法，不测私有内部实现

## 输入

1. `.claude/workflow/solution.md` — 测试场景章节
2. `git diff` — 变更范围
3. `.claude/workflow/tasks/{task-id}.md` — 任务边界和文件列表
4. 项目配置 — `pom.xml` / `package.json`

## 步骤 1: 提取测试目标

### 1.1 从方案设计提取测试场景
- 读取 `## 测试场景` 章节
- 映射每个场景到变更的方法
- 如无测试场景章节: 从验收标准派生

### 1.2 从 git diff 提取变更方法
- 列出所有变更文件
- 提取新增/修改的公开方法签名
- 区分语言: Java (JUnit 5 + Mockito) / TypeScript (Vitest + Testing Library)

### 1.3 生成测试覆盖矩阵

```
| 编号 | 被测方法 | 文件 | 正常路径 | 边界情况 | 异常路径 |
|------|----------|------|----------|----------|----------|
| 1 | checkAndWarn | WarningServiceImpl.java | 库存低于阈值触发告警 | 库存为0 | 所有参数为空 |
```

## 步骤 2: 生成测试清单草稿

解析方案设计的 `## 测试场景`，生成测试清单草稿:

```markdown
# 测试清单（草稿）

由测试大师于 {日期} 生成。
覆盖测试场景来源: solution.md
项目: {项目名称}

**状态**: 草稿 — 自动生成，如需调整可手动修改

## {测试类名}

| 测试方法 | 场景 | 类型 | 结果 |
|----------|------|------|------|
| shouldXxx_whenYyy | {方案设计中的场景描述} | 正常/边界/异常 |  |
```

**类型分类**:
- **正常**: 有效输入返回预期结果
- **边界**: 空列表、极值、状态转换、空输入
- **异常**: 未找到、校验失败、外部异常

## 步骤 3: 反模式预检（子代理，不阻塞）

启动独立子代理审查草稿。**结果作为信息输出，不阻塞流水线。**

子代理审查维度:
1. **覆盖完整性**: 每个验收标准有对应测试用例？每个公开方法有正常+边界+异常覆盖？
2. **反模式检测**: 纯验证型测试？过度 mock？单个测试测多个关注点？
3. **边界完整性**: 空集合/空输入、极值、状态转换、外部失败

**输出格式（指令式）**: 对每个发现，在 .claude/workflow/tests/test-index.md 对应行下方追加 `→ ASSERT:` 指令:

```
| shouldNotify_whenThreshold | 超过阈值发送通知 | 正常 |  |
→ ASSERT: verify(通知服务).send(argThat(n -> n.level == WARN && n.message.contains("threshold")))
```

该指令告诉代码生成器使用此断言代替默认断言模板。

## 步骤 4: 检测并补全测试框架

### 后端 Java
- 检查 pom.xml: spring-boot-starter-test、junit-jupiter、mockito-core、h2(如需)
- 控制器测试: 不用 @WebMvcTest，始终用 @SpringBootTest + @AutoConfigureMockMvc
- 创建 src/test/java 目录（如不存在）

### 前端
- 检查 package.json: vitest、@testing-library/react、@testing-library/jest-dom、jsdom
- 创建 vitest.config.ts（如不存在）

## 步骤 5: 生成测试代码

直接从 .claude/workflow/tests/test-index.md 生成，不等待用户确认。

### 5.1 解析规则

| 列 | 规则 |
|----|------|
| 测试方法 | 已填则直接用，TBD 则从场景自动生成 |
| 场景 | 作为 `@DisplayName("{原文}")` |
| 类型 | 正常→assertEquals/assertNotNull, 边界→assertTrue, 异常→assertThrows |
| `→ ASSERT:` 行 | 存在则跳过默认断言模板，直接使用指令中指定的断言代码 |

### 5.2 生成示例

```
测试清单行（无断言指令）:
| shouldReturnVO_whenValidFields | 有效标题创建待办 | 正常 |  |

生成:
@Test
@DisplayName("有效标题创建待办")
void shouldReturnVO_whenValidFields() {
    // 正常: mock 返回正常 → assertNotNull + assertEquals
}

测试清单行（有断言指令）:
| shouldNotify_whenThreshold | 超过阈值发送通知 | 正常 |  |
→ ASSERT: verify(通知服务).send(argThat(n -> n.level == WARN))

生成: 使用指令中的断言代码替换默认模板
```

## 步骤 6: 运行测试

```bash
# 后端
mvn test -Dtest={测试类名}

# 前端
npx vitest run {测试文件路径}
```

### 结果处理
- **全部通过** → 步骤 7
- **部分失败** → 分析根因，遵循铁律
  - 代码 bug → 自动修复生产代码（简单修复: 空检查、遗漏注解、类型修正）
  - 复杂 bug → 记录到结果列 (✘)，不阻塞流水线
  - 测试断言错误 → 修正测试（唯一例外）

## 步骤 7: 回填结果

更新 .claude/workflow/tests/test-index.md:
- 空结果单元格 → ✔ (通过) 或 ✘ (失败)
- 全部通过 → 状态设为 `✅ 最终版`
- 部分失败 → 状态设为 `⚠️ 部分通过`

## 步骤 8: 接口冒烟测试（后端项目）

仅后端项目，单元测试通过后执行: 启动应用 → curl 增删改查验证 → 停止应用。

## 流水线集成

此技能被流水线编排器作为第四阶段调用。执行完毕后流水线**直接进入审查阶段，不暂停**。所有输出文件用户可自助查看。

## Sub-Agent Prompt

```
你是测试大师。生成并运行单元测试，报告结果。全部中文输出。

## 执行顺序
1. 提取测试目标:
   - 读取 solution.md 的 ## 测试场景 章节（主输入）。
   - 运行 git diff HEAD 识别变更方法。
   - 合并为覆盖矩阵: | 被测方法 | 文件 | 正常 | 边界 | 异常 |。
2. 生成测试清单草稿到 .claude/workflow/tests/test-index.md:
   - 每场景一行，方法名用 shouldXxx_whenYyy 格式（不确定则 TBD）。状态: 草稿。
3. 反模式预检（必须执行的子代理，不可跳过）:
   - 启动独立审查子代理: .claude/workflow/tests/test-index.md 内容 + solution.md 验收标准 + 反模式目录。
   - 子代理检查: 覆盖完整性、反模式（纯验证型、过度mock）、边界完整性。
   - 子代理输出格式: 每个发现用 → ASSERT: 指令追加到受影响行下方。
     示例: → ASSERT: verify(通知服务).send(argThat(n -> n.level == WARN))
   - 子代理直接更新 .claude/workflow/tests/test-index.md。向用户展示摘要（信息性，不阻塞）。
4. 检测/补全测试框架:
   - 后端: 检查 pom.xml 的 spring-boot-starter-test 等。控制器测试用 @SpringBootTest。
   - 前端: 检查 package.json 的 vitest 等。npm install -D 缺失包。
5. 从 .claude/workflow/tests/test-index.md 生成测试代码:
   - 一行 = 一个 @Test 方法。用 shouldXxx_whenYyy 或从场景生成。
   - @DisplayName 使用原始场景文本。类型决定断言风格。
   - 如有 → ASSERT: 指令 → 直接用作断言体。
   - 后端: JUnit 5 + Mockito。前端: Vitest + Testing Library。
6. 运行: mvn test / npx vitest run。
   - 全部通过 → 步骤7。
   - 失败 → 铁律: 修生产代码（简单修复: 空检查、注解、类型修正）。复杂bug → 标记✘。测试断言错 → 修测试（唯一例外）。重跑。
7. 回填: 更新结果列 ✔/✘。全部通过 → ✅ 最终版。
8. 接口冒烟测试（后端）: mvn spring-boot:run → curl 增删改查 → 停止。

## 铁律
测试失败 → 修复生产代码。永远不要修改正确的测试来适应有问题的代码。

## 输出
测试数量、通过/失败数、覆盖摘要。.claude/workflow/tests/test-index.md 标记最终状态。全部中文。
```
