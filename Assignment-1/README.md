This repository documents the automation, directory configuration, user management, and security permission boundaries for a multi-tenant Linux server managed via an Ansible control node.

---

# Table of Contents

1. [Project Overview](#project-overview)
2. [Prerequisites & Environment](#prerequisites--environment)
3. [Files in Working Directory](#files-in-working-directory)
4. [Part A: Team Structure](#part-a-team-structure)
5. [Part B: Advanced User Management](#part-b-advanced-user-management)
6. [Part C: Advanced Directory Structure](#part-c-advanced-directory-structure)
7. [Part D: Security & Permission Matrix](#part-d-security--permission-matrix)

---

# Project Overview

The objective of this project is to automate the configuration of a secure multi-tenant Linux server (`web1`) using Ansible ad-hoc commands and modules. 

### Key Objectives:
- Establish role-based team groups (`dev-team`, `devops-team`, `admin-group`).
- Provision 9 unique users with custom UIDs (>= 2000), role-specific login shells, 90-day password expiration policies, and root escalation paths.
- Construct an organized directory hierarchy across personal, team, project, shared, and archive spaces.
- Enforce a strict **Security & Permission Matrix** using Linux file modes (`chmod`), ownership (`chown`), and the SetGID attribute (`2xxx`) to guarantee collaboration while blocking unauthorized access.

---

# Prerequisites & Environment

Ensure your control node and managed hosts satisfy the following requirements before executing Ansible modules:

- **Control Node**: Ansible 2.15+ installed on Linux/macOS
- **Managed Host**: Ubuntu/Debian remote host (`web1`) accessible via passwordless SSH
- **Privileges**: Root or `sudo` access on the remote host

Verify connectivity prior to running setup commands:
```bash
ansible all -m ping
```
---

# Files in Working Directory

### `ansible.cfg`

```ini
[defaults]
inventory = ./inventory
host_key_checking = False

[privilege_escalation]
become = True
become_method = sudo
become_user = root
become_ask_pass = False
```

---

* **What it is**: The global configuration file for Ansible that defines default settings and execution parameters for all ad-hoc commands and playbooks run from this directory.
* **Why we used it**: 

  * `inventory = ./inventory`: Points Ansible directly to our custom hosts file so we don't need to specify `-i inventory` every time we run a command.
  * `host_key_checking = False`: Disables SSH key verification to prevent connection prompts or host key mismatch errors during automated remote execution.
  * `[privilege_escalation]`: Configures Ansible to automatically elevate privileges to `root` via `sudo` without requesting a password (`become_ask_pass = False`), ensuring uninterrupted execution for administrative tasks like user creation and file permission changes.

---

### `inventory`

```ini
web1 ansible_host=43.204.236.24 ansible_user=ubuntu ansible_ssh_private_key_file=/home/rahul/.ssh/my_guru.pem
```

* **What it is**: The target host manifest file containing the IP addresses, domain names, and connection parameters for the remote managed servers.
* **Why we used it**: 
  * Registers our target node `web1` with its public IP address (`43.204.236.24`).
  * Specifies the remote login user (`ansible_user=ubuntu`) and the exact SSH private key (`ansible_ssh_private_key_file=/home/rahul/.ssh/my_guru.pem`) required to authenticate safely without a password.

---

### `admin-group`

```ini
%admin-group ALL=(ALL) NOPASSWD: ALL
```

* **What it is**: A standalone local text file containing a custom `sudoers` privilege directive.
* **Why we used it**: 
  * Serves as the source file pushed to `/etc/sudoers.d/admin-group` on the target host using Ansible's `copy` module.
  * Grants members of the `%admin-group` full root access without prompting for a password (`ALL=(ALL) NOPASSWD: ALL`), enabling seamless passwordless administrative escalation for admin users.

---

# Part A: Team Structure

### The Task:
Create three distinct organizational groups to enforce role-based access control (RBAC):
- Development Team (`dev-team`)
- DevOps Team (`devops-team`)
- Admin Group (`admin-group`)

### How We Solved It:
We used the Ansible `group` module to declare and ensure state presence for all three teams on the target server.

### Commands Executed:
```bash
# Create Development Team
ansible all -m group -a "name=dev-team state=present"

# Create DevOps Team
ansible all -m group -a "name=devops-team state=present"

# Create Admin Group
ansible all -m group -a "name=admin-group state=present"
```

---

# Part B: Advanced User Management

### The Task:
- Provision 3 users per team (9 users total).
- Assign custom UIDs starting at 2000.
- Assign appropriate login shells based on team role (`/bin/bash` or restricted shells).
- Enforce password policies requiring updates every 90 days (`password_expire_max=90`).
- Grant passwordless sudo escalation rights exclusively to `admin-group`.

### How We Solved It:
We leveraged Ansible's `user` module to provision accounts with deterministic UIDs, shells, and expiration policies, followed by deploying a drop-in sudoers rule via the `copy` module.

### User Provisioning Table:

| Username | Primary Group | Custom UID | Shell | Sudo Access |
| :--- | :--- | :--- | :--- | :--- |
| `devuser1` | `dev-team` | 2000 | `/bin/bash` | No |
| `devuser2` | `dev-team` | 2001 | `/bin/bash` | No |
| `devuser3` | `dev-team` | 2002 | `/bin/bash` | No |
| `devopsuser1` | `devops-team` | 2003 | `/bin/bash` | No |
| `devopsuser2` | `devops-team` | 2004 | `/bin/bash` | No |
| `devopsuser3` | `devops-team` | 2005 | `/bin/bash` | No |
| `adminuser1` | `admin-group` | 2006 | `/bin/bash` | Full (NOPASSWD) |
| `adminuser2` | `admin-group` | 2007 | `/bin/bash` | Full (NOPASSWD) |
| `adminuser3` | `admin-group` | 2008 | `/bin/bash` | Full (NOPASSWD) |

### Commands Executed:
```bash
# 1. Add Development Team Users (UIDs 2000-2002)
ansible all -m user -a "name=devuser1 uid=2000 group=dev-team shell=/bin/bash password_expire_max=5"
ansible all -m user -a "name=devuser2 uid=2001 group=dev-team shell=/bin/bash password_expire_max=5"
ansible all -m user -a "name=devuser3 uid=2002 group=dev-team shell=/bin/bash password_expire_max=5"

# 2. Add DevOps Team Users (UIDs 2003-2005)
ansible all -m user -a "name=devopsuser1 uid=2003 group=devops-team shell=/bin/bash password_expire_max=5"
ansible all -m user -a "name=devopsuser2 uid=2004 group=devops-team shell=/bin/bash password_expire_max=5"
ansible all -m user -a "name=devopsuser3 uid=2005 group=devops-team shell=/bin/bash password_expire_max=5"

# 3. Add Admin Group Users (UIDs 2006-2008)
ansible all -m user -a "name=adminuser1 uid=2006 group=admin-group shell=/bin/bash password_expire_max=5"
ansible all -m user -a "name=adminuser2 uid=2007 group=admin-group shell=/bin/bash password_expire_max=5"
ansible all -m user -a "name=adminuser3 uid=2008 group=admin-group shell=/bin/bash password_expire_max=5"

# 4. Grant Sudo Privileges to admin-group
ansible all -m copy -a "content='%admin-group ALL=(ALL) NOPASSWD: ALL' dest=/etc/sudoers.d/admin-group mode=0440 validation='visudo -cf %s'"
```

---

# Part C: Advanced Directory Structure

### The Task:
Construct an organized file system hierarchy containing:
- Personal workspace directories inside user home folders (`/home/<user>/personal_workspace`).
- Team collaboration directories (`/teams/dev-team`, `/teams/devops-team`, `/teams/admin-group`).
- Project directories for 3 active projects (`/projects/WebApp`, `/projects/API`, `/projects/Mobile`).
- Global shared resources directory (`/shared`).
- Long-term archive folder (`/archive`).

### How We Solved It:
We deployed directory endpoints using Ansible's `file` module, ensuring path structures existed before applying detailed ownership properties.

### Commands Executed:
```bash
# 1. Create Personal Workspace Directories
ansible all -m file -a "path=/home/devuser1/personal_workspace state=directory owner=devuser1 group=dev-team"
ansible all -m file -a "path=/home/devuser2/personal_workspace state=directory owner=devuser2 group=dev-team"
ansible all -m file -a "path=/home/devuser3/personal_workspace state=directory owner=devuser3 group=dev-team"
ansible all -m file -a "path=/home/devopsuser1/personal_workspace state=directory owner=devopsuser1 group=devops-team"
ansible all -m file -a "path=/home/devopsuser2/personal_workspace state=directory owner=devopsuser2 group=devops-team"
ansible all -m file -a "path=/home/devopsuser3/personal_workspace state=directory owner=devopsuser3 group=devops-team"
ansible all -m file -a "path=/home/adminuser1/personal_workspace state=directory owner=adminuser1 group=admin-group"
ansible all -m file -a "path=/home/adminuser2/personal_workspace state=directory owner=adminuser2 group=admin-group"
ansible all -m file -a "path=/home/adminuser3/personal_workspace state=directory owner=adminuser3 group=admin-group"

# 2. Create Team Directories
ansible all -m file -a "path=/teams/dev-team state=directory"
ansible all -m file -a "path=/teams/devops-team state=directory"
ansible all -m file -a "path=/teams/admin-group state=directory"

# 3. Create Project Directories
ansible all -m file -a "path=/projects/WebApp state=directory"
ansible all -m file -a "path=/projects/API state=directory"
ansible all -m file -a "path=/projects/Mobile state=directory"

# 4. Create Shared & Archive Directories
ansible all -m file -a "path=/shared state=directory"
ansible all -m file -a "path=/archive state=directory"
```

---

# Part D: Security & Permission Matrix

### The Task:
Apply explicit access rules according to the organizational matrix:
- **Personal Workspace**: Owner has full access (`rwx`), team has read access (`r--`), others have no access (`---`).
- **Team Directories**: Assigned team has full access (`rwx`), other teams have read-only access (`r--`). SetGID bit enabled.
- **Project Directories**: Project Lead has full access (`rwx`), assigned team has read/write access (`rwx` directory mode required for entry), others read-only (`r-x`). SetGID bit enabled.
- **Shared Resources**: All users/teams have read and write access (`rwxrwxrwx`).
- **Archive Directory**: Read-only access for all regular users (`r-xr-xr-x`).
- **Admin Areas**: Restricted strictly to `admin-group` (`rwxrwx---`).

### Deep Dive on Permissions & SetGID:
- **Directory Execute Bit (`x`)**: In Linux, a user must have Execute (`x`) permissions on a directory to enter (`cd`) and traverse it. Giving `rw-` without `x` breaks access. Therefore, modes like `2775` are applied so assigned teams can exercise read/write capabilities.
- **SetGID Bit (`2xxx`)**: Setting the leading `2` on team and project directories causes all newly created files and subdirectories to automatically inherit the group ownership of the parent directory rather than the primary group of the creating user.

### Security Matrix Mapping:

| Path | Mode Octal | Symbolic | Owner / Group Assignment | Access Control Strategy |
| :--- | :--- | :--- | :--- | :--- |
| `/home/*/personal_workspace` | `0740` | `rwxr-x---` | User : Primary Team | Owner full access; team read-only; others blocked |
| `/teams/dev-team` | `2774` | `rwxrwsr--` | `root` : `dev-team` | Team full access + SetGID; other teams read-only |
| `/teams/devops-team` | `2774` | `rwxrwsr--` | `root` : `devops-team` | Team full access + SetGID; other teams read-only |
| `/teams/admin-group` | `0770` | `rwxrwx---` | `root` : `admin-group` | Admins full access; all non-admins completely isolated |
| `/projects/WebApp` | `2775` | `rwxrwsr-x` | `devuser1` : `dev-team` | Project Lead (`devuser1`) owner; team full access; others read |
| `/projects/API` | `2775` | `rwxrwsr-x` | `devopsuser1` : `devops-team` | Project Lead (`devopsuser1`) owner; team full access; others read |
| `/projects/Mobile` | `2775` | `rwxrwsr-x` | `devuser2` : `dev-team` | Project Lead (`devuser2`) owner; team full access; others read |
| `/shared` | `0777` | `rwxrwxrwx` | `root` : `root` | Global read/write resource pool |
| `/archive` | `0755` | `rwxr-xr-x` | `root` : `root` | Immutable read-only storage |

### Commands Executed:
```bash
# 1. Apply Personal Workspace Permissions (0740)
ansible all -m file -a "path=/home/devuser1/personal_workspace mode='0740' owner=devuser1 group=dev-team"
ansible all -m file -a "path=/home/devuser2/personal_workspace mode='0740' owner=devuser2 group=dev-team"
ansible all -m file -a "path=/home/devuser3/personal_workspace mode='0740' owner=devuser3 group=dev-team"
ansible all -m file -a "path=/home/devopsuser1/personal_workspace mode='0740' owner=devopsuser1 group=devops-team"
ansible all -m file -a "path=/home/devopsuser2/personal_workspace mode='0740' owner=devopsuser2 group=devops-team"
ansible all -m file -a "path=/home/devopsuser3/personal_workspace mode='0740' owner=devopsuser3 group=devops-team"
ansible all -m file -a "path=/home/adminuser1/personal_workspace mode='0740' owner=adminuser1 group=admin-group"
ansible all -m file -a "path=/home/adminuser2/personal_workspace mode='0740' owner=adminuser2 group=admin-group"
ansible all -m file -a "path=/home/adminuser3/personal_workspace mode='0740' owner=adminuser3 group=admin-group"

# 2. Apply Team Directory & Admin Area Permissions (2774 / 0770)
ansible all -m file -a "path=/teams/dev-team mode='2774' owner=root group=dev-team"
ansible all -m file -a "path=/teams/devops-team mode='2774' owner=root group=devops-team"
ansible all -m file -a "path=/teams/admin-group mode='0770' owner=root group=admin-group"

# 3. Apply Project Directory Permissions (2775)
ansible all -m file -a "path=/projects/WebApp mode='2775' owner=devuser1 group=dev-team"
ansible all -m file -a "path=/projects/API mode='2775' owner=devopsuser1 group=devops-team"
ansible all -m file -a "path=/projects/Mobile mode='2775' owner=devuser2 group=dev-team"

# 4. Apply Shared & Archive Permissions (0777 / 0755)
ansible all -m file -a "path=/shared mode='0777' owner=root group=root"
ansible all -m file -a "path=/archive mode='0755' owner=root group=root"