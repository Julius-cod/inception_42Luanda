(function () {
  "use strict";
  document.documentElement.classList.add("js");
  var cfg = window.INCEPTION_CONFIG || { baseUrl: "", routes: [], externalLinks: [] };
  var reduce = window.matchMedia("(prefers-reduced-motion: reduce)").matches;

  function base() {
    var b = (cfg.baseUrl || "").replace(/\/+$/, "");
    if (b) return b;
    if (location.protocol === "https:" || location.protocol === "http:") return location.origin;
    return "";
  }
  function url(path) { return base() + path; }

  /* ---------- Quick access ---------- */
  var qa = document.getElementById("qa-list");
  if (qa) {
    qa.innerHTML = "";
    cfg.routes.filter(function (r) { return r.enabled; }).forEach(function (r) {
      var li = document.createElement("li");
      var a = document.createElement("a");
      a.className = "qa-card";
      a.href = url(r.path);
      a.innerHTML = '<span class="qa-path mono"></span><strong></strong><span class="qa-note"></span><span class="qa-url mono"></span>';
      a.querySelector(".qa-path").textContent = r.path;
      a.querySelector("strong").textContent = r.label;
      a.querySelector(".qa-note").textContent = r.note;
      a.querySelector(".qa-url").textContent = url(r.path) || r.path;
      li.appendChild(a);
      qa.appendChild(li);
    });
  }
  var ext = document.getElementById("ext-list");
  if (ext) {
    ext.innerHTML = "";
    cfg.externalLinks.forEach(function (l) {
      var li = document.createElement("li");
      var a = document.createElement("a");
      a.href = l.href; a.target = "_blank"; a.rel = "noopener noreferrer";
      a.textContent = l.label + " ↗";
      a.setAttribute("aria-label", l.label + " (link externo, abre num novo separador)");
      li.appendChild(a); ext.appendChild(li);
    });
  }
  var hostEl = document.getElementById("host-label");
  if (hostEl) hostEl.textContent = cfg.baseUrl ? cfg.baseUrl : (location.host || cfg.hostnameLabel);

  /* ---------- Clock ---------- */
  var clock = document.getElementById("clock");
  function tick() {
    if (!clock) return;
    var d = new Date();
    clock.textContent = d.toLocaleTimeString("pt-PT", { hour12: false });
    clock.setAttribute("datetime", d.toISOString());
  }
  tick(); setInterval(tick, 1000);

  /* ---------- Scroll progress + active nav ---------- */
  var bar = document.getElementById("progress");
  window.addEventListener("scroll", function () {
    var h = document.documentElement;
    var p = h.scrollTop / Math.max(1, h.scrollHeight - h.clientHeight);
    if (bar) bar.style.transform = "scaleX(" + p + ")";
  }, { passive: true });

  var navLinks = Array.prototype.slice.call(document.querySelectorAll(".nav-links a[href^='#']"));
  if ("IntersectionObserver" in window) {
    var secObs = new IntersectionObserver(function (entries) {
      entries.forEach(function (e) {
        if (!e.isIntersecting) return;
        navLinks.forEach(function (a) {
          var on = a.getAttribute("href") === "#" + e.target.id;
          a.classList.toggle("active", on);
          if (on) a.setAttribute("aria-current", "true"); else a.removeAttribute("aria-current");
        });
      });
    }, { rootMargin: "-45% 0px -50% 0px" });
    navLinks.forEach(function (a) {
      var s = document.querySelector(a.getAttribute("href"));
      if (s) secObs.observe(s);
    });

    var rev = new IntersectionObserver(function (entries) {
      entries.forEach(function (e) {
        if (e.isIntersecting) { e.target.classList.add("in"); rev.unobserve(e.target); }
      });
    }, { threshold: 0.12 });
    document.querySelectorAll(".reveal").forEach(function (el) {
      if (reduce) el.classList.add("in"); else rev.observe(el);
    });
  } else {
    document.querySelectorAll(".reveal").forEach(function (el) { el.classList.add("in"); });
  }

  /* ---------- Mobile menu ---------- */
  var toggle = document.getElementById("menu-toggle");
  var menu = document.getElementById("nav-links");
  function setMenu(open) {
    toggle.setAttribute("aria-expanded", String(open));
    menu.classList.toggle("open", open);
  }
  if (toggle && menu) {
    toggle.addEventListener("click", function () { setMenu(toggle.getAttribute("aria-expanded") !== "true"); });
    menu.addEventListener("click", function (e) { if (e.target.tagName === "A") setMenu(false); });
    document.addEventListener("keydown", function (e) {
      if (e.key === "Escape" && menu.classList.contains("open")) { setMenu(false); toggle.focus(); }
    });
  }

  /* ---------- Service data ---------- */
  var SERVICES = {
    client: { name: "Cliente / Browser", kind: "Externo", port: "—", proto: "HTTPS",
      text: "O browser é o único ponto de partida externo. Comunica apenas com o Nginx através de HTTPS na porta 443. Não tem acesso direto a nenhum outro container.",
      links: ["Nginx (HTTPS :443)"] },
    nginx: { name: "Nginx", kind: "Reverse proxy · TLS", port: "443 (publicada no host)", proto: "HTTPS → FastCGI / HTTP",
      text: "Ponto de entrada único. Termina o TLS, aplica o routing e encaminha pedidos: PHP do WordPress via FastCGI para wordpress:9000, PHP do Adminer para adminer:9001, ficheiros estáticos de /var/www/static/ e /cadvisor/ por proxy HTTP para cadvisor:8080.",
      links: ["WordPress (FastCGI :9000)", "Adminer (FastCGI :9001)", "cAdvisor (HTTP :8080, interno)", "Site estático (ficheiros locais)"] },
    wordpress: { name: "WordPress + PHP-FPM", kind: "Aplicação CMS", port: "9000 (interna)", proto: "FastCGI",
      text: "O WordPress corre sob PHP-FPM, o gestor de processos que executa PHP. Não fala HTTP: recebe pedidos FastCGI do Nginx. Os ficheiros do site ficam num volume persistente.",
      links: ["MariaDB (:3306)", "Redis (:6379)", "Volume de ficheiros WordPress"] },
    mariadb: { name: "MariaDB", kind: "Base de dados relacional", port: "3306 (interna)", proto: "Protocolo MySQL",
      text: "Guarda posts, utilizadores e configurações do WordPress. Os dados vivem num volume, por isso sobrevivem à recriação do container. Não deve ser publicada no host.",
      links: ["WordPress", "Adminer", "Volume da base de dados"] },
    redis: { name: "Redis", kind: "Bónus · Cache de objetos", port: "6379 (interna)", proto: "RESP",
      text: "Cache em memória usada pelo WordPress para guardar resultados de consultas frequentes, reduzindo a carga sobre a MariaDB.",
      links: ["WordPress"] },
    adminer: { name: "Adminer + PHP-FPM", kind: "Bónus · Admin da BD", port: "9001 (interna)", proto: "FastCGI",
      text: "Interface web de administração da base de dados, alcançada através da rota /adminer do Nginx. O script está em /var/www/adminer/index.php. Por dar acesso direto aos dados, deve estar protegido.",
      links: ["Nginx (/adminer)", "MariaDB (:3306)"] },
    ftp: { name: "vsftpd", kind: "Bónus · Transferência de ficheiros", port: "21 (controlo) + portas passivas", proto: "FTP",
      text: "Servidor FTP com acesso ao volume do WordPress. A porta 21 transporta apenas a ligação de controlo; as transferências de dados em modo passivo usam um intervalo de portas adicional configurado. O FTP não é cifrado por omissão.",
      links: ["Volume de ficheiros WordPress"] },
    cadvisor: { name: "cAdvisor", kind: "Bónus · Monitorização", port: "8080 (interna)", proto: "HTTP",
      text: "Recolhe métricas de CPU, memória, rede e disco de cada container. É servido através do reverse proxy em /cadvisor/, não necessariamente como porta publicada.",
      links: ["Nginx (/cadvisor/)", "Docker runtime (leitura)"] },
    static: { name: "Site estático", kind: "Bónus · Showcase", port: "— (servido pelo Nginx)", proto: "HTTPS",
      text: "Esta página: HTML, CSS e JavaScript puros, servidos pelo Nginx a partir de /var/www/static/ na rota /static/. Não é a página inicial do WordPress e não consulta o estado real dos serviços.",
      links: ["Nginx (/static/)"] }
  };

  var panel = document.getElementById("detail");
  function showDetail(id) {
    var s = SERVICES[id];
    if (!s || !panel) return;
    panel.querySelector("[data-f=kind]").textContent = s.kind;
    panel.querySelector("[data-f=name]").textContent = s.name;
    panel.querySelector("[data-f=port]").textContent = s.port;
    panel.querySelector("[data-f=proto]").textContent = s.proto;
    panel.querySelector("[data-f=text]").textContent = s.text;
    var ul = panel.querySelector("[data-f=links]");
    ul.innerHTML = "";
    s.links.forEach(function (l) { var li = document.createElement("li"); li.textContent = l; ul.appendChild(li); });
    document.querySelectorAll("[data-node]").forEach(function (n) {
      n.setAttribute("aria-pressed", String(n.getAttribute("data-node") === id));
    });
  }
  document.querySelectorAll("[data-node]").forEach(function (n) {
    n.addEventListener("click", function () { showDetail(n.getAttribute("data-node")); });
  });
  document.querySelectorAll("[data-learn]").forEach(function (b) {
    b.addEventListener("click", function () {
      showDetail(b.getAttribute("data-learn"));
      document.getElementById("arquitetura").scrollIntoView({ behavior: reduce ? "auto" : "smooth" });
      if (panel) panel.focus({ preventScroll: true });
    });
  });
  showDetail("nginx");

  /* ---------- Route explorer ---------- */
  var ROUTES = {
    "/": { target: "wordpress:9000", type: "FastCGI", text: "try_files procura o ficheiro pedido; se não existir, entrega a index.php do WordPress. Os pedidos .php seguem por FastCGI para o PHP-FPM em wordpress:9000." },
    "/adminer": { target: "adminer:9001", type: "FastCGI", text: "Os pedidos PHP são enviados ao PHP-FPM do Adminer em adminer:9001, com o script em /var/www/adminer/index.php." },
    "/static/": { target: "/var/www/static/", type: "Ficheiros", text: "O Nginx serve diretamente HTML, CSS e JS a partir de /var/www/static/. Nenhum PHP é executado." },
    "/cadvisor/": { target: "http://cadvisor:8080/", type: "Proxy HTTP", text: "proxy_pass encaminha para o cAdvisor dentro da rede Docker. A barra final é importante: o prefixo /cadvisor/ é substituído por /." }
  };
  var tabs = Array.prototype.slice.call(document.querySelectorAll("[role=tab][data-route]"));
  var rOut = document.getElementById("route-out");
  function selectRoute(tab) {
    tabs.forEach(function (t) { var on = t === tab; t.setAttribute("aria-selected", String(on)); t.tabIndex = on ? 0 : -1; });
    var r = ROUTES[tab.getAttribute("data-route")];
    rOut.querySelector("[data-r=path]").textContent = tab.getAttribute("data-route");
    rOut.querySelector("[data-r=type]").textContent = r.type;
    rOut.querySelector("[data-r=target]").textContent = r.target;
    rOut.querySelector("[data-r=text]").textContent = r.text;
  }
  tabs.forEach(function (t, i) {
    t.addEventListener("click", function () { selectRoute(t); });
    t.addEventListener("keydown", function (e) {
      var d = e.key === "ArrowRight" ? 1 : e.key === "ArrowLeft" ? -1 : 0;
      if (!d) return;
      e.preventDefault();
      var n = tabs[(i + d + tabs.length) % tabs.length];
      n.focus(); selectRoute(n);
    });
  });
  if (tabs[0]) selectRoute(tabs[0]);

  /* ---------- Copy YAML ---------- */
  var copyBtn = document.getElementById("copy-yaml");
  if (copyBtn && navigator.clipboard) {
    copyBtn.addEventListener("click", function () {
      navigator.clipboard.writeText(document.getElementById("yaml").textContent).then(function () {
        copyBtn.textContent = "Copiado";
        setTimeout(function () { copyBtn.textContent = "Copiar"; }, 1600);
      });
    });
  } else if (copyBtn) { copyBtn.hidden = true; }

  /* ---------- Glossary filter ---------- */
  var gInput = document.getElementById("gloss-search");
  var gCount = document.getElementById("gloss-count");
  if (gInput) {
    gInput.addEventListener("input", function () {
      var q = gInput.value.trim().toLowerCase(), n = 0;
      document.querySelectorAll(".gloss-item").forEach(function (it) {
        var show = it.textContent.toLowerCase().indexOf(q) !== -1;
        it.hidden = !show; if (show) n++;
      });
      gCount.textContent = n + (n === 1 ? " termo" : " termos");
    });
  }

  var y = document.getElementById("year");
  if (y) y.textContent = new Date().getFullYear();
})();
