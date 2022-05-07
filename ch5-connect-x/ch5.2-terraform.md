# 5.2 Terraform

Terraform 是一个 IT 基础架构自动化编排工具，它的口号是“Write, Plan, and Create Infrastructure as Code”，是一个“基础设施即代码”工具，类似于AWS CloudFormation，允许您创建、更新和版本控制的AWS基础设施。目前其社区已经具备了大量的资源，Kusion 通过复用 Provider 生态来兼容社区的资源。

Kusion 通过兼容的方式支持 Terraform 的 Provider，同时借助第三方的工具可以方便将 Provider 支持的模型导出为 KCL 格式的 Schema 模型。用户可以在此基础之上继续封装更简化的 API。
