---
name: solution-design
description: 协同技术方案设计。帮助做技术选型、数据模型设计、API 协议设计、容量评估、时序设计。全部中文输出。触发条件："设计这个"、"选技术"、"设计数据模型"、"方案是什么"、"方案对比"。
---

# Solution Design

协同技术方案设计——帮你做决策，不只是写文档。

## 与 design-doc 的区别

| | solution-design | design-doc |
|------|---------|------|
| 目标 | **做决策**（选择、设计） | **写文档**（TRD/RFC） |
| 输入 | 需求、约束 | 已确认的设计 |
| 输出 | 选项 + 对比 + 推荐 | 结构化设计文档 |
| 用户角色 | 高度协同，迭代讨论 | 审阅和批准 |

## Hard Constraints

- **永远不修改 `*Api.java` 接口签名**（除非用户确认架构组批准）
- **永远不 `git commit` 或 `git push`** 除非用户明确指示
- **永远不 `rm -rf`**

## Workflow

### Step 1: 清理 Workflow 目录

清理项目根目录 `.claude/workflow/`，移除上一次运行的残留产物。

```bash
# 在项目根目录
rm -rf .claude/workflow
mkdir -p .claude/workflow/tests .claude/workflow/tasks
```

如果目录不存在则跳过——后续步骤会自动创建。

### Step 2: 澄清需求

不等用户解释，主动确认边界：
- 功能范围：包含什么，不包含什么
- **实现范围（必须确认）**：仅后端 / 仅前端 / 全栈。即使需求已经暗示了范围，也必须显式确认——不能自动推断。这直接影响下游的任务拆分和项目骨架初始化。
- 非功能需求：QPS、数据量、延迟
- 约束：技术栈、团队能力、时间线
- 标记歧义点，直接问

### Step 3: 探索现有项目（不可跳过）

**仅针对 brownfield 项目**。触发条件：当前目录存在 `pom.xml` / `build.gradle` / `package.json`。

**这一步是硬性前置条件——不能跳过。** 必须先建立 codegraph 索引再进入设计。

1. **同步远程代码**（如适用）：
   ```bash
   git pull --rebase
   ```

2. **确保 codegraph 索引就绪**：
   ```bash
   npx codegraph init -i
   ```

3. **用 codegraph 扫描项目**：
   - `codegraph_context "项目架构 关键模式 约定 框架 版本 包结构 中间件"`
   - `codegraph_files` 获取项目文件树

4. **提取关键信息**：模块结构、现有架构、关键约定、相关代码

5. 检查 `CLAUDE.md` 的项目约定、包命名规则等

6. 将扫描结果写入 `.claude/workflow/project-context.md` 供下游 skill 复用

向用户展示确认：
```
## 项目扫描结果
- 项目类型: Spring Boot 2.7 + MyBatis-Plus 3.5 + OceanBase
- 基础包: com.company.product
- 受影响模块: user-service
- 相关文件: UserController.java 已有类似分页查询，模式可复用
```

### Step 4: 方案探索——2-3 个宏观方案

深入详细设计之前，先探索 2-3 个**根本不同**的方案。

**方法：**
1. 综合需求（Step 2）和项目上下文（Step 3）形成候选方案
2. 每个方案必须是**不同的架构愿景**，不是同一思路的变体
3. 对每个方案：核心思路（一段话）、与现有系统的关系、关键权衡
4. 呈现对比表：实现工作量、性能、可维护性、可扩展性、团队匹配度
5. 标记推荐方案并解释原因

