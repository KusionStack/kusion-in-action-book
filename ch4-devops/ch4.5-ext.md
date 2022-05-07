# 4.5 补充说明

为了适配云原生场景，Kusion 将一些概念内置到了最佳实践之中。本节补充解释一些云原生应用到概念。

## 4.5.1 命名空间

在以应用为中心的运维体系中，通常可以借助 Kubernetes 中的命名空间（Namespace）进行应用之间的资源隔离，即以应用名作为命名空间名。
同时，支持应用部署的所有 Kubernetes 资源都部署到同一个命名空间中。

在 Kusion 技术栈推荐的目录工程结构中，可以在 Project 配置文件（project.yaml）中声明当前 Project 的 Name，
在应用运维场景中，Project Name 即是应用名称，默认也是命名空间名称。

> 用户可以根据自己的业务需求修改命名空间，建议项目名称和命名空间保持一致，但不是硬性要求。

通过上一步初始化的样例，可以从 `project.yaml` 看到相关配置：

```yaml        
# The project basic info
name: deployment-single-stack
```

## 4.5.2 资源规格

通过配置 `schedulingStrategy.resource` 设置应用主容器的资源规格，此配置存在于 `dev/main.k` 文件。

> 有关资源规格的抽象定义，可以查看 Konfig 仓库中 [`base/pkg/kusion_models/kube/templates/resource.k`](https://github.com/KusionStack/konfig/blob/master/base/pkg/kusion_models/kube/templates/resource.k) 文件。

`dev/main.k` 中资源规格配置：

```py
appConfiguration: frontend.Server {
    schedulingStrategy.resource = res_tpl.tiny
}
```

通过配置 schedulingStrategy.resource 设置主容器的资源规格，上面的赋值语句等价于：

```py
import base.pkg.kusion_models.kube.frontend.resource as res

schedulingStrategy.resource = res.Resource {
    cpu = 100m
    memory = 100Mi
    disk = 1Gi
}
```

## 4.5.3 主容器配置

通过配置 mainContainer 设置主容器，此配置存在于 `base/bask.k` 文件中。

> 有关主容器的抽象定义，可以查看 Konfig 仓库中 [base.pkg.kusion_models.kube.frontend.container](/docs/reference/model/models/kube/frontend/container) 模块的文档。

`base/bask.k` 中主容器配置：

```py
appConfiguration: frontend.Server {
    # Main Container Configuration
    mainContainer = container.Main {
        name = "php-redis"
        env = [
            {
                name = "GET_HOSTS_FROM"
                value = "dns"
            }
        ]
        ports = [
            { containerPort = 80 }
        ]
    }
}
```

## 4.5.4 差异化配置

通过 if-else 添加差异化配置，比如根据实际部署的集群名称设置不同的 labels。

> 有关 KCL 语义相关的详细说明，请参阅[表达式](/reference/lang/lang/spec/expressions.md)。

`base/bask.k` 中 Pod Label 的配置：

```py
appConfiguration: frontend.Server {
    podMetadata.labels = {
        if __META_CLUSTER_NAME in ["minikube", "kind"]:
            cluster = __META_CLUSTER_NAME
        else:
            cluster = "other"
    }
}
```

## 4.5.5 服务配置

Service 的名称、类型、暴露的端口号等字段，可通过 `services` 字段配置。

> 有关 [Service](/reference/model/models/kube/frontend/service/service.md) 的抽象定义，可以查看 Konfig 仓库中 `base/pkg/kusion_models/kube/frontend/service/service.k` 文件。

`base/bask.k` 中 Service 的配置：
```py
appConfiguration: frontend.Server {
    services = [
        service.Service {
            name = "frontend-service"
            type = "NodePort"
            ports = [
                { port = 80 }
            ]
        }
    ]
}
```
