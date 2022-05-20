# 4.2 为应用配置监控

本节展示如何为应用配置监控，通过 Prometheus 查看应用状态。

## 4.2.1 准备工作

我们将展示以下内容：初始化配置代码、使能监控配置和查看监控面板。在开始前需要安装 KusionCtl、Minikube 和 [kube-prometheus](https://github.com/prometheus-operator/kube-prometheus)。

## 4.2.2 初始化配置代码

通过 kusion 命令行工具初始化代码：

```
$ kusion init
✔ Server
project name: prometheus-example-app
stack name: prod
cluster name: default
image: quay.io/brancz/prometheus-example-app:v0.3.0
```

其中 `quay.io/brancz/prometheus-example-app:v0.3.0` 镜像对应的应用代码可参考：[https://github.com/brancz/prometheus-example-app](https://github.com/brancz/prometheus-example-app)。

这个应用程序是一个示例，说明如何使用 Prometheus 指标轻松监测 HTTP 处理程序，它使用 Prometheus go 客户端监听本地 `8080` 端口创建一个新的 Prometheus 注册表。

具体的监控指标如下：

* 任何对 `/` 的请求都会产生一个 `200` 响应码，这会增加此响应代码的计数器指标
* 任何对 `/err` 的请求都将产生一个 `404` 响应代码，会增加相应计数器的指标

## 4.2.3 使能配置

通过将 `enableMonitoring` 设置为 `True` 使能配置，并添加主容器端口号配置 `8080`。代码如下：

```py
import base.pkg.kusion_models.kube.frontend
import base.pkg.kusion_models.kube.frontend.container
import base.pkg.kusion_models.kube.frontend.container.env as e
import base.pkg.kusion_models.kube.frontend.container.port as cp
import base.pkg.kusion_models.kube.frontend.container.probe as p

# The application configuration in stack will overwrite 
# the configuration with the same attribute in base.
appConfiguration: frontend.Server {
    # Main container configuration
    mainContainer: container.Main {
        name = "prometheus-example-app"
        ports = [
            cp.ContainerPort {
                name = "web"
                containerPort = 8080
            }
        ]
    }
    enableMonitoring = True
}
```

配置 web 服务端口号。

## 4.2.4 查看监控面板

通过 `kusion apply` 命令部署配置:

```
 SUCCESS  Compiling in stack prod...                                                                                                  

Stack: prod    Provider                                 Type                           Name    Plan
       * ├─  kubernetes                         v1:Namespace      prometheus-example-app[0]  Create
       * ├─  kubernetes  monitoring.coreos.com/v1:PodMonitor  prometheus-example-appprod[0]  Create
       * └─  kubernetes                   apps/v1:Deployment  prometheus-example-appprod[0]  Create
```

可以看到，除了部署 kubernetes `Deployment` 和 `Namespace` 资源外，还额外部署了 `PodMonitor` 资源用于配置 Prometheus 监听应用 Pod，当资源都创建完成时，可以通过如下命令查看 Prometheus 监控面板。

```
kubectl --namespace monitoring port-forward svc/prometheus-k8s 9090
```

最后通过 http://localhost:9090 访问监控面板并查看应用程序的监控指标。
