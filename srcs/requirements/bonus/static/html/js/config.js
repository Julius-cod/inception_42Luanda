/*
 * INCEPTION // CONTROL CENTER — configuração editável.
 *
 * baseUrl: origem HTTPS servida pelo Nginx (porta 443).
 *   - Deixe vazio ("") para usar a mesma origem onde esta página está a ser servida
 *     (recomendado: funciona automaticamente em https://<login>.42.fr/static/).
 *   - Ou defina explicitamente, por exemplo "https://juliados.42.fr",
 *     APENAS depois de confirmar que é o hostname configurado no projeto.
 *
 * routes: caminhos configurados no Nginx. Respeite as barras finais.
 * enabled: coloque false para esconder um link que não esteja acessível.
 */
window.INCEPTION_CONFIG = {
  baseUrl: "",
  hostnameLabel: "login.42.fr (configurável)",
  routes: [
    { id: "wordpress", label: "WordPress", path: "/", note: "Página inicial do site WordPress", enabled: true },
    { id: "wp-admin", label: "WordPress Admin", path: "/wp-admin/", note: "Painel de administração (requer autenticação)", enabled: true },
    { id: "adminer", label: "Adminer", path: "/adminer/", note: "Administração da base de dados — deve estar protegido", enabled: true },
    { id: "cadvisor", label: "cAdvisor", path: "/cadvisor/", note: "Métricas de containers via reverse proxy", enabled: true },
    { id: "static", label: "Este showcase", path: "/static/", note: "Site estático servido a partir de /var/www/static/", enabled: true }
  ],
  externalLinks: [
    { label: "Documentação Docker Compose", href: "https://docs.docker.com/compose/" },
    { label: "Documentação Nginx", href: "https://nginx.org/en/docs/" }
  ]
};