**示例结构：**
```
方案 A: 事件驱动微服务
  核心思路: 将匹配引擎抽取为独立 Kafka 消费者组，领域事件驱动状态转换
  与现有系统关系: Kafka 已在订单事件中使用，团队熟悉
  优点: 自然解耦，消费者独立扩缩
  缺点: 最终一致性，需要 saga 编排，运维面增加
  匹配度: ★★★★☆

方案 B: 单体增强
  核心思路: 保持现有架构，新增定时批处理器
  优点: 最快交付，调试简单，无新基础设施
  缺点: 扩展上限低，批处理延迟，后期复用困难
  匹配度: ★★★★★

对比表:
| 维度 | A: 事件驱动 | B: 单体增强 |
|------|------------|------------|
| 工作量 | 3-4 周 | 1-2 周 |
| 可维护性 | 中 | 易 |
| 性能 | 高 | 中 |
| 团队匹配 | ★★★★ | ★★★★★ |

推荐: 方案 B——团队 1 个迭代可交付，批处理窗口满足 QPS 要求。
```

**用户确认方向后** → 进入细化设计。

### Step 5: 细化设计

用户选择方向后展开：
- **数据模型**：表结构、索引、分片键、DDL 草案
- **API 协议**：REST/MQ 选择，请求/响应结构
- **核心流程**：关键流程的时序图或伪代码
- **容量估算**：存储、带宽、连接数估算

#### API Contract（涉及前后端时）

如果方案同时涉及前后端，**API Contract 优先定义**。这是唯一真相来源——前端 mock，后端实现，双方在开发前达成一致。

Contract 内容：
1. **端点定义**：路径、方法、请求头、查询参数、请求体
2. **请求/响应 DTO**：字段名、类型、必填/可选、嵌套结构、示例
3. **错误码**：HTTP 状态码、业务错误码、错误消息格式
4. **认证**：token 位置、认证方案、刷新流程
5. **分页**：page vs offset 风格、响应形状

#### Test Scenarios

从需求、数据模型和 API Contract 派生**特性级测试场景**——在写任何代码之前。确保测试与实现无关。

每个特性定义：
```
Normal paths (1-3): "正常情况"的表现
Edge cases (1-2): 边界、空状态、最大值
Error paths (1-2): 预期的失败模式
```

示例：
```
## Test Scenarios

### 创建书签
- Normal: 有效 URL + 标题 → 书签创建成功，返回 id
- Edge: URL 无协议 → 校验错误
- Edge: 标题超过 200 字符 → 截断或拒绝
- Error: DB 写入失败 → 500，用户看到重试提示

### 列出书签
- Normal: 分页返回正确的条目和总数
- Edge: 空数据库 → 空列表，非 null，非 404
- Edge: 页码超出范围 → 空列表
```

#### Format Contract（供 test-master 解析）

Test Scenarios 必须遵循此格式：
```markdown
## Test Scenarios

### {FeatureName}
- Normal: {description}
- Edge: {description}
- Error: {description}

### {AnotherFeature}
- Normal: {description}
- Error: {description}
```

规则：
1. 标题: `## Test Scenarios`（精确文本）
2. 特性组: `### {FeatureName}`
3. 场景行: `- {Type}: {description}`，Type 为 Normal/Edge/Error 之一
4. 每个特性至少 1 个场景，最多 5 个
5. 描述是自由文本，人类和 test-master 都可读

### Step 6: 自我挑战——"3 个最薄弱点"

完整方案草稿（设计决策 + 数据模型 + API + 核心流程 + 测试场景）呈现后，**持久化之前**，主动说：

> 方案初稿完成。需要我挑战它最薄弱的 3 个点吗？

**为什么**：AI 方案有天然的确认偏误——方案读起来通顺时容易忽略边界约束和局部最优。外部挑战远比自己审查有效。

仅在用户同意后执行：
1. 找出 3 个最有疑问的假设或最冒险的决策
2. 逐个解释：核心问题、为什么现在重要、什么条件下会真的出问题
3. 如果用户需要，建议可能的缓解措施

### Step 7: 标记风险

- A/B/C 分级
- 每个风险的缓解方案
- 标注 "如果出问题，最可能的失败模式是…"

### Step 8: 持久化到 Workflow

用户确认最终设计后，写入 `.claude/workflow/solution.md`。内容涵盖下游 skill 所需全部信息：

