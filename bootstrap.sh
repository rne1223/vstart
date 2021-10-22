ENV_HOME="/home/vagrant/"
ENV_BASHRC="${ENV_HOME}.bashrc" 
ENV_PROFILE="${ENV_HOME}.profile" 
ENV_BIN="${ENV_HOME}bin/"
ENV_KUBELOC="${ENV_HOME}.kube"

step=1
step() {
    echo "Step $step $1"
    step=$((step+1))
}

zypper_refresh() {
    step "===Zypper Refresh"
    sudo zypper refresh
    sudo zypper --non-interactive install bzip2
    sudo zypper --non-interactive install etcd
}

install_docker() {
    step "===== Installing Docker ====="
    sudo zypper install -y docker python3-docker-compose
    sudo systemctl enable docker
    sudo usermod -G docker -a vagrant 
    sudo systemctl restart docker
    newgrp docker

    sudo curl https://raw.githubusercontent.com/docker/docker-ce/master/components/cli/contrib/completion/bash/docker -o /etc/bash_completion.d/docker
    sudo curl -L https://raw.githubusercontent.com/docker/compose/1.24.0/contrib/completion/bash/docker-compose -o /etc/bash_completion.d/docker-compose
}

install_K3s() {
    step "===== Installing K3s ====="
    curl -sfL https://get.k3s.io | sh -
    sudo chown vagrant:vagrant '/etc/rancher/k3s/k3s.yaml'
    ln -s "/etc/rancher/k3s/k3s.yaml $ENV_KUBELOC/config"
}

install_git() {
    step "===== Installing Git ====="
    sudo zypper install -y git
    git config --global user.email "rne1223@gmail.com"
    git config --global user.name "rne1223"
}

install_gh() {
    step "===== Installing gh ====="
    VERSION=`curl "https://api.github.com/repos/cli/cli/releases/latest" | grep '"tag_name"' | sed -E 's/.*"([^"]+)".*/\1/' | cut -c2-`
    curl -sSL https://github.com/cli/cli/releases/download/v${VERSION}/gh_${VERSION}_linux_amd64.tar.gz -o gh_${VERSION}_linux_amd64.tar.gz
    tar xvf gh_${VERSION}_linux_amd64.tar.gz
    cp gh_${VERSION}_linux_amd64/bin/gh ${ENV_BIN}
    sudo cp -r gh_${VERSION}_linux_amd64/share/man/man1/* /usr/share/man/man1/

    # gh autocomplete
    echo "eval '$(gh completion -s bash)'" >> "${ENV_PROFILE}"
    rm -r gh_${VERSION}_linux_amd64 
    rm gh_${VERSION}_linux_amd64.tar.gz
}

install_skaffold() {
    step "==== Installing skaffold ===="
    curl -Lo skaffold https://storage.googleapis.com/skaffold/releases/latest/skaffold-linux-amd64
    sudo chown vagrant:vagrant skaffold
    sudo chmod +x skaffold
    mv skaffold $ENV_BIN
}

install_minikube() {
    step "==== Installing minikube===="
    curl -Lo minikube https://storage.googleapis.com/minikube/releases/latest/minikube-linux-amd64
    sudo chown vagrant:vagrant minikube 
    sudo chmod +x minikube 
    mv minikube $ENV_BIN
}

modify_bashrc() {
    step "===== Updating ~/.bashrc ====="

    # Modifying ~/.bashrc
    echo "set -o vi" >> "${ENV_BASHRC}"
    echo "source <(kubectl completion bash)" >> "${ENV_BASHRC}"
    echo "source <(helm completion bash)" >> "${ENV_BASHRC}"
    echo "source <(minikube completion bash)" >> "${ENV_BASHRC}"
    echo 'alias k=kubectl' >>  "${ENV_BASHRC}"
    echo 'complete -F __start_kubectl k' >> "${ENV_BASHRC}"
}

main() {

    zypper_refresh
    install_docker
    install_git
    install_gh
    modify_bashrc

    echo "====================="
    echo "    DONE     "
    echo "====================="
}

main