# 5.1 OpenAPI

对于全新的项目来说，您只需要从头开始采用 Kusion 技术栈编写和管理基础设施配置即可，我们提供了针对不同运行时的用户指南文档引导您这一过程。 然而，对于已经建设了基础设施的项目，可能已有存量的配置模型和数据，对此，Kusion 也提供了一些自动化工具帮助您快速迁移。

对于 kubernetes 用户，Kusion 提供了 OpenAPI 到 KCL 模型代码的转换工具，以直接复用 Kubernetes 已有的上百个核心模型。 对于 istio 用户，以及 Kubernetes 内置模型无法支持的情况， Kusion 还支持将 CRD 自动生成为 KCL 模型代码。

## 5.1.1 Kubernetes OpenAPI Spec

从 Kubernetes 1.4 开始，引入了对 OpenAPI 规范（在捐赠给 Open API Initiative 之前称为 swagger 2.0）的 alpha 支持，API 描述遵循 [OpenAPI 规范 2.0](https://github.com/OAI/OpenAPI-Specification/blob/main/versions/2.0.md)，从 Kubernetes 1.5 开始，Kubernetes 能够直接从[源码自动地提取模型并生成 OpenAPI 规范](https://github.com/kubernetes/kube-openapi)，自动化地保证了规范和文档与操作/模型的更新完全同步。

此外，Kubernetes CRD 使用 [OpenAPI v3.0 validation](https://kubernetes.io/docs/tasks/extend-kubernetes/custom-resources/custom-resource-definitions/#validation) 来描述（除内置属性 apiVersion、kind、metadata 之外的）自定义 schema，在 CR 的创建和更新阶段，APIServer 会使用这个 schema 对 CR 的内容进行校验。

## 5.1.2 KCL OpenAPI 支持

KCLOpenAPI 工具支持从 OpenAPI/CRD 定义提取并生成 KCL schema. 在[KCLOpenapi Spec](https://kusionstack.io/docs/reference/cli/openapi/spec)中明确定义了 OpenAPI 规范与 KCL 语言之间的映射关系。

[安装 Kusion 工具包](https://kusionstack.io/docs/user_docs/getting-started/install)的同时会默认安装 KCLOpenapi 工具，KCLOpenapi 工具的使用和示例可参见[KCLOpenAPI 工具](https://kusionstack.io/docs/reference/cli/openapi)

## 5.1.3 从 Kubernetes 模型迁移到 Kusion

Kubernetes 内置模型的完整 OpenAPI 定义存放在 [Kubernetes openapi-spec 文件](https://github.com/kubernetes/kubernetes/blob/master/api/openapi-spec/swagger.json)。以该文件作为输入，KCLOpenapi 工具能够生成相应版本的全部模型 schema. 接下来以发布部署场景为例，演示从 Kubernetes 迁移到 Kusion 的流程。假设您的项目正在使用 [Kubernetes Deployment](https://kubernetes.io/docs/concepts/workloads/controllers/deployment/) 定义发布部署配置，迁移到 Kusion 只需要如下几步：

### 5.1.3.1 Kubernetes Deployment 转为 KCL Schema

从 [Kubernetes 1.23 版本的 openapi-spec 文件](https://github.com/kubernetes/kubernetes/blob/release-1.23/api/openapi-spec/swagger.json)中，可以找到 apps/v1.Deployment 模型相关的定义，截取片段如下：

```json
{
    "definitions": {
        "io.k8s.api.apps.v1.Deployment": {
            "description": "Deployment enables declarative updates for Pods and ReplicaSets.",
            "properties": {
                "apiVersion": {
                    "description": "APIVersion defines the versioned schema of this representation of an object. Servers should convert recognized schemas to the latest internal value, and may reject unrecognized values. More info: https://git.k8s.io/community/contributors/devel/sig-architecture/api-conventions.md#resources",
                    "type": "string"
                },
                "kind": {
                    "description": "Kind is a string value representing the REST resource this object represents. Servers may infer this from the endpoint the client submits requests to. Cannot be updated. In CamelCase. More info: https://git.k8s.io/community/contributors/devel/sig-architecture/api-conventions.md#types-kinds",
                    "type": "string"
                },
                "metadata": {
                    "$ref": "#/definitions/io.k8s.apimachinery.pkg.apis.meta.v1.ObjectMeta",
                    "description": "Standard object's metadata. More info: https://git.k8s.io/community/contributors/devel/sig-architecture/api-conventions.md#metadata"
                },
                "spec": {
                    "$ref": "#/definitions/io.k8s.api.apps.v1.DeploymentSpec",
                    "description": "Specification of the desired behavior of the Deployment."
                },
                "status": {
                    "$ref": "#/definitions/io.k8s.api.apps.v1.DeploymentStatus",
                    "description": "Most recently observed status of the Deployment."
                }
            },
            "type": "object",
            "x-kubernetes-group-version-kind": [
                {
                    "group": "apps",
                    "kind": "Deployment",
                    "version": "v1"
                }
            ]
        }
    },
    "info": {
        "title": "Kubernetes",
        "version": "unversioned"
    },
    "paths": {},
    "swagger": "2.0"
}
```

将以上述 spec 保存为 deployment.json，执行 ```kclopenapi generate model -f deployment.json```，将在当前工作空间生成所有相关的 KCL schema 文件。在 Konfig 的 base/pkg/kusion_kubernetes 目录中，我们已经保存了一份由此生成的 [KCL 文件](https://github.com/KusionStack/konfig/blob/master/base/pkg/kusion_kubernetes/api/apps/v1/deployment.k)，并生成了对应的模型文档。

<!-- TODO: 模型文档加链接 -->

### 5.1.3.2 使用生成的 KCL Schema

* 使用生成的模型，直接声明 KCL 配置

    我们可以在 KCL 配置中直接实例化生成的 Deployment，得到一份部署声明，如下：

    ```python
    import kusion_kubernetes.api.apps.v1

    frontend = v1.Deployment {
        metadata.name: "frontend"
        spec.selector.matchLabels: {app: guestbook, tier: frontend}
        replicas: 3
        template.metadata.labels: {app: guestbook, tier: frontend}
        spec.containers: [
            {
                name: php-redis
                image: gcr.io/google-samples/gb-frontend:v4
                resources.requests: { cpu: "100m", memory: "100Mi"}
            }
            env: [{name: GET_HOSTS_FROM, value: dns}]
            ports: [{containerPort: 80}]
        ]
    }
    ```

    在 Konfig 仓库中增加以上配置声明，经过的编译后，其结果等价于 [Kubernetes examples guestbook-frontend](https://github.com/kubernetes/examples/blob/master/guestbook/frontend-deployment.yaml)，关于 Konfig 仓库及编译命令可参考 [Konfig 模型库快速开始](https://kusionstack.io/docs/reference/model/model-quick-start)。

* 最佳实践：对 Kubernetes 模型进一步抽象，定义用户友好的界面

    由于 Kubernetes 内置模型较为原子化和复杂，我们推荐以 Kubernetes 原生模型作为后端输出的模型，而向用户暴露一份更为友好和简单的前端模型界面。在 Konfig 的 kusion_models 目录中已经保存了一份经过良好抽象的模型 —— Server 模型，点此查看 [Server Schema](https://github.com/KusionStack/konfig/blob/master/base/pkg/kusion_models/kube/frontend/server.k)

## 5.1.4 从 Kubernetes CRD 迁移到 Kusion

如果您的项目中使用了 CRD，也可以采用类似的模式，生成 CRD 对应的 KCL schema，并基于该 schema 声明 CR。使用 `kclopenapi generate model --crd --skip-validation -f your_crd.yaml` 命令从 CRD 生成 KCL Schema。或者使用 KCL 声明 CR 的模式与声明 Kubernetes 内置模型配置的模式相同，在此不做赘述。