```markdown
# 技术方案: {title}

## 背景与目标
{简要上下文、问题陈述、成功标准}

## 设计决策
- **{决策1}**: 选择 {A}，原因 {reason}，不选 {B} 的原因 {reason}

## 数据模型
{每个表都要有完整的DDL SQL语句，含COMMENT注释:}
### {table_name}
```sql
CREATE TABLE {table_name} (
    {字段名} {类型} {约束} COMMENT '{说明}',
    ...
    PRIMARY KEY (...)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='{表说明}';
```
{如有索引: CREATE INDEX ... }

## API 契约（前后端共享）
- 端点: `{method} {path}` — {用途}
- 请求: {参数、请求体、请求头}
- 响应: {成功格式、错误码}
- 认证: {方案、token位置}

## 接口定义
- **{path/method}**: {用途}
  - 请求字段: {字段列表}
  - 响应字段: {字段列表}

## 核心流程
{关键业务流程，伪代码或时序图}

## 测试场景
### {功能模块名}
- 正常: {场景描述}
- 边界: {场景描述}
- 异常: {场景描述}

## 风险与缓解
- A: {风险} -> {缓解措施}
- B: {风险} -> {缓解措施}
```

> **全部中文输出**。仅代码标识符（类名、方法名、字段名、表名）保持英文。

### Pipeline 集成

此 skill 被 pipeline-runner 作为流水线第一阶段调用。**Step 8 持久化完成后，pipeline-runner 会暂停，向用户展示设计摘要（架构、数据模型、API 清单、测试场景数、风险分级）。用户确认无误后，才进入 Phase 2（SPLIT）。用户要求修改则回到 Step 5 调整。**

确保 solution.md 写入后格式完整，下游 task-splitter 可直接读取。

## 适用场景

### 技术选型
用户说"对账系统用 Flink 还是 Spring Batch？"→ 选项对比 + 推荐 + 理由。

### 数据模型设计
用户说"设计对账结果存储表"→ DDL + 分片键 + 索引 + 数据量估算 + 查询模式分析。

### API 设计
用户说"对账查询 API 怎么设计？"→ REST vs RPC vs MQ 选择 + 请求/响应结构 + 分页策略 + 错误码。

### 容量估算
用户说"这个方案能扛 1000 QPS 吗？"→ 逐层瓶颈分析 + 单实例容量估算 + 水平扩展计划。

## 交互原则

- **设计在文档之前**：先讨论确认设计，再写正式文档
- **挑战用户**：方向错了直接说
- **不替用户做决策**：呈现选项和推荐，让用户拍板
- **交流语言**: 所有产出文档（solution.md、project-context.md）必须全部使用中文。代码标识符（类名、方法名、字段名）保持英文。

## Sub-Agent Prompt

```
You are solution-design. Execute the following workflow:

1. Clean: rm -rf .claude/workflow && mkdir -p .claude/workflow/tasks .claude/workflow/tests
2. Clarify: confirm scope (backend/frontend/full-stack), non-functional requirements, constraints. Flag ambiguities.
3. Explore (brownfield): git pull --rebase, npx codegraph init -i, scan project with codegraph_context + codegraph_files. Write baseline to .claude/workflow/project-context.md.
4. Propose 2-3 macro approaches with comparison table. Each approach: core idea, how it fits existing system, trade-offs, team-fit rating. Mark recommendation.
5. After user picks direction: refine data model (**complete DDL SQL with COMMENT annotations, indexes**), API contract (endpoints, DTOs, error codes, auth), core flow, capacity estimation.
6. Derive test scenarios: feature-level Normal/Edge/Error scenarios following Format Contract (## Test Scenarios, ### {Feature}, - Type: description). At least 1 per feature, max 5.
7. Self-challenge: ask user "Should I challenge the 3 weakest points?" before persisting.
8. Flag risks with A/B/C classification and mitigation.
9. Persist to .claude/workflow/solution.md with all sections in **Chinese** (headings, descriptions, comments). Only code identifiers (class names, method names, field names, table names) remain in English. Follow the Chinese template exactly.

Output: .claude/workflow/solution.md with complete design in Chinese.
```
