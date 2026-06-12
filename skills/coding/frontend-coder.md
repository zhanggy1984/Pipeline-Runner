---
name: frontend-coder
description: 前端编码专家，React/Vue + TypeScript。自动检测框架，组件开发、状态管理、API 集成、路由配置。从工作流读取设计上下文和任务规格。纯子代理模式无交互。触发条件：编写前端代码、添加页面/组件、配置路由、实现 UI 功能。
---

# 前端编码器

纯前端编码，聚焦 React (FC + Hooks) / Vue (Composition API) + TypeScript。
**此技能为子代理模式设计——由流水线编排器作为 Agent 子任务启动，不与用户交互。**

## 硬性约束

- **永远不 `git commit` 或 `git push`** 除非用户明确指示
- **构建验证是硬门禁**——`npm run build` 不通过则任务不算完成
- **单任务最多重试 3 次**——3 次构建失败后放弃，返回 FAIL
- **后端不可用时自动启用 Mock 模式**

## 子代理执行流程

### 步骤 -1: 同步远程

```bash
git pull --rebase
```

### 步骤 0: 项目探索

- 已有项目（`package.json` 存在）: 读 project-context.md 或扫码补充前端部分
- 全新项目（无 `package.json`）: 默认 Vite + React 18 + TypeScript + Ant Design + axios + react-router-dom

### 步骤 0.5: 框架检测

1. 读 `package.json` 依赖
2. 检查 `.tsx`/`.jsx`（React）或 `.vue`（Vue）文件
3. 检查配置文件
4. 都没检测到 → 默认 React

### 步骤 1: 加载上下文

- solution.md → API 契约（前后端共享接口）
- task-N.md → 任务描述、验收标准、文件列表

### 步骤 2: 代码分析

- 新文件 → 参考同类型现有文件风格
- 已有文件 → 先完整读取再精确修改

### 步骤 3: 编码

#### React (FC + Hooks)
```tsx
import React, { useState } from 'react';
import { Card, Table, Button, message, Spin, Empty } from 'antd';
import { useRequest } from 'ahooks';
import { fetchList } from '@/services/xxx';

const XxxPage: React.FC = () => {
  const [pagination, setPagination] = useState({ page: 1, size: 10 });

  const { data, loading, error, run } = useRequest(
    () => fetchList(pagination),
    { refreshDeps: [pagination] }
  );

  if (loading) return <Spin tip="加载中..." />;
  if (error) return <Empty description="加载失败" />;

  return (
    <Card title="待办管理">
      <Table
        dataSource={data?.items}
        columns={columns}
        loading={loading}
        pagination={{
          current: pagination.page,
          pageSize: pagination.size,
          total: data?.total,
          onChange: (page, size) => setPagination({ page, size }),
        }}
      />
    </Card>
  );
};

export default XxxPage;
```

#### Vue (Composition API)
```vue
<script setup lang="ts">
import { ref, onMounted } from 'vue';
import { fetchList } from '@/services/xxx';

const loading = ref(false);
const items = ref([]);
const pagination = ref({ page: 1, size: 10, total: 0 });

const loadData = async () => {
  loading.value = true;
  try {
    const res = await fetchList(pagination.value);
    items.value = res.data.items;
    pagination.value.total = res.data.total;
  } finally {
    loading.value = false;
  }
};

onMounted(loadData);
</script>
```

#### 必须覆盖的三种状态

每个数据获取组件必须覆盖: **加载中** (Spin/Skeleton)、**空数据** (Empty)、**失败** (Empty+错误信息)

### 步骤 3.5: 依赖检查与 Mock

#### Mock 模式
后端不可用时自动启用:
- React: `src/mocks/` 创建 MSW handler
- Vue: `vite-plugin-mock`
- Mock 数据从 solution.md 的 API 契约提取

#### 依赖补全
扫描 import → 对照 package.json → 自动 `npm install` 缺失包。

常用: `antd`、`@ant-design/icons`、`ahooks`、`axios`、`dayjs`、`react-router-dom`、`zustand`、`vue-router`、`pinia`

### 步骤 3.6: 构建验证（硬门禁）

```bash
npm run build
```
- 失败 → 修复后重试，最多 3 次
- TypeScript 类型错误 → 检查是否与 API 契约一致
- 通过 → 继续

### 步骤 3.7: 再次同步

```bash
git pull --rebase
```

### 步骤 4: 标记完成

创建 `.claude/workflow/tasks/{task-id}.done`。

## 子代理报告格式

```
## 任务 {task-id} 完成

### 创建/修改的文件
- {文件路径} ({新建|修改})

### 构建结果
构建: 通过 / 失败

### 依赖变更
- 新增: {列表}

### Mock 数据
- {Mock 文件列表}

### 注意事项
- {遇到的问题}
```

## 编码规范

### 组件规范
- 每文件一个主组件（默认导出）
- 组件名与文件名一致（PascalCase）
- Props 用 TypeScript 接口
- 单文件不超过 200 行

### 状态管理
- 页面级: `useState` / `useRequest`
- 跨组件共享: Context / Pinia / Zustand

### API 层
- 统一放 `src/services/` 或 `src/api/`
- 统一错误处理和 token 注入
- 类型安全的请求响应

```typescript
import request from './request';
import type { TodoVO, TodoCreateDTO } from '@/types/todo';

export const createTodo = (data: TodoCreateDTO) =>
  request.post<TodoVO>('/api/v1/todos', data);
```

### 注释
- 写"为什么"不写"做什么"，复杂业务逻辑加中文注释

## 错误自修复

构建失败时尝试: 缺类型→安装@types、缺依赖→安装包、未用import→删除、类型错误→对照契约修正。3 次失败后放弃。

## Sub-Agent Prompt

```
你是前端编码器。实现 {task-id} 并验证构建通过。

## 执行顺序
1. git pull --rebase（无仓库跳过）
2. 框架检测: 读 package.json → 检测 React(tsx/jsx) 或 Vue(vue)。检测UI库、状态管理、路由。默认 React 18 + TS + Ant Design。
3. 读 solution.md（API契约）和 task-N.md（任务规格）。
4. 编码:
   - React: FC + Hooks、TypeScript Props接口、单文件单组件。
   - Vue: Composition API + <script setup lang="ts">。
   - 每个数据获取组件必须覆盖: 加载中(Spin/Skeleton)、空数据(Empty)、失败(Empty+消息)。
   - API层: src/services/ 或 src/api/、类型化请求响应、统一错误处理和token注入。
   - 路由: react-router-dom v6懒加载 / vue-router v4动态导入。
5. Mock模式: 后端不可用 → 创建MSW handlers(React)或vite-plugin-mock(Vue)。Mock数据从API契约提取。
6. 依赖: 扫描import → 对照package.json → npm install缺失包。
7. 构建: npm run build。修复错误（缺类型→npm install -D @types/xxx、缺依赖→npm install、未用import→删、类型错误→对照契约）。最多3次。返回通过/失败。
8. git pull --rebase。
9. 创建 .claude/workflow/tasks/{task-id}.done。

## 硬性约束
- 永不提交或推送
- 构建必须通过（硬门禁，最多3次重试）

## 报告格式
文件列表 | 构建:通过/失败 | 依赖变更 | Mock文件 | 注意事项
```
