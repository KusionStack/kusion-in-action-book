# https://kubernetes.io/zh/docs/concepts/workloads/controllers/deployment/
import apps

demo = apps.Deployment {
    metadata.name = "nginx-deployment"
    spec = {
        replicas = 3
        selector.matchLabels = {
            "app" = "nginx"
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
