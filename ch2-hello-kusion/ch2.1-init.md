# 2.1 初始化工程

在开始前用户需要先配置好 [Kusion 工具](https://kusionstack.io/docs/user_docs/getting-started/install) 和 [Konfig 配置库](https://github.com/KusionStack/konfig)。初始化工程是在 Konfig 配置库内添加代码。

## 2.1.1 执行 `init` 命令

第一步：进入 `Konfig/appops` 目录对应的命令行，输入 `kusion init` 命令初始化工程：

```
$ kusion init
Use the arrow keys to navigate: ↓ ↑ → ← 
? This command will initialize KCL file structure and base codes for a new project.Please choose a KCL schema type: 
  ▸ Server
```

选择工程的类型：目前只有一个 Server 类型，点击回车确定。然后输入工程的名字：

```
Use the arrow keys to navigate: ↓ ↑ → ← 
✔ Server
✔ project name: █emo
```

比如输入 `demo` 的名字然后回车确认。然后输入 stack 的名字（stack 是为了方便管理大量云原生应用而人为做的分类）：

```
Use the arrow keys to navigate: ↓ ↑ → ← 
✔ Server
project name: demo
stack name: █ev
```

然后选择默认集群的名字：

```
Use the arrow keys to navigate: ↓ ↑ → ← 
✔ Server
project name: demo
stack name: dev
✔ cluster name: █efault
cluster name: █efault
```

然后指定镜像：

```
Use the arrow keys to navigate: ↓ ↑ → ← 
✔ Server
project name: demo
stack name: dev
✔ cluster name: █efault
✔ image: █cr.io/google-samples/gb-frontend:v4
```

初始化完成后会产生一个 demo 目录，其中内容如下：

```
$ cd demo
$ tree .
.
├── README.md
├── base
│   └── base.k
├── dev
│   ├── ci-test
│   │   └── settings.yaml
│   ├── kcl.yaml
│   ├── main.k
│   └── stack.yaml
└── project.yaml

3 directories, 7 files
```

现在我们已经有一个完整的 Kusion 配置项目。

## 2.1.2 理解代码内容

查看 base 目录的基线配置，其中 `base/base.k` 内容如下：

```python
import base.pkg.kusion_models.kube.frontend
import base.pkg.kusion_models.kube.frontend.container
import base.pkg.kusion_models.kube.templates.resource as res_tpl
import base.pkg.kusion_models.kube.frontend.service

# Application Configuration
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
        ports = [{containerPort = 80}]
    }
    selector = {
        "tier" = "frontend"
    }
    podMetadata.labels: {
        "tier" = "frontend"
    }
    schedulingStrategy.resource = res_tpl.medium
    services = [
        service.Service {
            name = "frontend-service"
            type = "NodePort"
            ports = [{port = 80}]
        }
    ]
}
```

其中包含主容器和应用的默认配置。基线配置参数相对相对，不过都是默认的配置，平时不需要经常修改。

`dev` 对应 stack 类型（常见的类型还有 gray 表示灰度、pre 表示预发、prod 表示正是版本等），这里表示开发状态的配置。 配置的入口在 `dev/main.k` 文件：

```python
import base.pkg.kusion_models.kube.frontend
import base.pkg.kusion_models.kube.templates.resource as res_tpl

# The application configuration in stack will overwrite 
# the configuration with the same attribute in base.
appConfiguration: frontend.Server {
    image = "gcr.io/google-samples/gb-frontend:v4"
    schedulingStrategy.resource = res_tpl.tiny
}
```

`main.k` 中只需要填写和基线参数不一样的部分。比如 image 在基线的基础之后增加新的镜像路径，`schedulingStrategy.resource` 则是覆盖已有的基线配置。

另外，`project.yaml` 中记录了工程的名字 demo，`dev/stack.yaml` 中记录了当前目录的类型。
