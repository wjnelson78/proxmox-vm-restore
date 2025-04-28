---

### `scripts/rebuild-vm.sh`

```bash
#!/usr/bin/env bash
# ============================================================================
#  Interactive VM restore script  •  Proxmox VE
#  Restores a deleted Windows guest from an existing QCOW2 disk.
#  Tested on Proxmox 7/8 • Windows Server 2022 (ostype win11)
# ============================================================================

set -euo pipefail

echo -e "\n=== Proxmox VM Rebuild (Windows) ======================================\n"

# ------------------------- gather input ------------------------------------
read -rp "New or original VMID                : " VMID
read -rp "VM Name (hostname/FQDN)             : " VMNAME
read -rp "Memory (MB, default 8192)           : " MEMORY;  MEMORY=${MEMORY:-8192}
read -rp "vCPU cores (default 4)              : " CORES;   CORES=${CORES:-4}
read -rp "Bridge (default vmbr0)              : " BRIDGE;  BRIDGE=${BRIDGE:-vmbr0}

echo -e "\n--- Storage specifics ----------------------------------------------------"
read -rp "Directory storage ID                : " STORAGE          # e.g. proxmox-storage
read -rp "QCOW2 relative path (images/V/…)    : " DISK_PATH        # images/610/vm-610-disk-0.qcow2
read -rp "VirtIO ISO volume ID (stor:iso/…)   : " VIRTIO_VOL       # proxmox-storage:iso/virtio-win.iso

DISK_VOL="${STORAGE}:${DISK_PATH}"

# ------------------------- create VM shell ---------------------------------
echo -e "\nCreating VM ${VMID} (${VMNAME}) …"
qm create "${VMID}" \
  --name "${VMNAME}" \
  --memory "${MEMORY}" --cores "${CORES}" \
  --net0 virtio,bridge="${BRIDGE}" \
  --ostype win11 \               # closest ostype for Server 2022
  --machine q35 --bios ovmf \
  --agent enabled=1

# ------------------------- attach rescued disk -----------------------------
qm set "${VMID}" --sata0 "${DISK_VOL}"
qm set "${VMID}" --boot order=sata0

# ------------------------- mount VirtIO ISO --------------------------------
qm set "${VMID}" --ide2 "${VIRTIO_VOL},media=cdrom"

# ------------------------- summary & guidance ------------------------------
echo -e "\n-----------------------------------------------------------------"
qm config "${VMID}"
echo   "-----------------------------------------------------------------"
cat <<EOF

VM ${VMID} created.

NEXT STEPS
1.  Start the VM:      qm start ${VMID}
2.  In Windows, install drivers from the CD (usually D:):
      • Storage  : \\vioscsi\\amd64\\*.inf
      • Network  : \\NetKVM\\amd64\\*.inf
3.  Shut down the VM and run:

   # --- swap rescued disk SATA ➜ VirtIO-SCSI -----------------
   qm set ${VMID} --delete sata0
   qm set ${VMID} --scsi0 ${DISK_VOL}
   qm set ${VMID} --scsihw virtio-scsi-pci
   qm set ${VMID} --boot order=scsi0
   # ----------------------------------------------------------

4.  Start the VM again; confirm it boots normally.
5.  (Optional) detach the ISO:  qm set ${VMID} --delete ide2

Done.
EOF
