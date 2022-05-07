# 4.3 扩展应用资源容量

本节展示如果扩展资源容量。

## 4.3.1 准备条件

在开始之前同样需要安装 KusionCtl、Minikube环境，然后将展示初始化配置代码、应用扩容等内容。

## 4.3.2 配置资源规格

可以通过编辑 `schedulingStrategy.resource` 的值来设置主容器的资源规格。有两个方法修改资源规格，一种是修改 resource 表达式中 cpu、memory 的值：

<!-- TODO: 给出模型参考链接 -->

```py
import base.pkg.kusion_models.kube.frontend
import base.pkg.kusion_models.kube.frontend.resource as res

appConfiguration: frontend.Server {
    # 修改 resource 表达式中 cpu、memory 的值
    # 原值：schedulingStrategy.resource = "cpu=100m,memory=100Mi,disk=1Gi"
    # 新的值（应用扩容）：
    schedulingStrategy.resource = res.Resource {
        cpu = 500m
        memory = 500Mi
        disk = 1Gi
    }
}
```

另一种是使用预置的 resource 值替代原值来进行应用扩容：

```py
import base.pkg.kusion_models.kube.frontend
import base.pkg.kusion_models.kube.templates.resource as res_tpl

appConfiguration: frontend.Server {
    # 使用预置的 resource 值替代原值来进行应用扩容：
    # 原值：schedulingStrategy.resource = "cpu=100m,memory=100Mi,disk=1Gi"
    # 新的值（应用扩容）：
    schedulingStrategy.resource = res_tpl.large
}
```

上述代码是样例配置，可以根据 SchedulingStrategy 模型定义和实际情况添加自定义配置：

```py
import base.pkg.kusion_models.kube.frontend.resource as res

schema SchedulingStrategy:
    """ SchedulingStrategy represents scheduling strategy.

    Attributes
    ----------
    resource: str | res.Resource, default is "1<cpu<2,1Gi<memory<2Gi,disk=20Gi", required.
        A Pod-level attribute.
        Main container resource.
    """
    resource: str | res.Resource = "1<cpu<2,1Gi<memory<2Gi,disk=20Gi"
```

## 4.3.3 配置生效

执行以下命令将升级后的镜像进行生效：

```
$ kusion apply
SUCCESS  Compiling in stack dev...

Stack: dev    Provider                Type              Name    Plan
      * ├─  kubernetes        v1:Namespace              demo  UnChange
      * ├─  kubernetes          v1:Service      demo-service  UnChange
      * └─  kubernetes  apps/v1:Deployment           demodev  Update

✔ yes
SUCCESS  Updating apps/v1:Deployment
Updating apps/v1:Deployment [1/1] ████████████████████████████████ 100% | 0s
```

通过 Kubernetes 工具查看资源验证。
