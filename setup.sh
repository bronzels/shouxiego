if [[ "$OSTYPE" == "darwin"* ]]; then
    echo "Mac detected."
    #mac
    MYHOME=/Volumes/data
    BININSTALLED=/Users/apple/bin
    os=darwin
    SED=gsed
    MNTPATH=/Volumes/data/workspace
    GOINSTALLED=/Volumes/data/go
    GOPATHFILE=/etc/profile
    GOENVFILE=~/.zshrc
else
    echo "Assuming linux by default."
    #linux
    MYHOME=~
    BININSTALLED=/usr/local/bin
    os=linux
    SED=sed
    MNTPATH=/workspace
    GOINSTALLED=/data0/go
    GOPATHFILE=~/.bashrc
    GOENVFILE=~/.bashrc
fi

MY_PRJ_HOME=${GOPATH}/src/shouxiego

GOLANG_VERSION=1.17.13

KUSTOMIZE_VERSION=5.0.1

#KUBEBUILDER_VERSION=v4.2.0
#KUBEBUILDER_VERSION=v3.2.0
KUBEBUILDER_VERSION=v3.6.0
#KUBEBUILDER_VERSION=v3.15.1

wget -c https://dl.google.com/go/go${GOLANG_VERSION}.${os}-amd64.tar.gz
tar xzvf go${GOLANG_VERSION}.${os}-amd64.tar.gz
mv go ${GOINSTALLED}
echo "export PATH=\$PATH:${GOINSTALLED}/bin" >> ${GOPATHFILE}
echo "export GOROOT=${GOINSTALLED}" >> ~/${GOENVFILE}
echo "export GOPATH=${MNTPATH}/gopath" >> ~/${GOENVFILE}
echo "export GOPROXY=https://goproxy.cn,direct" >> ~/${GOENVFILE}

wget -c https://github.com/kubernetes-sigs/kustomize/releases/download/kustomize%2Fv${KUSTOMIZE_VERSION}/kustomize_v${KUSTOMIZE_VERSION}_${os}_amd64.tar.gz
tar xzvf kustomize_v${KUSTOMIZE_VERSION}_${os}_amd64.tar.gz
chmod +x ./kustomize
mv kustomize ${BININSTALLED}

wget -c https://github.com/kubernetes-sigs/kubebuilder/releases/download/${KUBEBUILDER_VERSION}/kubebuilder_${os}_amd64
chmod +x ./kubebuilder_${os}_amd64
mv kubebuilder_${os}_amd64 ${BININSTALLED}/kubebuilder

git clone git@github.com:webgamedevelop/games.git
cd games
file=Makefile
cp ${file} ${file}.bk
$SED -i '/PROXY/d' ${file}
$SED -i 's/	  --driver-opt=network=host \\/	  --driver-opt=network=host/g' ${file}
$SED -i '/BUILDER ?= builder/a\REPO ?= harbor.my.org:1080' ${file}
#harbor中新建webgamedevelop项目
$SED -i 's/--tag /--tag $(REPO)\//g' ${file}
$SED -i '/##@ General/a\all: rm-builder builder snake 2048 battle-city react-tetris super-mario' ${file}
$SED -i '/	  --driver-opt=network=host/a\	- docker buildx use $(BUILDER)' ${file}
cat << EOF > buildkit.toml
debug=true
[registry."docker.io"]
  mirrors = [
            "https://fxy8rj00.mirror.aliyuncs.com",
            "https://docker.registry.cyou",
            "https://docker-cf.registry.cyou",
            "https://dockercf.jsdelivr.fyi",
            "https://docker.jsdelivr.fyi",
            "https://dockertest.jsdelivr.fyi",
            "https://mirror.aliyuncs.com",
            "https://dockerproxy.com",
            "https://mirror.baidubce.com",
            "https://docker.m.daocloud.io",
            "https://docker.nju.edu.cn",
            "https://docker.mirrors.sjtug.sjtu.edu.cn",
            "https://docker.mirrors.ustc.edu.cn",
            "https://mirror.iscas.ac.cn",
            "https://docker.rainbond.cc"
    ]
