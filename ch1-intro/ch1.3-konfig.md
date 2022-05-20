# 1.3 Konfig 模型库

Konfig 是 Kusion 内置的基础配置模型库（ Kuison+config 的组合词）。本节将展示如何通过 KCL 语言为已有的 YAML 配置建模，从而构建一个自己的模型库——这也是 Konfig 的雏形。最后简单介绍 Konfig 诞生的背景。

## 1.3.1 YAML 建模

YAML 是用来写配置文件的语言，非常简洁和强大，目前是 Kubernetes 官方钦定的首选配置交换格式。YAML 很灵活也很好写，同时也很容易出错！比如 Kubernetes 官网的 [Nginx-Deployment](https://kubernetes.io/zh/docs/concepts/workloads/controllers/deployment/) 例子：

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: nginx-deployment
spec:
  replicas: 3
  selector:
    matchLabels:
      app: nginx
  template:
    spec:
      containers:
      - image: nginx:1.14.2
        name: nginx
        ports:
        - containerPort: 80
```

该例子部署一个 Nginx 服务。如果我们不小心写错其中的某个配置，并且不能在第一时间发现，那么可能带来未知的风险。其实对于 Kubernetes 语境来说，这个 `Deployment` 配置是有着明确的定义的：每个字段的名字和类型、以及相关字段的值需要满足一定的规则等。通过定制面向领域的 DSL 语言来提升配置的安全性正是设计 KCL 语言的初衷。

我们可以尝试用 KCL 给 `Deployment` 配置建模：

```py
schema Deployment:
    final apiVersion: str = "apps/v1"
    final kind: str = "Deployment"

    metadata?: apis_ObjectMeta
    spec?: DeploymentSpec
```

我们首选通过 KCL 的 `schema` 关键字定义一个 `Deployment` 模型。其中的 `apiVersion` 和 `kind` 字段有着固定的类型和值，因此我们通过 `final` 和默认值的特性描述。而对于复杂的 `metadata` 和 `spec` 字段则通过新的 `ObjectMeta` 和 `DeploymentSpec` 模型描述，它们的字段名均已问号结尾表示是可选的字段。

`ObjectMeta` 模型的全部属性有很多，目前只定义需要的部分如下：

```py
schema ObjectMeta:
    name?: str
    namespace?: str
```

同样 `DeploymentSpec` 模型的定义如下：

```py
schema DeploymentSpec:
    replicas?: int
    selector: LabelSelector
    template: PodTemplateSpec
```

其中 `replicas` 是一个可选字段，`selector` 和 `template` 字段则继续用新模型描述。

`LabelSelector` 模型用户描述 Label 选择的参数，定义如下：

```py
schema LabelSelector:
    matchLabels?: {str:str}
```

其中 `matchLabels` 字段是一个 dict 字典类型，字典的 Key 和 Value 都是字符串。

`PodTemplateSpec` 模型定义如下：

```py
schema PodTemplateSpec:
    metadata?: ObjectMeta
    spec?: PodSpec

schema PodSpec:
    containers: [Container]

schema Container:
    image?: str
    name: str
    ports?: [ContainerPort]

schema ContainerPort:
    containerPort: int

```

其中 `metadata` 字段用的是已经定义的 `ObjectMeta` 类型，`spec` 字段则通过 `PodSpec` 和 `Container` 描述其中容器的镜像和名称，`ports` 通过 `ContainerPort` 类型描述。

## 1.3.2 基于模型库重写配置

现在我们可以将以上代码合并保持到 `apps/deployment.k` 文件中作为一个自定义的模型库，这就是第一版 Konfig 雏形了（Konfig 开源模型库在 `base.pkg.kusion_kubernetes.api.apps.v1` 也提供了更完整的 `Deployment` 模型定义）。

现在可以创建 `main.k`，基于这个 `Deployment` 模型重新构造配置：

```py
import apps

demo = apps.Deployment {
    metadata.name = "nginx-deployment"
    spec = {
        replicas = 3
        selector.matchLabels = {
            app = "nginx"
        }
        template.spec.containers = [
            {
                name = "nginx"
                image = "nginx:1.14.2"
                ports = [
                    {containerPort = 80}
                ]
            }
        ]
    }
}
```

现在输入的 KCL 配置代码虽然和原来的 YAML 文件差不多，但是获得了 Konfig 模型库提供的静态化类型和运行时校验规则的能力，同时可以配合 IDE 插件获得更好的编码效率，也可以让我们写的配置代码更安全。然后通过 `kcl main.k` 命令可以将模型渲染出之前的 YAML 文件了。

## 1.3.3 Konfig 诞生的背景

从本节的例子可以发现，相对于我们的业务配置代码，底层模型的抽象代码更多。真实 Konfig 模型库中的 `Deployment` 代码更加庞大，同时也提供了更加完整灵活的静态类型和规则检查保障。Konfig 最初朴素的出发点就是改善 YAML 用户的效率和体验，我们希望通过将代码更繁杂的模型抽象封装到统一的模型库中，从而简化用户侧配置代码的编写。

Konfig 的前身是蚂蚁在落地 IaC&GitOps 的过程中采用的是 Konfig 大库。蚂蚁开始就把所有的 IaC 配置代码维护在一个统一的 Konfig 大仓库中，代码包括基础配置代码和业务配置代码两部分。之所以用一个大的仓库管理全部的 IaC 配置代码，是由于蚂蚁内部不同代码包的研发主体不同，会引发出包管理和版本管理的问题，从而导致平台侧需要支持类似编译平台的能力。采用大库模式下，业务配置代码、基础配置代码在一个大库中，因此代码间的版本依赖管理比较简单，平台侧处理也比较简单，定位唯一代码库的目录及文件即可，代码互通，统一管理，便于查找、修改、维护（大库模式也是 Google 等头部互联网公司内部实践的模式）。

大库模式虽然有版本管理简单等优点，但是缺点也非常多：比如大库导致仓库体积爆炸的问题会给网络下载带来更大的压力，因此不适合开源社区的分布式、异步协作的开发模式。因此当 Kusion 项目绝对开源后，我们对 Konfig 大库做了大量改造和拆分工作，核心目标是将和 Kubernetes 相关的基础模型保留，将和蚂蚁内部业务耦合比较紧密的业务代码剥离（业务相关部分的最佳实践方式会在案例实践场景中体现）。因此开源版本的 Konfig 库可以看作是 Kusion 项目针对 Kubernetes 云原生的开放生态提供基础设施模型库，这样可以帮助用户以较少的配置代码部署和运维 Kubernetes 生态的应用。同时我们希望和社区共建的方式完善和改进 Kubernetes 生态的基础设施模型库。
