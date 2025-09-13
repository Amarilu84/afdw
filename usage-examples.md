# Here you will find copy & paste style commands that will teach you how to use AFDW. These are only some examples:
Note: The normal guided run is pre-programmed to do an encrypted wipe, zero the drive, then format exFat to mimic factory settings. (It was written originally for Flash USB/SD).\

You can always customize the actions and behavior using any --flag.


## AFDW Usage Examples

List available disks
```bash
./afdw.sh --list
````

Shows all detected drives (Linux via `lsblk`) so you can pick the correct device. (It does this automatically at the start of interactive mode).

---

## Wipe a drive with zeros (fastest)

```bash
sudo ./afdw.sh -d /dev/sdb
```

Performs a single pass overwrite with **zeros**.

---

## Wipe a drive with random encrypted data (more secure, slower)

```bash
sudo ./afdw.sh -d /dev/sdb -r
```

Performs a single pass overwrite with **random bytes** from `/dev/urandom` encrypted with AES-256.

---

## Multiple passes

```bash
sudo ./afdw.sh -d /dev/sdb -n 3
```

Overwrites the drive **3 times** with zeros.

---

## Random + multiple passes

```bash
sudo ./afdw.sh -d /dev/sdb -n 2 -r
```

Overwrites the drive **twice**, both times with random data.

---

## Non-interactive (skip confirmations)

```bash
sudo ./afdw.sh -d /dev/sdb -y
```

Automatically assumes “yes” for all prompts.
Useful for automation scripts — but dangerous if misused.

---

## Combine options

```bash
sudo ./afdw.sh -d /dev/sdb -n 3 -r -y
```

* 3 passes
* Random data
* Non-interactive confirmations

---

# Formatting After a Wipe - After wiping, you can reformat the drive with standard Linux tools. Formatting will destroy any existing data on the device.

## 1. Create a new ext4 filesystem (Linux default)
```bash
sudo mkfs.ext4 /dev/sdb
````

Formats the drive with the ext4 filesystem, commonly used on Linux.

---

## 2. Create a FAT32 filesystem (USB drives, Windows/macOS compatibility)

```bash
sudo mkfs.vfat -F 32 /dev/sdb
```

Good for USB sticks and drives that need to work across multiple OSes.

---

## 3. Create an NTFS filesystem (Windows compatibility, large files)

```bash
sudo mkfs.ntfs -f /dev/sdb
```

Formats the drive as NTFS, useful for Windows systems and large storage devices.

## ℹHelp

```bash
./afdw.sh -h
```

Shows usage information.