# optionally mirror configuration can be done by defining it as a registry.
[registry."harbor.my.org:1080"]
  http = true
EOF
$SED -i 's/	  --driver-opt=network=host/	  --driver-opt=network=host \\/g' ${file}
$SED -i '/	  --driver-opt=network=host/a\	  --config=buildkit.toml' ${file}
mkdir src
cd src
git clone git@github.com:gabrielecirulli/2048.git
git clone git@github.com:shinima/battle-city.git
git clone git@github.com:chvin/react-tetris.git
git clone git@github.com:RabiRoshan/snake_game.git
git clone git@github.com:martindrapeau/backbone-game-engine.git
cd ..
#备份和修改每个游戏的Dockerfile，把CMD git clone修改为COPY
docker pull bitnami/git:latest
docker pull nginx:1.25.3
docker pull node:16
#PLATFORMS=linux/amd64 make
#改成COPY代码，还是很长时间没有反应，不知道什么原因，放弃用buildx，修改Makefile直接docker build
#npm install超时，修改battle-city的Dockerfile的npm源到taobao
make

COPY src/battle-city /workspace/battle-city
RUN cd battle-city && \


git clone git@github.com:bronzels/k8sopwebgame.git
cd k8sopwebgame
kubebuilder init \
    --domain op.k8s.at.bronzels \
    --repo github.com/bronzels/k8sopwebgame
kubebuilder create api --controller --resource \
    --group k8sopwebgame \
    --version v1 \
    --kind WebGame
make manifests
make generate

make build
make install 
make install
./bin/manager
#或者
make run
#kubectl apply -k config/samples/
#-k提示缺少kustomize相关yaml文件

#1,增加打印
#修改controllers/webgame_controller.go
make run
kubectl apply -f config/samples/
kubectl delete -f config/samples/

#2,增加2个成员变量
#修改api/v1/webgame_types.go
go mod tidy
make generate
make manifests
make install
make run
kubectl create secret docker-registry harbor-secret --namespace=default --docker-server=harbor.my.org:1080 --docker-username=admin --docker-password=Harbor12345
#修改config/samples/k8sopwebgame_v1_webgame.yaml，在spec增加相应的值
kubectl apply -f config/samples/
kubectl get webgame k8sopwebgame-sample -o yaml
kubectl delete -f config/samples/

#3,增加所有成员变量
#修改api/v1/webgame_types.go
go mod tidy
make generate manifests install
make run
kubectl apply -f config/samples/
kubectl get webgame k8sopwebgame-sample -o yaml
kubectl delete -f config/samples/

#4,增加所有成员变量
#修改controllers/webgame_controller.go
go mod tidy
make generate manifests install
make run

#fq
export http_proxy=127.0.0.1:7897
export https_proxy=127.0.0.1:7897
export no_proxy="192.168.3.14,github.com"

#安装 cert-manager
helm repo add jetstack https://charts.jetstack.io --force-update
helm repo update
#Error: INSTALLATION FAILED: chart requires kubeVersion: >= 1.22.0-0 which is incompatible with Kubernetes v1.21.14
#  --version v1.14.3 \
helm install \
  cert-manager jetstack/cert-manager \
  --namespace cert-manager \
  --create-namespace \
  --version v1.11.0 \
  --set installCRDs=true

:<<EOF
kubectl delete -f https://raw.githubusercontent.com/GoogleCloudPlatform/k8s-stackdriver/master/custom-metrics-stackdriver-adapter/deploy/production/adapter.yaml
#安装 opentelemetry-operator
#把223.5.5.5,223.6.6.6加到dns中
helm repo add open-telemetry \
  https://open-telemetry.github.io/opentelemetry-helm-charts
