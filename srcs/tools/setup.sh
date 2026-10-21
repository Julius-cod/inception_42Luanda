#!/bin/bash

# Cores para o terminal (Códigos ANSI)
GR='\033[1;32m'
YL='\033[0;33m'
CY='\033[0;36m'
NC='\033[0m'

target='/etc/hosts'
domain="juliados.42.fr"
domain2="www.juliados.42.fr"

echo -e "${CY}⣿⣿⣿ Configuração do Ficheiro /etc/hosts ⣿⣿⣿${NC}"

# 1. Verificar se o teu domínio JÁ EXISTE dentro do ficheiro /etc/hosts
# Isto evita que o script adicione o mesmo domínio repetidamente sempre que rodas o comando.
if grep -q "$domain" "$target"; then
    echo -e "Domínio${GR} [ok]${YL} $domain e $domain2 já estão configurados.${NC}"
else
    echo -e "${YL}Domínio não detetado. A atualizar /etc/hosts...${NC}"
    
    # 2. Modificação Segura com o SED
    # Em vez de focar na linha 1, procuramos qualquer linha que comece por 127.0.0.1 (^127.0.0.1)
    # Adicionamos os teus domínios à frente do localhost SEM apagar o localhost original.
    sudo sed -i '/^127.0.0.1/s/$/ '"$domain $domain2"'/' "$target"
    
    # 3. Confirmação visual de sucesso
    if grep -q "$domain" "$target"; then
        echo -e "Domínio${GR} [ok]${YL} Configurado com sucesso!${NC}"
    else
        echo -e "Domínio${YL} [erro] Falha ao atualizar o ficheiro.${NC}"
    fi
fi
