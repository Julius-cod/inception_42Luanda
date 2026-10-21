# USER_DOC.md — User Documentation

Welcome to the **Inception** stack documentation. This guide explains how to start, stop, access, and verify the services provided by this infrastructure.

---

## 1. Services Provided by the Stack
This infrastructure runs a secure web stack composed of three dedicated services:
*   **NGINX**: The sole entry point of the infrastructure. It handles secure connections (HTTPS) and protects the internal network.
*   **WordPress (PHP-FPM)**: The Content Management System (CMS) that serves the dynamic website.
*   **MariaDB**: The relational database management system that stores all WordPress data.

---

## 2. How to Start and Stop the Project
All management is automated via the `Makefile` located at the root of the repository.

*   **To start the project:**
    ```bash
    make
    ```
    *(This will automatically configure your local `/etc/hosts`, generate default credentials, and launch all containers in background mode).*

*   **To stop the project (without losing data):**
    ```bash
    make stop
    ```

*   **To restart the project:**
    ```bash
    make start
    ```

*   **To completely destroy the infrastructure (containers and network):**
    ```bash
    make down
    ```

---

## 3. Accessing the Website and Administration Panel
Before accessing the site, ensure the services are running. Open your preferred web browser and navigate to:

*   **Main Website (HTTPS):** `https://42.fr`
*   **WordPress Admin Dashboard:** `https://42.fr/wp-admin`

> ⚠️ **Note:** Since the SSL certificate is self-signed for development purposes, your browser will display a security warning. You must click **"Advanced"** and select **"Proceed to juliados.42.fr (unsafe)"** to access the page.

---

## 4. Locating and Managing Credentials
For maximum security, passwords are not exposed in plaintext or stored in environment variables. 

*   The local administrative and user credentials can be found at the root of the project inside the hidden `secrets/` folder:
    *   `secrets/wp_admin_password.txt` — WordPress Administrator password.
    *   `secrets/wp_user_password.txt` — WordPress regular User (Author) password.
*   The default administrator username is **`juliados`** (as per 42 rules, it does not contain the word 'admin' or 'root').
*   The default regular user username is **`colaborador42`**.

To change any password before booting the stack, simply edit the corresponding `.txt` file inside the `secrets/` folder.

---

## 5. Checking Service Status
To verify that all services are alive and running correctly, execute:
```bash
make ps
```
You should see all three containers (`nginx`, `wordpress`, `mariadb`) with the status **"Up"**.

To check active traffic or service logs in real-time, run:
```bash
make logs
```
