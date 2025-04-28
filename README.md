# 🔄 Proxmox VE — Restore a Deleted VM from an Orphaned QCOW2 Disk

When the VM definition (`<vmid>.conf`) is gone but the disk image is still
present on a **directory/NFS storage**, you can rebuild the guest in minutes.

This repository contains:

* **`scripts/rebuild-vm.sh`** – an interactive Bash script that  
  1. Prompts for basic VM settings and storage paths  
  2. Re-creates a VM shell (UEFI/Q35)  
  3. Attaches the rescued QCOW2 as a SATA drive for the first boot  
  4. Mounts the VirtIO driver ISO  
  5. Prints follow-up commands to switch the disk to VirtIO-SCSI

* **This `README.md`** – background, prerequisites, step-by-step usage,
  and a post-restore checklist.

> **Example scenario:** Windows Server 2022 guest, stored on an NFS share called
> `proxmox-storage`, VMID 610, disk file
> `images/610/vm-610-disk-0.qcow2`.

---

## ℹ️  Background

| Fact | Why it matters |
|------|----------------|
| Directory/NFS storage keeps each disk as a standalone `qcow2` file. | You can “re-attach” it just by naming the file path. |
| Windows boots from **SATA** without extra drivers. | We attach as SATA first to avoid an *INACCESSIBLE_BOOT_DEVICE* BSOD. |
| VirtIO offers the best performance. | After drivers are installed, we swap the disk to VirtIO-SCSI. |

---

## ✅  Prerequisites

| Item | Example |
|------|---------|
| QCOW2 image | `/mnt/pve/proxmox-storage/images/610/vm-610-disk-0.qcow2` |
| VirtIO driver ISO | `proxmox-storage:iso/virtio-win.iso` |
| Free VMID | `610` (use the original if possible) |
| Proxmox shell access | Run as **root** on any node that sees the storage |

---

## 🚀  Quick Start

```bash
git clone https://github.com/<you>/proxmox-vm-restore.git
cd proxmox-vm-restore
chmod +x scripts/rebuild-vm.sh
sudo ./scripts/rebuild-vm.sh   # run on a Proxmox node
