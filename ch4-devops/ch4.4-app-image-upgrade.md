# 4.4 应用镜像升级

本节展示如何升级应用镜像。

## 4.4.1 准备条件

在开始之前同样需要安装 KusionCtl、Minikube 环境，然后将展示通过修改配置代码完成镜像升级工作。

## 4.4.2 镜像升级

编辑 `dev/main.k` 中的 image 的值：

```py
import base.pkg.kusion_models.kube.frontend

appConfiguration: frontend.Server {
    # 修改 image 的值为要升级的版本
    # image = "gcr.io/google-samples/gb-frontend:v4"
    image = "gcr.io/google-samples/gb-frontend:v5"
}
```

## 4.4.3 配置生效

执行以下命令将升级后的镜像进行生效：

```
$ kusion apply
SUCCESS  Compiling in stack dev...

Stack: dev    Provider                Type              Name    Plan
      * ├─  kubernetes        v1:Namespace              demo  UnChange
      * ├─  kubernetes          v1:Service      demo-service  Update
      * └─  kubernetes  apps/v1:Deployment           demodev  UnChange

✔ yes
SUCCESS  Updating Service/demo-service
Updating Service/demo-service [1/1] ████████████████████████████████ 100% | 0s
```

通过 Kubernetes 工具查看资源验证。
