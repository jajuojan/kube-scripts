# kube-scripts

Collection of small helper scripts for interacting with Kubernetes pods.

Included scripts

- `kki_bash.sh` — choose a running pod and open an interactive `/bin/bash`
  shell inside a selected container.
- `kki_logs.sh` — choose a running pod and display logs from a selected
  container.

Summary

These scripts are lightweight wrappers around `kubectl` that present an
interactive menu to pick a running pod and container, using `dialog` when
available and falling back to a Bash `select` menu otherwise. Both scripts
strip ANSI escape codes from menu output to ensure clean selections.

Prerequisites

- `kubectl` available in PATH and configured for your cluster/context.
- `bash` (the scripts use Bash arrays and `mapfile`).
- Optional: `dialog` for a curses-style UI. When absent the scripts fall
  back to a `select` menu.

Install

Make the scripts executable:

```bash
chmod +x kki_bash.sh kki_logs.sh
```

Usage

- Open a shell inside a container:

```bash
./kki_bash.sh
```

- Show logs from a container:

```bash
./kki_logs.sh
```

Examples

- Run with a specific kubeconfig file:

```bash
KUBECONFIG=/home/user/.kube/custom-config ./kki_bash.sh
KUBECONFIG=/home/user/.kube/custom-config ./kki_logs.sh
```

How they work

1. The scripts list running pods using `kubectl get pods --no-headers
--field-selector=status.phase=Running` and present the results as a menu.
2. If a pod contains multiple containers, the scripts prompt to select one.
3. `kki_bash.sh` runs `kubectl exec -it <pod> -c <container> -- /bin/bash`.
4. `kki_logs.sh` runs `kubectl logs <pod> -c <container>`.

Files

- `kki_bash.sh` — open a shell in a selected pod/container.
- `kki_logs.sh` — show logs for a selected pod/container.
- `LICENSE` — project license (MIT).

License

See the `LICENSE` file for license terms. This project is distributed under
the MIT License.