helm repo update
helm --namespace opentelemetry-operator-system install --create-namespace \
  --set manager.collectorImage.repository="registry-cn-hangzhou.ack.aliyuncs.com/acs/opentelemetry-collector" \
  opentelemetry-operator open-telemetry/opentelemetry-operator
#opentelemetry因为horiztal scaler的原因无法正常运行，放弃安装

#安装 jaeger-operator 和 jaeger
kubectl create namespace observability
kubectl delete -n observability \
  -f https://github.com/jaegertracing/jaeger-operator/releases/download/v1.54.0/jaeger-operator.yaml 
#会占用443端口, 影响nginx-ingress，opentelemetry因为horiztal scaler的原因无法正常运行，放弃安装

#非必须放弃安装
#安装 prometheus stack
helm repo add \
  prometheus-community https://prometheus-community.github.io/helm-charts
helm repo update
helm -n monitoring install --create-namespace \
  prometheus-stack prometheus-community/kube-prometheus-stack
# 开启 grafana 的 ingress
helm -n monitoring upgrade --install --create-namespace \
  prometheus-stack prometheus-community/kube-prometheus-stack \
  --set grafana.ingress.enabled=true \
  --set grafana.ingress.ingressClassName=nginx \
  --set grafana.ingress.hosts={"grafana.mydev.io"}
EOF

# 安装 ingress-nginx
#tigera-operator会占用443端口，删除
helm upgrade --install ingress-nginx ingress-nginx \
  --repo https://kubernetes.github.io/ingress-nginx \
  --namespace ingress-nginx --create-namespace \
  --set controller.allowSnippetAnnotations=true \
  --set controller.hostPort.enable=true
#helm pull ingress-nginx --repo https://kubernetes.github.io/ingress-nginx
#tar xzvf ingress-nginx-4.11.2.tgz
#helm pull ingress-nginx --version 4.2.5 --repo https://kubernetes.github.io/ingress-nginx
helm pull ingress-nginx --version 4.8.3 --repo https://kubernetes.github.io/ingress-nginx
tar xzvf ingress-nginx-4.8.3.tgz
#4.11.2是最新版本，可能因为和k8s配套关系，总是提示80/443被占用
#修改values.yaml里的image: 
#ingress-nginx/kube-webhook-certgen
#
#注释掉digest
#用阿里镜像服务拉取
#registry.k8s.io/ingress-nginx/kube-webhook-certgen:v1.4.3@sha256:a320a50cc91bd15fd2d6fa6de58bd98c1bd64b9a6f926ce23a600d87043455a3
#registry.k8s.io/ingress-nginx/controller:v1.11.2@sha256:d5f8217feeac4887cb1ed21f27c2674e58be06bd8f5184cacea2a69abaf78dce
docker tag registry.cn-hangzhou.aliyuncs.com/bronzels/registry.k8s.io-ingress-nginx-kube-webhook-certgen-v1.4.3-sha256:1.0 registry.k8s.io/ingress-nginx/kube-webhook-certgen:v1.4.3
#  --set controller.hostNetwork=true \
#  --set controller.dnsPolicy=ClusterFirstWithHostNet
#  --set controller.allowSnippetAnnotations=true \
#  --set controller.hostPort.enable=true \
#  --set controller.hostPort.ports.http=90 \
#  --set controller.hostPort.ports.https=543
helm install ingress-nginx ./ingress-nginx  --namespace ingress-nginx --create-namespace

helm repo add stable https://charts.helm.sh/stable
helm repo update
kubectl patch storageclass local-path -p '{"metadata": {"annotations":{"storageclass.kubernetes.io/is-default-class":"true"}}}'
helm -n mysql upgrade --install --create-namespace mysql stable/mysql 
  --version 1.6.9 \
  --set imageTag=8.3.0,mysqlRootPassword="abc123",mysqlPassword="abc123"


kubectl apply -f config/samples/
kubectl get webgame k8sopwebgame-sample -o yaml
kubectl delete -f config/samples/


