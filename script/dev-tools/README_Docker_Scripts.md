# Docker Installation Scripts

Script-script ini dibuat untuk memudahkan instalasi Docker dengan konfigurasi yang tepat agar bisa digunakan tanpa sudo.

## 📁 File yang Tersedia

### 1. `install_docker.sh` - Script Lengkap
Script komprehensif dengan fitur:
- ✅ Deteksi otomatis user dan sistem
- ✅ Pengecekan apakah Docker sudah terinstall
- ✅ Instalasi Docker lengkap (CE, CLI, Compose, Buildx)
- ✅ Konfigurasi permission otomatis
- ✅ Testing instalasi
- ✅ Panduan penggunaan
- ✅ Output berwarna dan informatif

### 2. `quick_docker_install.sh` - Script Cepat
Script sederhana untuk instalasi cepat:
- ✅ Deteksi user otomatis
- ✅ Instalasi Docker dasar
- ✅ Konfigurasi permission
- ✅ Testing sederhana

## 🚀 Cara Penggunaan

### Untuk Instalasi Lengkap (Recommended)
```bash
./install_docker.sh
```

### Untuk Instalasi Cepat
```bash
./quick_docker_install.sh
```

## 🔧 Fitur Utama

### Deteksi User Otomatis
- Script otomatis mendeteksi user yang sedang login
- Menambahkan user ke grup `docker`
- Mengkonfigurasi permission agar bisa menggunakan Docker tanpa sudo

### Konfigurasi Permission
- Menambahkan user ke grup `docker`
- Mengatur permission Docker socket
- Memastikan Docker bisa diakses tanpa sudo

### Testing Otomatis
- Mengecek versi Docker dan Docker Compose
- Testing koneksi ke Docker daemon
- Menjalankan container test (hello-world)

## 📋 Persyaratan Sistem

- **OS**: Ubuntu/Debian
- **User**: Bukan root (script akan menggunakan sudo saat diperlukan)
- **Internet**: Koneksi internet untuk download Docker

## 🎯 Untuk TryHackMe

Script ini sangat cocok untuk aktivitas TryHackMe karena:

1. **Mudah digunakan** - Tinggal jalankan satu command
2. **Otomatis** - Tidak perlu konfigurasi manual
3. **Aman** - Tidak perlu menjalankan sebagai root
4. **Lengkap** - Include Docker Compose untuk multi-container apps

### Contoh Penggunaan untuk TryHackMe:
```bash
# Install Docker
./install_docker.sh

# Run vulnerable web app
docker run -p 8080:80 vulnerables/web-dvwa

# Run interactive Ubuntu container
docker run -it ubuntu bash

# Run nginx web server
docker run -p 80:80 nginx
```

## 🔍 Troubleshooting

### Jika masih perlu sudo setelah instalasi:
```bash
# Logout dan login kembali
# Atau jalankan:
newgrp docker
```

### Jika Docker tidak bisa start:
```bash
sudo systemctl start docker
sudo systemctl enable docker
```

### Jika permission masih bermasalah:
```bash
sudo chmod 666 /var/run/docker.sock
```

## 📝 Catatan Penting

- Script ini menggunakan `chmod 666` untuk kemudahan development
- Untuk production, sebaiknya menggunakan grup docker yang proper
- Docker akan otomatis start saat boot
- Semua command Docker bisa digunakan tanpa sudo setelah instalasi

## 🆘 Support

Jika ada masalah dengan script, periksa:
1. Apakah user sudah di grup docker: `groups`
2. Apakah Docker service berjalan: `sudo systemctl status docker`
3. Apakah permission socket benar: `ls -la /var/run/docker.sock`

---
**Happy Hacking with Docker! 🐳**
