#!/bin/bash

clear
echo '
                        ++++++
                  ++++++++++++++++++
                ++++..          --++++
              ++++                  ++++
            ++++                      ++++
          ++++      ::##      ##..      ++++
          ++..    ++######  ######--    ++++
          ++    ++##..  ######  ++##--    ++
        ++++    ##--    ####      ::##    ++::
        ++++  ####      ##  ##      ####  ++++
        ++++    ##        ####    ####    ++::
          ++      ##    ######  ####      ++
          ++::      ######  ######      ++++
          ++++        ##      ##        ++++
            ++++                      ++++
              ++++                  ++++
                ++++++          ++++++
                  ++++++++++++++++++
                        --++--
  ______ .______       _______      _______.  ______    __
 /      ||   _  \     |   ____|    /       | /  __  \  |  |
|  ,----´|  |_)  |    |  |__      |   (----`|  |  |  | |  |
|  |     |      /     |   __|      \   \    |  |  |  | |  |
|  `----.|  |\  \----.|  |____ .----)   |   |  `--´  | |  `----.
 \______|| _| `._____||_______||_______/     \______/  |_______|
'
echo -e "Seja bem-vindo! Vamos ingressar sua máquina no domínio hoje?\n"

# Função para executar o script do Debian
executar_debian() {
    echo "Executando script do Debian..."
    [ -d /etc/apt/keyrings ] || sudo mkdir -m0755 -p /etc/apt/keyrings && sudo wget -O /etc/apt/keyrings/cid-archive-keyring.pgp https://downloads.sf.net/c-i-d/pkgs/apt/debian/cid-archive-keyring.pgp && sudo wget -O /etc/apt/sources.list.d/cid.sources https://downloads.sf.net/c-i-d/pkgs/apt/debian/cid.sources && sudo apt update && sudo apt install cid cid-gtk -y
    echo "CID instalado"
    menu2
}

# Função para executar o script do Ubuntu
executar_ubuntu() {
    echo "Executando script do Ubuntu..."
    sudo add-apt-repository ppa:emoraes25/cid && sudo apt update && sudo apt install cid cid-gtk
    echo "CID instalado"
    menu2
}

# Função para verificar se o rsync está instalado
verificar_rsync1() {
    REQUIRED_PKG="rsync"
    PKG_OK=$(dpkg-query -W --showformat='${Status}\n' $REQUIRED_PKG|grep "install ok installed")
    echo Checking for $REQUIRED_PKG: $PKG_OK
    if [ "" = "$PKG_OK" ]; then
      echo "No $REQUIRED_PKG. Setting up $REQUIRED_PKG."
      sudo apt-get --yes install $REQUIRED_PKG
    fi
}

verificar_rsync2() {
pacote=$(dpkg --get-selections|grep "rsync" )
    echo -n "Verificando se o rsync está instalado."
    sleep 2
    if [ -n "$pacote" ] ;
    then echo
         echo "Rsync já instalado"
         menu2
    else echo
         echo "Rsync necessário-> Nao instalado"
         echo "Instalando rsync..."
         sudo apt-get install rsync -y
    fi
    echo "O rsync foi instalado"
    menu2
}

# Função para executar a migração de perfil de usuári para a hometemp
executar_home_para_hometemp(){
    home_temp='/home/hometempmigracao'

    ls /home
    read -p "Qual usuario vamos migrar?: " usuario_alvo

    mkdir -p $home_temp

    rsync -av --ignore-existing --remove-source-files /home/$usuario_alvo/ $home_temp/ && rsync -av --delete `mktemp -d`/ /home/$usuario_alvo/ && rmdir /home/$usuario_alvo/
    echo -e "\nO script está sendo finalizado. Faça login com o usuário do AD para que seja criada a nova home do usuário e volte na opção 4 do menu, assim os dados da home temporária serão migrados para a home definitiva"
    exit 0
}

# Função para executar a migração da hometemp para o perfil de usuário
executar_hometemp_para_home(){
    home_temp='/home/hometempmigracao'

    ls /home
    read -p "Qual usuario vamos migrar?: " usuario_alvo

    rsync -av --ignore-existing --remove-source-files $home_temp/ /home/$usuario_alvo/ && rsync -av --delete `mktemp -d`/ $home_temp/ && rmdir $home_temp/

    chown -R $usuario_alvo:$usuario_alvo /home/$usuario_alvo

    menu2
}

# Função para ingressar no domínio

ingressar_dominio(){
    sed -e s/' sss'//g -i /etc/nsswitch.conf-teste
    systemctl stop sssd && systemctl disable sssd
    systemctl start winbind && systemctl enable winbind

    read -p "Qual o domínio? " dominio
    read -p "Qual o usuário com permissão para ingressar máquinas no domínio? " usuario
    read -s -p "Qual senha? " senha

    cid join domain=$dominio user=$usuario pass=$senha

    menu2
}

# Função para instalar o CID
menu() {
    echo -e "\nA sua distribuição é Ubuntu ou Debian?"
    echo "1. Ubuntu"
    echo "2. Debian"
    echo "0. Sair"
    read -p "Opção: " opcao


    case $opcao in
        1)
            executar_ubuntu
            ;;
        2)
            executar_debian
            ;;
        0)
            echo "Saindo..."
            exit 0
            ;;
        *)
            echo "Opção inválida."
            menu
            ;;
    esac
}

# Função para o menu inicial
menu1() {
    echo "1. Sim, por favor"
    echo "2. Não, obrigado"
    echo " "
    read -p "Opção: " opcao

    case $opcao in
        1)
            menu2
            ;;
        2)
            echo "Saindo..."
            exit 0
            ;;
        *)
            echo "Opção inválida."
            menu1
            ;;
    esac
}

menu2() {
    echo -e "\nSelecione uma opção, por favor"
    echo "1. Instalar o CID, ferramenta para ingressar a máquina no domínio"
    echo "2. Ingressar máquina no domínio"
    echo "3. Verificar requisitos para a migração do perfil de usuário"
    echo "4. Migrar home do usuário para a home temporária"
    echo "5. Migrar home temporária para a home do usuário"
    echo "6. Sair"
    read -p "Opção: " opcao

    case $opcao in
        1)
            menu
            ;;
        2)
            ingressar_dominio
            ;;
        3)
            verificar_rsync2
            ;;
        4)
            executar_home_para_hometemp
            ;;
        5)
            executar_hometemp_para_home
            ;;
        6)
            echo "Saindo..."
            exit 0
            ;;
        *)
            echo "Opção inválida."
            menu2
            ;;
    esac
}

# Inicialização do menu
menu1

###
#
